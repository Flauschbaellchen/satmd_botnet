# MODULE antispam
#
# provides the "old" antijoin-spam script with a blacklist and a whitelist (saved in antispam_blacklist.db and antispam_whitelist.db in the same folder)
# both lists have global and local funktions included
# It supports normal strings and regexp-strings. To specify a regexp-sring use &R: in front of your string.
#
# all bans have a 14d timeline and will be in form of *!*@host
#
# Script by Noxx, irc.euirc.net
#
#
#
# Usage:
#
#-Public:
# !blacklist <local|global> <string>
# !delblacklist <local|global> <string>
#
# !whitelist <local|global> <string>
# !delwhitelist <local|global> <string>
#
#
#-Partyline
# .blacklist [*string*]
# .blacklist #channel [*string*]
# .+blacklist <#channel|-all> <*string*>
# .-blacklist <#channel|-all> <*string*>
#
# .whitelist [*string*]
# .whitelist #channel [*string*]
# .+whitelist <#channel|-all> <*string*>
# .-whitelist <#channel|-all> <*string*>
#
# .antispambalance <bot1[,bot2,bot3...]> - To request white/blacklists from another bot
#
#-Partyline Settings
# satmd_botnet_antijoinspam_delay      - Delay in seconds after the user can post an url, channel or serveradress and don't get a join+spam ban
# satmd_botnet_antispam_protect_voice  - If set to 1 (+) all users with voice are protected and don't trigger the onjoin-spam script or the blacklist
# satmd_botnet_antispam_blacklist      - If set to 1 (+) the blacklist is activated on the channel
# satmd_botnet_report_blacklist_global - If set to 1 (+) a report will be send if a global blacklist entry is hit
# satmd_botnet_report_blacklist_local  - If set to 1 (+) a report will be send if a local blacklist entry is hit
# satmd_botnet_report_onjoinspam       - If set to 1 (+) a report will be send if someone trigger the antijoinspam_delay
#

satmd_botnet_require gban
satmd_botnet_require depends

bind pub  -|-  "$satmd_botnet(cmdchar)blacklist"               satmd_botnet_blacklist_pub
bind pub  -|-  "$satmd_botnet(cmdchar)delblacklist"            satmd_botnet_blacklist_pub_del
bind dcc  -|-  "blacklist"                                     satmd_botnet_blacklist_lookup_dcc
bind dcc  -|-  "+blacklist"                                    satmd_botnet_blacklist_dcc
bind dcc  -|-  "-blacklist"                                    satmd_botnet_blacklist_dcc_del

bind pub  -|-  "$satmd_botnet(cmdchar)whitelist"               satmd_botnet_whitelist_pub
bind pub  -|-  "$satmd_botnet(cmdchar)delwhitelist"            satmd_botnet_whitelist_pub_del
bind dcc  -|-  "whitelist"                                     satmd_botnet_whitelist_lookup_dcc
bind dcc  -|-  "+whitelist"                                    satmd_botnet_whitelist_dcc
bind dcc  -|-  "-whitelist"                                    satmd_botnet_whitelist_dcc_del

bind bot  -|-  "antispam"                                      satmd_botnet_antispam_bot

bind pubm -|-  "*"                                             satmd_botnet_antispam_pubm
bind notc -|-  "*"                                             satmd_botnet_antispam_notc
bind msgm -|-  "*"                                             satmd_botnet_antispam_msgm
bind ctcp -|-  ACTION                                          satmd_botnet_antispam_act
bind sign -|-  "*"                                             satmd_botnet_antispam_partsign
bind part -|-  "*"                                             satmd_botnet_antispam_partsign

bind dcc  -|-  "antispambalance"                               satmd_botnet_antispamlist_balance_request
bind bot  -|-  "antispambalance_send"                          satmd_botnet_antispamlist_balance_send

setudef int "satmd_botnet_antijoinspam_delay"
setudef flag "satmd_botnet_antispam_protect_voice"
setudef flag "satmd_botnet_antispam_blacklist"
setudef flag "satmd_botnet_report_blacklist_global"
setudef flag "satmd_botnet_report_blacklist_local"
setudef flag "satmd_botnet_report_onjoinspam"

#-----------------------------------------------------------------
proc satmd_botnet_antispam_pubm { nick uhost handle channel text } {
	global botnick
	if { $botnick != $nick } {
		satmd_botnet_antispam $nick $uhost $handle $channel 0 $text
	}
}

