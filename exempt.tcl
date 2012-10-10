# MODULE exempt
#
# This module provides a botnet-global exempt system WITHOUT sharing module
# Examples:
# !exempt exemptmask duration reason
# !unexempt exemptmask [reason]
# .exempt add exemptmask duration reason
# .exempt del exemptmask [reason]

# forked on 2007-08-01 from gban.tcl with version 0.7.4 -> 0.1

# bind GEXEMPT commands
bind pub nG|Gnmo  "$satmd_botnet(cmdchar)exempt"                 satmd_botnet_exempt_pub
bind pub -|-  "$satmd_botnet(cmdchar)unexempt"                satmd_botnet_unexempt_pub
bind bot -|-  "exempt"                   satmd_botnet_exempt_bot
bind dcc nG|Gnmo  "lexempt"                  satmd_botnet_exempt_dcc
bind dcc nG|Gnmo  "+lexempt"				   satmd_botnet_exempt_dcc_add
bind dcc nGmno|Gnmo  "-lexempt"           satmd_botnet_exempt_dcc_del

# Create GEXEMPT udef
setudef flag "satmd_botnet_exempt"

# Handle public EXEMPT
proc satmd_botnet_exempt_pub { nick uhost handle channel text } {
	global botnick
	set text [split $text]
#	if { ( [matchattr [nick2hand $nick] nGN|G $channel] ) } {
		set target [lindex $text 0]
		if { [onchan $target] } {
			set target "*!*@[lindex [split [getchanhost $target] @] 1]"
		}
		set duration [lindex $text 1]
		set reason [join [lrange $text 2 end]]
		if { [lindex $text 1] == "force" } {
			set duration [lindex $text 2]
			set reason [join [lrange $text 3 end]]
			if { [matchattr $handle "nG|-"] } {
				putnotc $nick "exempt: forcefully accepted."
			} else {
				putnotc $nick "exempt: denied. invalid syntax (\"force\" is reserved)"
				return 0
			}
		} else { 
			set duration [lindex $text 1]
			set readon [join [lrange $text 2 end]]
		}
		
		if { [satmd_botnet_exempt_add $channel $target $duration "$nick!$uhost" $handle $reason 1] } {
			putnotc $nick "(Local Exempt) Exemptmask:($target) Reason:($reason) Lifetime:($duration) added"
		}
#	}
	return 0
}

# Handle public UNEXEMPT
proc satmd_botnet_unexempt_pub { nick uhost handle channel text } {
	global botnick
	set text [split $text]
	if { [matchattr $handle G|G $channel] || (( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle olGN|olG $channel] ) && [channel get $channel "satmd_botnet_exempt"] == 1)} {
		set target [join [lindex $text 0]]
		set reason [join [lrange $text 1 end]]
		if { [satmd_botnet_exempt_del $channel $target "$nick!$uhost" "$handle" $reason 1] } {
			putnotc $nick "(Local Exempt) Exemptmask:($target) removed"
		}
	}
	return 0
}

# Handle remote (bot) EXEMPT
proc satmd_botnet_exempt_bot { frombot keyword text } {
#	if { [isbotnick $frombot]} { return 1}
	global botnick
	set text [split $text]
#	putlog "DEBUG $text"
	if { [matchattr $frombot "G"] } {
		set action [lindex $text 0]
		switch $action {
			add {
				set channel [lindex $text 1]
				set target  [lindex $text 2]
				set duration [lindex $text 3]
				set mask [lindex $text 4]
				set handle [lindex $text 5]
				set reason [join [lrange $text 6 end]]
				satmd_botnet_exempt_add $channel $target $duration "$mask@$frombot" $handle $reason 0
			}
			del {
				set channel [lindex $text 1]
				set target [join [lindex $text 2]]
				set mask [lindex $text 3]
				set handle [lindex $text 4]
				set reason [join [lrange $text 5 end]]
				satmd_botnet_exempt_del $channel $target "$mask@$frombot" $handle $reason 0
			}
		}
	}
	return 0
}

