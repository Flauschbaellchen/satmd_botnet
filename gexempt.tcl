# MODULE gexempt
#
# This module provides a botnet-global exempt system WITHOUT sharing module
# Look at satmd_botnet_gexempt_gettime before using this module!
# Examples:
# !gexempt exemptmask duration reason
# !gunexempt exemptmask [reason]
# .gexempt add exemptmask duration reason
# .gexempt del exemptmask [reason]

# forked on 2007-08-01 from gban.tcl with version 0.7.4 -> 0.1

# bind GEXEMPT commands
bind pub nG|G  "$satmd_botnet(cmdchar)gexempt"                 satmd_botnet_gexempt_pub
bind pub -|-  "$satmd_botnet(cmdchar)gunexempt"                satmd_botnet_gunexempt_pub
bind bot -|-  "gexempt"                   satmd_botnet_gexempt_bot
bind dcc nG|G  "gexempt"                  satmd_botnet_gexempt_dcc
bind dcc nG|G  "+gexempt"				   satmd_botnet_gexempt_dcc_add
bind dcc nGmno|Gnmo  "-gexempt"           satmd_botnet_gexempt_dcc_del

# Create GEXEMPT udef
setudef flag "satmd_botnet_gexempt"
catch { deludef flag "gexempt" }

# Handle public GEXEMPT
proc satmd_botnet_gexempt_pub { nick uhost handle channel text } {
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
				putnotc $nick "gexempt: forcefully accepted."
			} else {
				putnotc $nick "gexempt: denied. invalid syntax (\"force\" is reserved)"
				return 0
			}
		} else { 
			set duration [lindex $text 1]
			set readon [join [lrange $text 2 end]]
		}
		
		if { [satmd_botnet_gexempt_add $target $duration "$nick!$uhost" $handle $reason 1] } {
			putnotc $nick "(Global Exempt) Exemptmask:($target) Reason:($reason) Lifetime:($duration) added"
		}
#	}
	return 0
}

# Handle public GUNEXEMPT
proc satmd_botnet_gunexempt_pub { nick uhost handle channel text } {
	global botnick
	set text [split $text]
	if { [matchattr $handle G|G $channel] || (( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle olGN|olG $channel] ) && [channel get $channel "satmd_botnet_gexempt"] == 1)} {
		set target [join [lindex $text 0]]
		set reason [join [lrange $text 1 end]]
		if { [satmd_botnet_gexempt_del $target "$nick!$uhost" "$handle" $reason 1] } {
			putnotc $nick "(Global Exempt) Exemptmask:($target) removed"
		}
	}
	return 0
}

# Handle remote (bot) GEXEMPT
proc satmd_botnet_gexempt_bot { frombot keyword text } {
#	if { [isbotnick $frombot]} { return 1}
	global botnick
	set text [split $text]
#	putlog "DEBUG $text"
	if { [matchattr $frombot "G"] } {
		set action [lindex $text 0]
		switch $action {
			add {
				set target  [lindex $text 1]
				set duration [lindex $text 2]
				set mask [lindex $text 3]
				set handle [lindex $text 4]
				set reason [join [lrange $text 5 end]]
				satmd_botnet_gexempt_add $target $duration "$mask@$frombot" $handle $reason 0
			}
			del {
				set target [join [lindex $text 1]]
				set mask [lindex $text 2]
				set handle [lindex $text 3]
				set reason [join [lrange $text 4 end]]
				satmd_botnet_gexempt_del $target "$mask@$frombot" $handle $reason 0
			}
		}
	}
	return 0
}

# Handle partyline GEXEMPT/GUNEXEMPT
proc satmd_botnet_gexempt_dcc_add { handle idx text} {
	satmd_botnet_gexempt_dcc $handle $idx "add $text"
}
proc satmd_botnet_gexempt_dcc_del { handle idx text} {
	satmd_botnet_gexempt_dcc $handle $idx "del $text"
}
proc satmd_botnet_gexempt_dcc {handle idx text} {
	global botnick
	set action [lindex $text 0]
	set target [lindex $text 1]
	if { [string tolower $action] == "add" } {
		if { [onchan $target] } {
			set target "*!*@[lindex [split [getchanhost $target] @] 1]"
		}
		if { [lindex $text 2] == "force" } {
			if { [matchattr $handle "nG|-"] } {
				set duration [lindex $text 3]
				set reason [join [lrange $text 4 end]]
				putidx $idx "gexempt: forcefully accepted."
			} else {
				putidx $idx "gexempt: denied. invalid syntax (\"force\" is reserved )"
				return 0
			}
		} else {
			set duration [lindex $text 2]
			set reason [join [lrange $text 3 end]]
		}
		satmd_botnet_gexempt_add $target $duration "[hand2nick $handle]![getchanhost [hand2nick $handle]]" $handle $reason 1
		putcmdlog "satmd_botnet:gexempt add $target" 
	}
	if { [string tolower $action] == "del" } {
		set reason [join [lrange $text 2 end]]
		satmd_botnet_gexempt_del $target "[hand2nick $handle]![getchanhost [hand2nick $handle]]" $handle $reason 1
		putcmdlog "satmd_botnet:gexempt del $target"
	}
	if { $action == "" } {
		putidx $idx "SYNTAX: gexempt add <hostmask> <duration> <reason>"
		putidx $idx "        gexempt del <hostmask> \[<reason>\]"
	}
	return 0
}


# main GEXEMPT function
proc satmd_botnet_gexempt_add { target duration mask handle reason forward } {
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
			newexempt $target $handle "$reason -- gexempt" $duration
			putcmdlog "satmd_botnet:gexempt add $target \[$reason\] by $mask ($handle) (duration:$duration)"
		}
		if { $forward == 1 } {
			putallbots "gexempt add $target $duration $mask $handle $reason"
		}
	}
	catch { gexemptlist_add $target $reason $handle}
	return 1
}

# main GUNEXEMPT function
proc satmd_botnet_gexempt_del { target mask handle reason forward } {
#	putlog "DEBUG del $target $mask $handle $reason $forward"
	global satmd_botnet
	foreach c [channels] {
		if { [botisop $c] || [botishalfop $c] } {
			catch { pushmode "$c" "-e" "$target" }
		}
	}
	if { $forward == 1 } {
		putallbots "gexempt del $target $mask $handle $reason"
	}
	killexempt $target
	catch { gexemptlist_del $target }
	putcmdlog "satmd_botnet:gexempt del $target by $mask ($handle)"
	return 1
}

# Successful
set satmd_botnet(version,gexempt) "0.2.1"
return 1
