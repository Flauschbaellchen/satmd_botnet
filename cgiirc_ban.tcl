# MODULE cgiirc_ban
#
# script for HEX-encoded IP idents used by cgi:irc clients like mibbit
# converts this ident to long-ip and checks it against the local and global banlist
# if nothing was found makes a dns-lookup and check the resolved hostname, too.
# bans are set as *!ident@* for 1h
#
# /!\ dns-lookup is tmp. disabled for banlist lookup /!\
#
# using CGI:IRC as an hardcoded ident
# this ident cannot be used on IRC and thus makes possible to ban
# something like *!CGI:IRC@*.de to ban all german users using such a client/proxy
# but let any other users unharmed
set satmd_botnet(cgiirc_ban,ident) "CGI:IRC"


satmd_botnet_require gban

bind join -     "*"                            satmd_botnet_cgiirc_ban
bind pub  nmolG "$satmd_botnet(cmdchar)cgiirc" satmd_botnet_cgiirc_ban_ident_lookup_pub
bind msg  nmolG "cgiirc"                       satmd_botnet_cgiirc_ban_ident_lookup_msg
bind notc nmolG "cgiirc*"                      satmd_botnet_cgiirc_ban_ident_lookup_notc
bind dcc  nmolG "cgiirc"                       satmd_botnet_cgiirc_ban_ident_lookup_dcc
setudef flag "satmd_botnet_cgiirc_ban"

proc satmd_botnet_cgiirc_ban_ident_lookup_pub { nick uhost handle channel text } {
  satmd_botnet_cgiirc_ban_ident_lookup "pub:$channel:$nick" $text
}

proc satmd_botnet_cgiirc_ban_ident_lookup_msg { nick uhost handle text } {
  satmd_botnet_cgiirc_ban_ident_lookup "msg:$nick:$nick" $text
}

proc satmd_botnet_cgiirc_ban_ident_lookup_notc { nick uhost handle text {dest ""}} {
  set text [split $text]
  satmd_botnet_cgiirc_ban_ident_lookup "notc:$nick:$nick" [lindex $text 1]
}

proc satmd_botnet_cgiirc_ban_ident_lookup_dcc { hand idx text } {
  satmd_botnet_cgiirc_ban_ident_lookup "dcc:$idx:$hand" $text
}

proc satmd_botnet_cgiirc_ban_ident_lookup { destination text } {
  if { ![regexp -- {-?([0-9a-f]{8})} $text all hexip] } {
    satmd_botnet_cgiirc_ban_reply $destination "invalid ident: $text"
    return 0
  }
  set realip [long2ip [format %d "0x$hexip"]]
  dnslookup $realip satmd_botnet_cgiirc_ban_lookup_callback $destination $text
}

proc satmd_botnet_cgiirc_ban_reply { destination text } {
  set destination [split $destination :]
  switch [lindex $destination 0] {
    pub { puthelp "PRIVMSG [lindex $destination 1] :[lindex $destination 2], $text" }
    notc { putnotc [lindex $destination 1] "[lindex $destination 2], $text" }
    msg { puthelp "PRIVMSG [lindex $destination 1] :[lindex $destination 2], $text" }
    dcc { putidx [lindex $destination 1] "[lindex $destination 2], $text" }
    default { }
  }
}

proc satmd_botnet_cgiirc_ban_lookup_callback { realip hostname status destination text} {
  if { !$status } {
    set hostname "not resolveable"
  }
  satmd_botnet_cgiirc_ban_reply $destination "$text is $realip ($hostname)"
}