# Handle partyline EXEMPT/UNEXEMPT
proc satmd_botnet_exempt_dcc_add { handle idx text} {
	satmd_botnet_exempt_dcc $handle $idx "add $text"
}
proc satmd_botnet_exempt_dcc_del { handle idx text} {
	satmd_botnet_exempt_dcc $handle $idx "del $text"
}
proc satmd_botnet_exempt_dcc {handle idx text} {
	global botnick
	set action [lindex $text 0]
	set channel [lindex $text 1]
	set target [lindex $text 2]
	if { [string tolower $action] == "add" } {
		if { [onchan $target] } {
			set target "*!*@[lindex [split [getchanhost $target] @] 1]"
		}
		if { [lindex $text 3] == "force" } {
			if { [matchattr $handle "nG|-"] } {
				set duration [lindex $text 4]
				set reason [join [lrange $text 5 end]]
				putidx $idx "exempt: forcefully accepted."
			} else {
				putidx $idx "exempt: denied. invalid syntax (\"force\" is reserved )"
				return 0
			}
		} else {
			set duration [lindex $text 3]
			set reason [join [lrange $text 4 end]]
		}
		satmd_botnet_exempt_add $channel $target $duration "[hand2nick $handle]![getchanhost [hand2nick $handle]]" $handle $reason 1
		putcmdlog "satmd_botnet:exempt add $channel $target" 
	}
	if { [string tolower $action] == "del" } {
		set reason [join [lrange $text 3 end]]
		satmd_botnet_exempt_del $channel $target "[hand2nick $handle]![getchanhost [hand2nick $handle]]" $handle $reason 1
		putcmdlog "satmd_botnet:exempt del $target"
	}
	if { $action == "" } {
		putidx $idx "SYNTAX: exempt add <channel> <hostmask> <duration> <reason>"
		putidx $idx "        exempt del <channel> <hostmask> \[<reason>\]"
	}
	return 0
}


# main EXEMPT function
proc satmd_botnet_exempt_add { channel target duration mask handle reason forward } {
	global satmd_botnet
	if { $reason == "" || $duration == "" || $duration == "0" } { return 0 }
	if { ![regexp "^\[0-9\]*$" $duration] } { 
		set durlength [string range $duration 0 end-1]
		set durtype [string index $duration end]
		if { ![regexp "^\[0-9\]*$" $durlength] } {
			return 0
		} else {
			catch { 
				switch $durtype {
					d { set duration [expr 1440 * $durlength] }
					h { set duration [expr 60 * $durlength] }
					m { set duration $durlength }
					s { set duration 1}
				}
			}
		}
	}
	if { ($duration != "-1") && ($duration >= 0) } {
		if { ![isexempt $target]}  {
			newchanexempt $channel $target $handle "$reason -- exempt" $duration
			putcmdlog "satmd_botnet:exempt add $channel $target \[$reason\] by $mask ($handle) (duration:$duration)"
		}
		if { $forward == 1 } {
			putallbots "exempt add $channel $target $duration $mask $handle $reason"
		}
	}
	catch { exemptlist_add $target $reason $handle}
	return 1
}

# main UNEXEMPT function
proc satmd_botnet_exempt_del { channel target mask handle reason forward } {
#	putlog "DEBUG del $target $mask $handle $reason $forward"
	global satmd_botnet
	if { [botisop $channel] || [botishalfop $channel] } {
		catch { pushmode "$channel" "-e" "$target" }
	}
	if { $forward == 1 } {
		putallbots "exempt del $channel $target $mask $handle $reason"
	}
	killchanexempt $channel $target
	catch { exemptlist_del $target }
	putcmdlog "satmd_botnet:exempt del $channel $target by $mask ($handle)"
	return 1
}

# Successful
set satmd_botnet(version,exempt) "0.2.1"
return 1
