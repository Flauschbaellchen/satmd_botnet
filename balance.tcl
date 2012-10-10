# MODULE balance
# this module provides an update of gbans and gexempts

### we have three configuration variables

# set this to the time in minutes you want wait for a bot to offer you the bans, before timeout

#set satmd_botnet(balance,timeout) "1"

# set this to the prefix that will match gbans
# the normal prefix will be "gban" 
# while !gban <nick!ident@host> <time> <reason> will save bans in banlist with the "-- gban" prefix on end of reason
# if you use another prefix set this to your prefix
# or you want to become _any_ global ban from <bot> set this to "*"

#set satmd_botnet(balance,bans,prefix) "gban"

# set this to the prefix that will match gexempts
# the normal prefix will be "gexempt" 
# while !gexempt <nick!ident@host> <time> <reason> will save exempts in exemptlist with the "-- gexempt" prefix on end of reason
# if you use another prefix set this to your prefix
# or you want to become _any_ global exempt from <bot> set this to "*"

#set satmd_botnet(balance,exempts,prefix) "gexempt"

### end of configuration


bind bot -|- "satmd_botnet_balance_request" satmd_botnet_balance_request
bind bot -|- "satmd_botnet_balance_offer" satmd_botnet_balance_offer
bind dcc - "balance" satmd_botnet_balance

proc satmd_botnet_balance {hand idx text} {
	global satmd_botnet
	if {([lindex $text 1] != "bans") && ([lindex $text 1] != "exempts") && ([lindex $text 1] != "badwords")} {
		putlog "Usage: .balance <bot> <bans|exempts|badwords>"
		putlog "you can define more bots by seperating them with \",\" e.g. .balance bot,bot1,bot2,bot3 bans"
		return 0
	}
	set bots [split [lindex $text 0] ,]
	foreach bot $bots {
		if {![isbot $bot]} {
			putlog "cannot find $bot on botnet. (not linked?)"
			return 0
		}
		set satmd_botnet(balance,$bot,[lindex $text 1],count) 0
		putlog "request [lindex $text 1] from $bot"
		set satmd_botnet(balance,$bot,timeout) [after [expr 60000 * $satmd_botnet(balance,timeout)] [list satmd_botnet_balance_timeout $bot]]
		putbot $bot [list satmd_botnet_balance_request [lindex $text 1]]
	}
}


proc satmd_botnet_balance_request {bot keyword text} {
	global satmd_botnet
	if {$text == "bans"} {
		putlog "$bot requestet update of bans"
		foreach cban [banlist] {
			set ban [lindex $cban 0]
			set reason [lindex $cban 1]
			set duration [lindex $cban 2]
			putbot $bot [list satmd_botnet_balance_offer bans $ban $reason $duration]
		}
		putbot $bot [list satmd_botnet_balance_offer bans EOF]
		return 0
	}
	if {$text == "exempts"} {
		putlog "$bot requestet update of exempts"
		foreach cexem [exemptlist] {
			set exem [lindex $cexem 0]
			set reason [lindex $cexem 1]
			set duration [lindex $cexem 2]
			putbot $bot [list satmd_botnet_balance_offer exempts $exem $reason $duration]
		}
		putbot $bot [list satmd_botnet_balance_offer exempts EOF]
		return 0
	}
	if {$text == "badwords"} {
		putlog "$bot requestet update of badwords"
		if { ([file exists "$satmd_botnet(basepath)/badword.db"]) } {
			set fid [open "$satmd_botnet(basepath)/badword.db"]
			while {[gets $fid badwordline] >= 0} {
				if { ($badwordline != "") } {
					putbot $bot [list satmd_botnet_balance_offer badwords $badwordline]
				}
			}
			close $fid
		}
		putbot $bot [list satmd_botnet_balance_offer badwords EOF]
		return 0
	}
}


proc satmd_botnet_balance_offer {bot keyword text} {
	global satmd_botnet
	if {[info exists satmd_botnet(balance,$bot,timeout)]} {
		after cancel [list "$satmd_botnet(balance,$bot,timeout)"]
		unset satmd_botnet(balance,$bot,timeout)
	}
	set updatetype [lindex $text 0]
	if {[lindex $text 1] == "EOF"} {
		putlog "$bot: updated $satmd_botnet(balance,$bot,$updatetype,count) $updatetype"
		unset satmd_botnet(balance,$bot,$updatetype,count)
		return 0
	}
	if {$updatetype == "bans"} {
		set ban [lindex $text 1]
		set reason [lindex $text 2]
		set prefix [lindex $reason [expr [llength $reason] - 1]]
		set duration [expr ([lindex $text 3] - [unixtime]) / 60]
		if {![string match "$satmd_botnet(balance,$updatetype,prefix)" "$prefix"]} {
			return 0
		}
		if {![isban $ban]} {
			incr satmd_botnet(balance,$bot,$updatetype,count)
			newban $ban $bot $reason $duration
			return 0
		}
	}
	if {$updatetype == "exempts"} {
		set exem [lindex $text 1]
		set reason [lindex $text 2]
		set prefix [lindex $reason [expr [llength $reason] - 1]]
		set duration [expr ([lindex $text 3] - [unixtime]) / 60]
		if {![string match "$satmd_botnet(balance,$updatetype,prefix)" "$prefix"]} {
			return 0
		}
		if {![isexempt $exem]} {
			incr satmd_botnet(balance,$bot,$updatetype,count)
			newexempt $exem $bot $reason $duration
			return 0
		}
	}

	if {$updatetype == "badwords"} {
		set text [split [lindex $text 1]]
		set date [lindex $text 0]
		set creator [lindex $text 1]
		set channel [lindex $text 2]
		set badword [join [lrange $text 3 end]]

		set badword_exists 0
		if { (![file exists "$satmd_botnet(basepath)/badword.db"]) } {
			set filename "$satmd_botnet(basepath)/badword.db"
			set fileId [open $filename "w"]
			close $fileID
		}

		set fid [open "$satmd_botnet(basepath)/badword.db"]
		set content [read $fid]
		close $fid

		foreach badwordline [split $content "\n"] {
			if { ("[lrange [split $badwordline] 3 end]" == "$badword") && ("[lindex [split $badwordline] 2]" == "$channel") } {
				set badword_exists 1
				break
			}
		}
		if { $badword_exists == 0 } {
			set fid [open "$satmd_botnet(basepath)/badword.db" "a"]
			puts -nonewline $fid "$date $creator $channel $badword\n"
			close $fid
			bind pubm -|- "$badword" satmd_botnet_badword_gban
			incr satmd_botnet(balance,$bot,$updatetype,count)
		}
		return 0
	}
}

proc satmd_botnet_balance_timeout {bot} {
	putlog "$bot does not answer, timeout."
}

proc isbot {cbot} {
	foreach bot [botlist] { if {$cbot == [lindex $bot 0]} {return 1} }
	if {$cbot != [lindex $bot 0]} {return 0}
}


#Successfull
set satmd_botnet(version,balance) "0.1"
return 1

