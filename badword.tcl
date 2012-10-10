# MODULE badword
# This module is depricated! use antispam.tcl instead!
# ----------
#
#
# ban a user if he/she wrote a forbidden word or string for 14 days (global) or 24h (local)
#
# badwords are saved in badword.db in your satmd-botnet folder
#
# to look up the badwords typ .badwords [*badword*] on the partyline
# 
# all spammers who spam badwords will be announce through the report module - if you have this module enabled ;)
#
# ToDo.. dcc-commands for add/del (?)
# balance for badwords
#

satmd_botnet_require gban

bind pub nG|G  "$satmd_botnet(cmdchar)badword"               satmd_botnet_badword_pub
bind bot -|-  "badword"                          satmd_botnet_badword_bot
bind pub -|-  "$satmd_botnet(cmdchar)delbadword"             satmd_botnet_badword_pub_del
bind dcc -|- "badwords"          satmd_botnet_badword_lookup_dcc

#MAIN badword funktion (add+delete!)
proc satmd_botnet_badword_main { handle channel badword forward act} {
	global satmd_botnet
 
	set filename "$satmd_botnet(basepath)/badword.db.TMP"
	set fid [open $filename "w"]

	set add_badword 1
	#add old badwords and delete the badword if DEL-command is used
	set fid [open "$satmd_botnet(basepath)/badword.db"]
	while {[gets $fid badwordline] >= 0} {
		if { $badwordline != "" } { 
			switch $act {
				ADD { 
					puts -nonewline $fid "$badwordline\n"    
					if { ("[lrange [split $badwordline] 3 end]" == "$badword") && ("[lindex [split $badwordline] 2]" == "-all") } { set add_badword 0 }
				}
				DEL {
					if { "[lrange [split $badwordline] 3 end]" != "$badword" } { puts -nonewline $fid "$badwordline\n" }
				}
			}
		}
	}
	close $fid

	#add new badword or delete old bind
	switch $act {
		ADD { 
			if { $add_badword == 1 } {
				puts $fid "[clock seconds] $handle $channel $badword"
				bind pubm -|- "$badword" satmd_botnet_badword_gban
			}
			putcmdlog "satmd_botnet:badword add \"$badword\" by $handle"
		}
		DEL {
			unbind pubm -|- "$badword" satmd_botnet_badword_gban
			putcmdlog "satmd_botnet:badword del \"$badword\" by $handle"
		}
	}
	#close file and save
	close $fid
	file delete "$satmd_botnet(basepath)/badword.db"
	file rename "$satmd_botnet(basepath)/badword.db.TMP" "$satmd_botnet(basepath)/badword.db"

	if { $forward == 1 } {
		putallbots "badword $handle $channel $badword $act"
	}
	return 1
}

# Handle remote (bot) badword ADD/DEL
proc satmd_botnet_badword_bot { frombot keyword text } {
	global botnick
	global satmd_botnet
	set text [split $text]
	if { [matchattr $frombot "G"] } {
		set action [lindex $text end]
		set badword [join [lrange $text 2 end-1]]
		set handle [lindex $text 0]
		set channel [lindex $text 1]
		switch $action {
			ADD {
				satmd_botnet_badword_main $handle "$channel" "$badword" 0 "ADD"
			}
			DEL {
				satmd_botnet_badword_main $handle "$channel" "$badword" 0 "DEL"
			}
		}
	}
	return 0
}




#public ADD badword
proc satmd_botnet_badword_pub { nick uhost handle channel text } {
	global botnick
	global satmd_botnet
	set text [split $text]
	set channel_text [lindex $text 0]
	set text [lrange $text 1 end]

	if { ((!( [matchattr $handle nG|G $channel] )) && ("$channel" == "global"))} { return 0 }
	if { (!( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle olGN|olG $channel] ))} { return 0 }

	if { $channel_text == "global" } {
		set channel "-all"
	} elseif { $channel_text == "local" } { 
		set channel "$channel"
	} else { 
		return 0
	}
	if { [satmd_botnet_badword_main $handle "$channel" "$text" 1 "ADD"] } {
		putnotc $nick "(Badword) Channel:($channel) Badword:($text) added"
	}
	return 0
}