proc satmd_botnet_antispam_notc { nick uhost handle text dest } {
	global botnick
	if { $botnick != $nick } {
		satmd_botnet_antispam_channellist $nick $uhost $handle $text
	}
}

proc satmd_botnet_antispam_msgm { nick uhost handle text } {
	global botnick
	if { $botnick != $nick } {
		satmd_botnet_antispam_channellist $nick $uhost $handle $text
	}
}

proc satmd_botnet_antispam_act { nick uhost handle dest keyword text } {
	global botnick
	if { $botnick != $dest } {
		satmd_botnet_antispam $nick $uhost $handle $dest 0 $text
	}
	return 0
}

proc satmd_botnet_antispam_partsign { nick uhost handle channel text } {
	global botnick
	if { $botnick != $nick } {
		satmd_botnet_antispam $nick $uhost $handle $channel 2 $text
	}
}

proc satmd_botnet_antispam_channellist { nick uhost handle text } {
	global satmd_botnet

	set satmd_botnet(antispam,channellist,$nick,global_blacklist) ""
	set satmd_botnet(antispam,channellist,$nick,local_blacklist) ""
	set satmd_botnet(antispam,channellist,$nick,joinspam_chanlist) ""

	foreach channel [channels] {
		if {[botonchan $channel] && [onchan $nick $channel] } {
			satmd_botnet_antispam $nick $uhost $handle $channel 1 "$text"
		}
	}

	if { $satmd_botnet(antispam,channellist,$nick,global_blacklist) != "" } {
		catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:antispam $nick!$uhost/$handle triggered the global-blacklist over msg/notc/part: [join $satmd_botnet(antispam,channellist,$nick,global_blacklist)] with \[$text\]" }
	}
	if { $satmd_botnet(antispam,channellist,$nick,local_blacklist) != "" } {
		catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:antispam $nick!$uhost/$handle triggered the local-blacklist over msg/notc/part: [join $satmd_botnet(antispam,channellist,$nick,local_blacklist)] with \[$text\]" }
	}
	if { $satmd_botnet(antispam,channellist,$nick,joinspam_chanlist) != "" } {
		catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:antispam $nick!$uhost/$handle triggered the antijoinspam delay over msg/notc on [join $satmd_botnet(antispam,channellist,$nick,joinspam_chanlist)] with \[$text\]" }
	}

}

