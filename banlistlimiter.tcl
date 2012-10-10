# MODULE banlistlimiter
#
# this module watches the channel banlist and perform actions if the banlist is full or reached a specified amount of saved entries
#
# if the banlist is getting full and the server is sending an error,
# the module will set a new manual limit to prevent it from happen again and tries to resend the latest banmask
#
# satmd_botnet_banlistlimit
# == 0 the bot will not manually limit the size of the channel's banlist
# >= 1 bot will limit the channel's banlist to the specified amount of bans. if the amount is reached, the oldest ban is removed
# in case of "Banlist is full" the bot will set this value automatically to the highest possible number.
#
# satmd_botnet_banlistlimiter_purgeold
# + if set enabled, the bot will not only remove the ban from the channel's banlist but from the bot's internal banlist, too
#
# satmd_botnet_banlistlimiter_report_full_banlist
# + if set enabled, report all "Banlist is full" errors.
#


bind mode - "% +b" satmd_botnet_banlistlimiter_ban_mode_add
bind mode - "% -b" satmd_botnet_banlistlimiter_ban_mode_remove
bind join - "*" satmd_botnet_banlistlimiter_join
bind evnt "*" rehash satmd_botnet_banlistlimiter_rehash
bind raw - "368" satmd_botnet_banlistlimiter_banlist_end
bind raw - "478" satmd_botnet_banlistlimiter_banlist_full

setudef int "satmd_botnet_banlistlimit"
setudef flag "satmd_botnet_banlistlimiter_purgeold"
setudef flag "satmd_botnet_banlistlimiter_report_full_banlist"

proc satmd_botnet_banlistlimiter_join { nick uhost handle channel } {
  global satmd_botnet
  if {![isbotnick $nick]} { return 0 }
  
  set satmd_botnet(banlistlimiter,$channel) [list]
  utimer 5 [list satmd_botnet_banlistlimiter_rehash_channelbanlist $channel]
}

proc satmd_botnet_banlistlimiter_banlist_end { from keyword text } {
  set channel [lindex [split $text] 1]
  if { [botonchan $channel] } {
    #because there is a race condition, wait some seconds before unset bans
    #if this is done to early, eggdrop thinks it does not joined the channel yet and silently ignore all mode-requests
    #yes! even if botonchan just returns true. crazy.
    utimer 5 [list satmd_botnet_banlistlimiter_rehash_channelbanlist $channel]
  }
}
proc satmd_botnet_banlistlimiter_banlist_full { from keyword text } {
  global satmd_botnet

  set text [split $text]
  set channel [string tolower [lindex $text 1]]

  if { [botonchan $channel] } {
    #omg, banlist is full!
    set banmask [lindex $text 2]
    set banlist_length [llength $satmd_botnet(banlistlimiter,$channel)]
    set banlist_limit [channel get $channel "satmd_botnet_banlistlimit"]

    #lower limit so this won't happen again
    set newlimit [expr $banlist_length-1]
    channel set $channel "satmd_botnet_banlistlimit" $newlimit
    
    #report the case
    catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:banlistlimiter $channel: Banlist is full ($banlist_length entries)! Changed limit from $banlist_limit to $newlimit and try to ban $banmask again." }
    #delete oldest bans using the new limit
    satmd_botnet_banlistlimiter_checklimit $channel
    #make sure all bans are unset first before sending any new ones
    flushmode $channel
    
    #resend new ban
    pushmode $channel "+b" $banmask
  }
}

proc satmd_botnet_banlistlimiter_ban_mode_add { nick uhost handle channel mode target } {
  satmd_botnet_banlistlimiter_ban_add $channel $target [clock seconds]
}
proc satmd_botnet_banlistlimiter_ban_mode_remove { nick uhost handle channel mode target } {
  satmd_botnet_banlistlimiter_ban_remove $channel $target
}