#public DELETE badword
proc satmd_botnet_badword_pub_del { nick uhost handle channel text } {
	global botnick
	global satmd_botnet
	set channel "-all"
	if { (!( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle olGN|olG $channel] ))} { return 0 }

	if { [satmd_botnet_badword_main $handle "$channel" "$text" 1 "DEL"] } {
		putnotc $nick "(Badword) Badword:($text) deleted"
	}
	return 0
}




#handle badwords - gban
proc satmd_botnet_badword_gban { nick uhost handle channel text} {
	#putloglev "d" "*" "DEBUG badword: $nick $uhost $handle $channel $text"
	if { ([string index $channel 0] != "#") } { return 0}
	global botnick
	global satmd_botnet
	set banstring ""
	set doban_global 0
	set doban_local 0
	if {  (!([isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle "mnolfb|mnolfb" $channel] || [isbotnick $nick]))} {

	set fid [open "$satmd_botnet(basepath)/badword.db"]
	while {[gets $fid badwordline] >= 0} {
		if { $badwordline != "" } { 
			#putloglev "d" "*" "DEBUG Badword: [lrange [split $badwordline] 3 end] - Date: [lindex [split $badwordline] 0] - Creator: [lindex [split $badwordline] 1] - Channel: [lindex [split $badwordline] 2]"
			if { ([string match -nocase "[lrange [split $badwordline] 3 end]" $text]) && ("[lindex [split $badwordline] 2]" == "$channel") } {
				set doban_local 1
				set banstring "[lrange [split $badwordline] 3 end]"
				break
			}
			if { ([string match -nocase "[lrange [split $badwordline] 3 end]" $text]) && ("[lindex [split $badwordline] 2]" == "-all") } {
				set doban_global 1
				set banstring "[lrange [split $badwordline] 3 end]"
				break
				}
			}
		}
		close $fid
	}
	if { $doban_global == 1 } {
		catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:badword $nick!$uhost/$handle triggered a global-badword:$banstring on $channel" }
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		satmd_botnet_gban_add $banmask "14d" "badword@$botnick" $botnick "user $nick removed for writing a blacklisted string" 1
		putloglev d $channel "botnet.tcl:badword: user $nick removed for writing a blacklisted string"
	}
	if { $doban_local == 1 } {
		#catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:badword $nick!$uhost/$handle triggered a local-badword:$banstring on $channel" }
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		newchanban "$channel" "$banmask" "$botnick" "user $nick removed for writing a blacklisted string" 1440
		putloglev d $channel "botnet.tcl:badword: user $nick removed for writing a blacklisted string"
	}
}
	
#Handle .badwords on partyline
proc satmd_botnet_badword_lookup_dcc {hand idx text} {
	global satmd_botnet
	set badwords 0
	if { $text == "" } { set text "*" }
	set fid [open "$satmd_botnet(basepath)/badword.db"]
	while {[gets $fid badwordline] >= 0} {
		if { ( ($badwordline != "") && ([string match -nocase "$text" "[lrange [split $badwordline] 3 end]"]) ) } {
			putlog "Badword: [lrange [split $badwordline] 3 end]"
			putlog "Creator: [lindex [split $badwordline] 1] - Channel: [lindex [split $badwordline] 2] - Created: [clock format [lindex [split $badwordline] 0] -format "%d-%b-%Y %H:%M"]"
			set badwords 1
		}
	}
	close $fid
	if {$badwords != 1 } { putlog "The badwordlist is empty." }
}

##autoload the file (restart or rehash)
if { (![file exists "$satmd_botnet(basepath)/badword.db"]) } {
	set filename "$satmd_botnet(basepath)/badword.db"
	set fid [open $filename "w"]
	close $fid
}

set fid [open "$satmd_botnet(basepath)/badword.db"]
while {[gets $fid badwordline] >= 0} {
	if { $badwordline != "" } { 
		#putloglev "d" "*" "DEBUG Badword: [lrange [split $badwordline] 3 end] - Date: [lindex [split $badwordline] 0] - Creator: [lindex [split $badwordline] 1] - Channel: [lindex [split $badwordline] 2]"
		bind pubm -|- [lrange [split $badwordline] 3 end] satmd_botnet_badword_gban
	}
}
close $fid

set satmd_botnet(version,badword) "0.2"
putloglev "db" "*" "satmd_botnet:badword.tcl is depricated! Use antispam.tcl instead!"
return 1