#-----------------------------------------------------------------
#handle main antispam - gban
# private 0 = normal (channeltext)
# private 1 = notice/msg
# private 2 = part/quit
proc satmd_botnet_antispam { nick uhost handle channel private text} {
	global botnick
	global satmd_botnet
 
	#defaults
	set text [stripcontrolcodes $text]
	set banstring_global ""
	set banstring_local ""
	set doban_blacklist_global 0
	set doban_blacklist_local 0
	set doban_joinspam 0
	set whitelist_local 0
	set whitelist_global 0
	if {
		([string index $channel 0] != "#")
		|| [isop $nick $channel]
		|| [ishalfop $nick $channel]
		|| (([channel get $channel "satmd_botnet_antispam_protect_voice"] == 1) && [isvoice $nick $channel])
		|| [matchattr $handle "mnolfb|mnolfb" $channel]
		|| [isbotnick $nick]
	} {
		return 0
	}
	set chanjoin -1
	set delay -1
	set maxdelay 0
	if { [onchan $nick $channel] } {
		catch {
			set chanjoin [getchanjoin $nick $channel]
			set delay [expr [unixtime] - $chanjoin]
		}
		catch {
			set maxdelay [channel get $channel "satmd_botnet_antijoinspam_delay"]
		}
	}

	#putloglev d "$channel" "DEBUG: we hit a antispam.tcl code path: delay:$delay chanjoin:$chanjoin unixtime:[unixtime] nick:$nick handle:$handle channel:$channel"

	if { $private != 2 } {
		foreach textpart [split $text] {
			if { $delay < 0 || $chanjoin <=0 } {
				# Recent eggdrops seem to have trouble with netsplits, add some extra checks and preemptively log all code executions in here
				continue
			} elseif { $maxdelay < 1 || $delay > $maxdelay } {
				# Check the delay
				continue
			} elseif { [regexp "^#\[0-9\]*$" $textpart] == 1 } {
				#false positive
				continue
			} elseif { ([string match -nocase "*www.?*" $textpart] || [string match -nocase "*http*" $textpart] || [string match -nocase "*/server*" $textpart] || [string match "#*" $textpart] || [string match -nocase "irc://*" $textpart]) && (![string match "#$channel" "#$textpart"])  } {
				set doban_joinspam 1
			}
		}
	}

	if { $private == 2 } { set private 0 }

	set channel "[string tolower $channel]"

	if { ([channel get $channel "satmd_botnet_antispam_blacklist"] == 1) } {
		set fid [open "$satmd_botnet(basepath)/antispam_blacklist.db"]
		while {[gets $fid blacklistline] >= 0} {
			if { $blacklistline != "" } { 
				set blacklistline_match [matchsafe [join [lrange [split $blacklistline] 3 end]]]
				set blacklistline_match_regexp [join [lrange [split $blacklistline] 3 end]]
		
				#putloglev "d" "*" "DEBUG Blacklist: $blacklistline_match -> $text - Date: [lindex [split $blacklistline] 0] - Creator: [lindex [split $blacklistline] 1]  - Channel: [lindex [split $blacklistline] 2] - Stringmatch: [string match -nocase $blacklistline_match $text]"
				if { ([string match -nocase $blacklistline_match $text] || ([string match -nocase "&R:*" $blacklistline_match_regexp] && [regexp [string range $blacklistline_match_regexp 3 end] $text])) && ("[lindex [split $blacklistline] 2]" == "$channel") } {
					set doban_blacklist_local 1
					lappend banstring_local " \[[join [lrange [split $blacklistline] 3 end]]\]"
				}
				if { ([string match -nocase $blacklistline_match $text] || ([string match -nocase "&R:*" $blacklistline_match_regexp] && [regexp [string range $blacklistline_match_regexp 3 end] $text])) && ("[lindex [split $blacklistline] 2]" == "-all") } {
					set doban_blacklist_global 1
					lappend banstring_global " \[[join [lrange [split $blacklistline] 3 end]]\]"
				}
			}
		}
		close $fid
	}

	if { (($doban_joinspam == 1) && ($doban_blacklist_local == 0)) || ($doban_blacklist_global == 1) } {
		set fid [open "$satmd_botnet(basepath)/antispam_whitelist.db"]
		while {[gets $fid whitelistline] >= 0} {
			if { $whitelistline != "" } { 
				set whitelistline_match [matchsafe [join [lrange [split $whitelistline] 3 end]]]
				set whitelistline_match_regexp [join [lrange [split $whitelistline] 3 end]]
				#putloglev "d" "*" "DEBUG Whitelist: $whitelistline_match - Date: [lindex [split $whitelistline] 0] - Creator: [lindex [split $whitelistline] 1] - Channel: [lindex [split $whitelistline] 2]"
				if { ([string match -nocase $whitelistline_match $text] || ([string match -nocase "&R:*" $whitelistline_match_regexp] && [regexp [string range $whitelistline_match_regexp 3 end] $text])) && ("[lindex [split $whitelistline] 2]" == "$channel") } {
					set whitelist_local 1
				}
				if { ([string match -nocase $whitelistline_match $text] || ([string match -nocase "&R:*" $whitelistline_match_regexp] && [regexp [string range $whitelistline_match_regexp 3 end] $text])) && ("[lindex [split $whitelistline] 2]" == "-all") } {
					set whitelist_global 1
				}
			}
		}
		close $fid
	}

	#putloglev "d" "*" "DEBUG antispam: doban_blacklist_global:$doban_blacklist_global, doban_blacklist_local:$doban_blacklist_local - whitelist_global:$whitelist_global, whitelist_local:$whitelist_local - doban_joinspam:$doban_joinspam"

	set banmask [satmd_botnet_genericbanmask $nick $uhost]

	#global
	if { ($doban_blacklist_global == 1) && ($whitelist_local == 0) } {
		if { ([channel get $channel "satmd_botnet_report_blacklist_global"] == 1) } {
			if { $private != 1 } {
				catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:antispam $nick!$uhost/$handle triggered the global-blacklist on $channel: [join $banstring_global] with \[$text\]" }
			} else {
				set satmd_botnet(antispam,channellist,$nick,global_blacklist) "[join $banstring_global]"
			}
		}
		satmd_botnet_gban_add $banmask "14d" "antispam@$botnick" $botnick "user $nick removed for writing a global blacklisted string" 1
		putloglev d $channel "botnet.tcl:antispam: user $nick removed for writing a global blacklisted string"
	}

	#local
	if { ($doban_blacklist_local == 1) } {
		if { ([channel get $channel "satmd_botnet_report_blacklist_local"] == 1) } {
			if { $private != 1 } {
				catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:antispam $nick!$uhost/$handle triggered the local-blacklist on $channel: [join $banstring_local] with \[$text\]" }
			} else {
				lappend satmd_botnet(antispam,channellist,$nick,local_blacklist) "$channel: [join $banstring_local] "
			}
		}
		newchanban "$channel" "$banmask" "$botnick" "user $nick removed for writing a local blacklisted string" 20160
		putloglev d $channel "botnet.tcl:antispam: user $nick removed for writing a local blacklisted string"
	}

	#onjoinspam
	if { ($doban_joinspam == 1) && ($whitelist_global == 0) && ($whitelist_local == 0) } {
		if { ([channel get $channel "satmd_botnet_report_onjoinspam"] == 1) } {
			if { $private != 1 } {
				catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:antispam $nick!$uhost/$handle triggered the antijoinspam delay on $channel: \[$text\]" }
			} else {
				lappend satmd_botnet(antispam,channellist,$nick,joinspam_chanlist) "$channel "
			}
		}
		satmd_botnet_gban_add $banmask "14d" "antispam@$botnick" $botnick "user $nick removed for join+spam" 1
		putloglev d $channel "botnet.tcl:antispam: user $nick removed for join+spam"
	}
}