proc satmd_botnet_banlistlimiter_ban_add { channel mask time } {
  global satmd_botnet
  #to keep all things save, make channels and masks case insensitive
  set channel [string tolower $channel]
  set mask [string tolower $mask]
  #check if already set (due to other scripts calling the banlist we would get all entries twice+)
  foreach entry $satmd_botnet(banlistlimiter,$channel) {
    if { [lindex $entry 1] == $mask } { return }
  }
  #entry was not saved yet, save it!
  lappend satmd_botnet(banlistlimiter,$channel) [list $time $mask]
  #sort it by creation timestamp
  set satmd_botnet(banlistlimiter,$channel) [lsort -integer -index 0 $satmd_botnet(banlistlimiter,$channel)]
  #check if we reached the limit
  satmd_botnet_banlistlimiter_checklimit $channel
}

proc satmd_botnet_banlistlimiter_ban_remove { channel mask } {
  global satmd_botnet

  #to keep all things save, make channels and masks case insensitive
  set channel [string tolower $channel]
  set mask [string tolower $mask]

  set temp [list]
  foreach entry $satmd_botnet(banlistlimiter,$channel) {
    if { [lindex $entry 1] == $mask } { continue }
    lappend temp $entry
  }
  set satmd_botnet(banlistlimiter,$channel) $temp
}

proc satmd_botnet_banlistlimiter_checklimit { channel } {
  global satmd_botnet
  #check if we really need to do something here
  set limit [channel get $channel "satmd_botnet_banlistlimit"]
  if { $limit <= 0 } { return }

  #calculate how many bans need to be deleted
  set todelete [expr [llength $satmd_botnet(banlistlimiter,$channel)] - $limit]
  if { $todelete <= 0 } { return }
  set i 0
  while {$todelete > 0 && $i < [llength $satmd_botnet(banlistlimiter,$channel)]} {
    set banmask [lindex $satmd_botnet(banlistlimiter,$channel) $i 1]
    #sticky bans can couse a serious problem, see below the for-loop for the handling
    #for the first glance, just ignore them
    if { [isbansticky $banmask $channel] } {
        #jup to the text ban in line
        set i [expr $i+1]
        continue
    }
    #found a non-sticky banlist we can delete
    #delete from list
    set satmd_botnet(banlistlimiter,$channel) [lreplace $satmd_botnet(banlistlimiter,$channel) $i $i]
    if { [channel get $channel "satmd_botnet_banlistlimiter_purgeold"] } { 
      killchanban $channel $banmask
    }
    pushmode $channel "-b" $banmask
    #one less we need to care of
    set todelete [expr $todelete - 1]
  }
  for {set i 0} {$i < $todelete} {incr i} {
    #holy crap, we still have bans we need to delete?
    #that happens, if the limit is lower than the number of sticky bans we have saved
    #only solution is to unsticky the oldest bans as many as we need to get below the limit
    set banmask [lindex $satmd_botnet(banlistlimiter,$channel) 0 1]
    #unshift
    set satmd_botnet(banlistlimiter,$channel) [lreplace $satmd_botnet(banlistlimiter,$channel) 0 0]
    #unstick it
    unstick $banmask $channel
    #because it's a sticky ban, it isn't checked for purging.. that wouldn't make any sense, does it?
    #just push the deletion
    pushmode $channel "-b" $banmask
  }
}

proc satmd_botnet_banlistlimiter_rehash { evnt } {
  foreach channel [channels] {
    if { ![botonchan $channel] } { continue }
    satmd_botnet_banlistlimiter_rehash_channelbanlist $channel
  }
}

proc satmd_botnet_banlistlimiter_rehash_channelbanlist { channel } {
  global satmd_botnet
  set channel [string tolower $channel]
  set satmd_botnet(banlistlimiter,$channel) [list]
  foreach entry [chanbans $channel] {
    satmd_botnet_banlistlimiter_ban_add $channel [lindex $entry 0] [expr [clock seconds]-[lindex $entry 2]]
  }
}

set satmd_botnet(version,banlistlimiter) "0.1"
return 1