proc satmd_botnet_cgiirc_ban { nick uhost handle channel } {
  global satmd_botnet
  global botnick

  #check if ident is valid hexip and that we do not ban any friends
  if {
    ([string index $channel 0] != "#")
    || ![channel get $channel "satmd_botnet_cgiirc_ban"]
    ||  [matchattr $handle "mnolfb|mnolfb" $channel]
    ||  [isbotnick $nick]
    || ![satmd_botnet_isCGIClient $nick $uhost]
  } {
    return 0
  }
  #convert it to a long ip
  regexp -- {-?([0-9a-f]{8})@.*} $uhost all hexip
  set realip [long2ip [format %d "0x$hexip"]]
  putloglev "d" "*" "cgiircban@satmd_botnet: $nick!$uhost joined $channel. Real IP is $realip"
  
  #break if an exempt exists
  if {[matchexempt "$nick!$satmd_botnet(cgiirc_ban,ident)@$realip"]} { return 0 }

  set banmask [satmd_botnet_genericbanmask $nick $uhost]
  #check if realip is already matching
  #by channel
  foreach banline [banlist $channel] {
    if { [string match -nocase [lindex $banline 0] "$nick!$satmd_botnet(cgiirc_ban,ident)@$realip"] } {
      newchanban $channel $banmask $botnick "[lindex $banline 1] (cgi:irc/open proxy)" 60
      return 0
    }
  }
  #by global banlist
  foreach banline [banlist] {
    if { [string match -nocase [lindex $banline 0] "$nick!$satmd_botnet(cgiirc_ban,ident)@$realip"] } {
      satmd_botnet_gban_add $banmask "1h" "cgiircban@$botnick" $botnick "[lindex $banline 1] (cgi:irc/open proxy)" 1
      return 0
    }
  }
  #check dronebl if ip is listed
  satmd_botnet_dronebl_check $realip satmd_botnet_cgiirc_ban_dronebl_callback $realip $nick $uhost $channel

  #temp. disabled, dns-lookup is not really useful, is it?
  #dnslookup $realip satmd_botnet_cgiirc_ban_callback $nick $uhost $channel
}
proc satmd_botnet_cgiirc_ban_dronebl_callback { ip hostname status realip nick uhost channel } {
  putloglev "d" "*" "cgiircban@satmd_botnet: DroneBL-Lookup for $realip returned: $status"

  if { !$status } { return 0 }
  putcmdlog "cgiircban@satmd_botnet: $nick!$uhost on $channel: $realip was found on dronebl.org."
  set banmask [satmd_botnet_genericbanmask $nick $uhost]
  set reason "Your IP appears in BL zone dnsbl.dronebl.org (http://dronebl.org/lookup)"

  putserv "MODE $channel +b $banmask"
  putkick $channel $nick $reason
  newchanban $channel $banmask $botnick $reason 60
}


proc satmd_botnet_cgiirc_ban_callback { realip hostname status nick uhost channel } {
  global satmd_botnet
  global botnick

  putloglev "d" "*" "cgiircban@satmd_botnet: DNS-Lookup for $realip returned: $hostname (status: $status)"

  #if status equals 0 the dnslookup wasn't successfull
  #break if an exempt exists
  if {
    !$status 
    || [matchexempt "$nick!$satmd_botnet(cgiirc_ban,ident)@$hostname"]
   } { return 0 }

  set banmask [satmd_botnet_genericbanmask $nick $uhost]
  #check for banlist
  #by channel
  foreach banline [banlist $channel] {
    if { [string match -nocase [lindex $banline 0] "$nick!$satmd_botnet(cgiirc_ban,ident)@$hostname"] } {
      newchanban $channel $banmask $botnick "[lindex $banline 1] (cgi:irc/open proxy)" 60
      return 0
    }
  }
  #by global banlist
  foreach banline [banlist] {
    if { [string match -nocase [lindex $banline 0] "$nick!$satmd_botnet(cgiirc_ban,ident)@$hostname"] } {
      satmd_botnet_gban_add $banmask "1h" "cgiircban@$botnick" $botnick "[lindex $banline 1] (cgi:irc/open proxy)" 1
      return 0
    }
  }
}

#Successfull
set satmd_botnet(version,cgiirc_ban) "0.1"
return 1