#-----------------------------------------------------------------
#ADD || DEL funktion for files
proc satmd_botnet_antispam_file { handle channel text forward act file} {
	global satmd_botnet
 
	set filename "$satmd_botnet(basepath)/antispam_$file.db.TMP"
	set fileId [open $filename "w"]

	#defaults
	set add_file 1
	set del_success 0
	set channel [string tolower $channel]
	set success 0
	set text [join $text]

	#add old entrys and delete the entry if DEL-command is used
	set fid [open "$satmd_botnet(basepath)/antispam_$file.db"]
	while {[gets $fid fileline] >= 0} {
		if { $fileline != "" } {
			set lineentry "[join [lrange [split $fileline] 3 end]]"
			set chanentry "[string tolower [lindex [split $fileline] 2]]"
			switch $act {
				ADD { 
					puts -nonewline $fileId "$fileline\n"    
					if { ("$lineentry" == "$text") && ("$chanentry" == "$channel") } { set add_file 0 }
				}
				DEL {
					if { ("$lineentry" != "$text") || ("$chanentry" != "$channel") } { puts -nonewline $fileId "$fileline\n" }
					if { ("$lineentry" == "$text") && ("$chanentry" == "$channel") } { set del_success 1 }
				}
			}
		}
	}
	close $fid

	#add the entry && putcmdlog
	switch $act {
		ADD { 
			if { $add_file == 1 } { 
				putcmdlog "satmd_botnet:$file add \"$text\" by $handle for $channel"
				puts $fileId "[clock seconds] $handle $channel $text"
				set success 1
			} else {
				set success 0
			}
		}
		DEL {
			if { $del_success == 0 } {
				set success 0 
			} else { 
				putcmdlog "satmd_botnet:$file del \"$text\" by $handle for $channel"
				set success 1
			}
		}
	}
	#close file and save
	close $fileId
	file delete "$satmd_botnet(basepath)/antispam_$file.db"
	file rename "$satmd_botnet(basepath)/antispam_$file.db.TMP" "$satmd_botnet(basepath)/antispam_$file.db"

	if { $forward == 1 } {
		putallbots "antispam $handle $channel $text $act $file"
	}
	return $success
}


#-----------------------------------------------------------------
# Handle remote (bot) antispam ADD/DEL white/blacklist
proc satmd_botnet_antispam_bot { frombot keyword text } {
	global botnick
	global satmd_botnet
	set text [split $text]
	if { [matchattr $frombot "G"] } {
		set action [lindex $text end-1]
		set blacklist [join [lrange $text 2 end-2]]
		set handle [lindex $text 0]
		set channel [lindex $text 1]
		set file [lindex $text end]
		satmd_botnet_antispam_file $handle "$channel" "$blacklist" 0 "$action" "$file"
	}
return 1
}



#-----------------------------------------------------------------
#public DELETE/ADD blacklist/whitelist (MAIN)
proc satmd_botnet_antispam_pub { nick uhost handle channel file action text } {
	global botnick
	global satmd_botnet

	set text [split $text]
	set channel_text [lindex $text 0]
	set noticetext [join [lrange [stripcontrolcodes $text] 1 end]]
	set text [lrange [stripcontrolcodes $text] 1 end]

	if { [string length $text] == 0 } { return 0 }

	if { ![matchattr $handle nG|G $channel] && "$channel_text" == "global"} { return 0 }
	if { !([isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle olGN|olG $channel])} { return 0 }

	if { $channel_text == "global" } {
		set channel "-all"
	} elseif { $channel_text == "local" } { 
		set channel "$channel"
	} else {
		return 0
	}

	if { [satmd_botnet_antispam_file "$nick/$handle" "$channel" "$text" 1 "$action" "$file"] } {
		switch $action {
			ADD { putnotc $nick "($file) channel:($channel) text:($noticetext) added" }
			DEL { putnotc $nick "($file) channel:($channel) text:($noticetext) deleted" }
		}
	} else {
		switch $action {
			ADD { putnotc $nick "($file) Entry already exist. Nothing added." }
			DEL { putnotc $nick "($file) Entry not found. Nothing deleted." }
		}
	}
	return 1
}


#Handle DELETE public whitelist
proc satmd_botnet_whitelist_pub_del {nick uhost handle channel text} {
	satmd_botnet_antispam_pub $nick $uhost $handle $channel "whitelist" "DEL" "$text" 
}
#Handle DELETE public blacklist
proc satmd_botnet_blacklist_pub_del {nick uhost handle channel text} {
	satmd_botnet_antispam_pub $nick $uhost $handle $channel "blacklist" "DEL" "$text"
}

#Handle ADD public whitelist
proc satmd_botnet_whitelist_pub {nick uhost handle channel text} {
	satmd_botnet_antispam_pub $nick $uhost $handle $channel "whitelist" "ADD" "$text" 
}
#Handle ADD public blacklist
proc satmd_botnet_blacklist_pub {nick uhost handle channel text} {
	satmd_botnet_antispam_pub $nick $uhost $handle $channel "blacklist" "ADD" "$text"
}


#-----------------------------------------------------------------
#partyline DELETE/ADD blacklist/whitelist (MAIN)
proc satmd_botnet_antispam_dcc { hand idx file action text } {
	global satmd_botnet
	set text [split $text]
	set dccchannel [lindex $text 0]
		if { $dccchannel == "-all" } { 
			set channel "-all"
		} elseif { [string match -nocase "#*" $dccchannel] } {
			set channel $dccchannel
		} else {
			putidx $idx "Usage: .+$file <#channel|-all> <string>"
			return 0
		}
	set antispamtext [lrange [stripcontrolcodes $text] 1 end]
	set noticetext [join [lrange [stripcontrolcodes $text] 1 end]]

	if { ![matchattr $hand noG|G] && "$channel" == "-all"} {
		putidx $idx "You have not the requiered flags for $action a global entry."
		return 0
	}
	if { ![matchattr $hand olGN|olG $channel]} {
		putidx $idx "You have not the requiered flags for $action a local entry for $channel."
		return 0
	}

	if { [string length $antispamtext] == 0 } {
		putidx $idx "Usage: .+$file <#channel|-all> <string>"
		return 0
	}

	if { [satmd_botnet_antispam_file "DCC/$hand" "$channel" "$antispamtext" 1 "$action" "$file"] } {
		switch $action {
			ADD { putidx $idx "($file) channel:($channel) text:($noticetext) added" }
			DEL { putidx $idx "($file) channel:($channel) text:($noticetext) deleted" }
		}
	} else {
		switch $action {
			ADD { putidx $idx "($file) Entry already exist. Nothing added." }
			DEL { putidx $idx "($file) Entry not found. Nothing deleted." }
		}
	}
	return 1
}

#Handle ADD DCC whitelist
proc satmd_botnet_whitelist_dcc {hand idx text} {
	satmd_botnet_antispam_dcc $hand $idx "whitelist" "ADD" $text
}
#Handle DELETE DCC whitelist
proc satmd_botnet_whitelist_dcc_del {hand idx text} {
	satmd_botnet_antispam_dcc $hand $idx "whitelist" "DEL" $text
}
#Handle ADD DCC blacklist
proc satmd_botnet_blacklist_dcc {hand idx text} {
	satmd_botnet_antispam_dcc $hand $idx "blacklist" "ADD" $text
}
#Handle DELETE DCC blacklist
proc satmd_botnet_blacklist_dcc_del {hand idx text} {
	satmd_botnet_antispam_dcc $hand $idx "blacklist" "DEL" $text
}


#-----------------------------------------------------------------
#Handle .blacklist/whitelist on partyline (MAIN)
proc satmd_botnet_antispam_lookup_dcc {idx text} {
	global satmd_botnet
	set foundentry 0
	set findmask ""
	set channel_exists 0

	set text [split $text]
	set file [lindex $text 0]
	set channel [lindex $text 1]

	if { ([string match -nocase "#*" $channel]) } {
		set channel $channel
		set findmask [lrange $text 2 end]
		set channel_exists 1
	}
	if { $channel_exists == 0 } {
		set findmask [lrange $text 1 end]
		set channel "*"
	}

	if { $findmask == "{}" || $findmask == "" } { set findmask "*" }
	set fid [open "$satmd_botnet(basepath)/antispam_$file.db"]
	while {[gets $fid listline] >= 0} {
		if { ( ($listline != "") && ([string match -nocase "[join [matchsafe $findmask]]" "[join [lrange [split $listline] 3 end]]"])&&([string match -nocase "[string tolower $channel]" "[lindex [split $listline] 2]"]) ) } {
			putidx $idx "$file: [join [lrange [split $listline] 3 end]]"
			putidx $idx "-- Creator: [lindex [split $listline] 1] - Channel: [lindex [split $listline] 2] - Created: [clock format [lindex [split $listline] 0] -format "%d-%b-%Y %H:%M"]"
			set foundentry 1
		}
	}
	close $fid
	if {$foundentry != 1 } { putidx $idx "No entrys were found in the $file that match your search criteria. (Channel: $channel - Mask: $findmask)" }
}

#Handle .whitelist on partyline
proc satmd_botnet_whitelist_lookup_dcc {hand idx text} {
	satmd_botnet_antispam_lookup_dcc "$idx" "whitelist $text" 
}
#Handle .blacklist on partyline
proc satmd_botnet_blacklist_lookup_dcc {hand idx text} {
	satmd_botnet_antispam_lookup_dcc "$idx" "blacklist $text" 
}


#balance for white and blacklists
proc satmd_botnet_antispamlist_balance_request {hand idx text} {
	global satmd_botnet
	if {([lindex $text 0] == "")} {
		putidx $idx "Usage: .antispambalance <bot\[,bot2,bot3...\]>"
		return 0
	}

	set bots [split $text ,]
	foreach bot $bots {
			if {![isbot_antispam $bot]} {
				putidx $idx "Cannot find $bot on botnet. (not linked?)"
				return 0
			}
		set satmd_botnet(balance,$bot,[lindex $text 1],count) 0
		putidx $idx "Request antispam lists from $bot"
		putbot $bot "antispambalance_send"
	}
}

proc satmd_botnet_antispamlist_balance_send {bot idx text} {
	global satmd_botnet
	set listfiles [split "blacklist whitelist"]
	foreach file $listfiles {
		set fid [open "$satmd_botnet(basepath)/antispam_$file.db"]
		while {[gets $fid fileline] >= 0} {
			if { $fileline != "" } {
				set lineentry "[string tolower [join [lrange [split $fileline] 3 end]]]"
				set channel "[string tolower [lindex [split $fileline] 2]]"
				set creator [lindex [split $fileline] 1]
				set date [lindex [split $fileline] 0]
				putbot $bot "antispam $creator $channel $lineentry ADD $file"
			}
		}
		close $fid
	}
}

proc isbot_antispam {cbot} {
	foreach bot [botlist] { if {$cbot == [lindex $bot 0]} {return 1} }
	if {$cbot != [lindex $bot 0]} {return 0}
}


#-----------------------------------------------------------------
##autocreate the files (restart or rehash)
if { (![file exists "$satmd_botnet(basepath)/antispam_blacklist.db"]) } {
	set filename "$satmd_botnet(basepath)/antispam_blacklist.db"
	set fileId [open $filename "w"]
	close $fileId
}
if { (![file exists "$satmd_botnet(basepath)/antispam_whitelist.db"]) } {
	set filename "$satmd_botnet(basepath)/antispam_whitelist.db"
	set fileId [open $filename "w"]
	close $fileId
}


set satmd_botnet(version,antispam) "0.5"
return 1
