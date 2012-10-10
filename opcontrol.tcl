# MODULE opcontrol
#
# This module provides public channel commands like ... see this binds below ;)
#

bind pub -|- "$satmd_botnet(cmdchar)op"         satmd_botnet_opcontrol_op_pub
bind pub -|- "$satmd_botnet(cmdchar)deop"       satmd_botnet_opcontrol_deop_pub
bind pub -|- "$satmd_botnet(cmdchar)halfop"     satmd_botnet_opcontrol_halfop_pub
bind pub -|- "$satmd_botnet(cmdchar)dehalfop"   satmd_botnet_opcontrol_dehalfop_pub
bind pub -|- "$satmd_botnet(cmdchar)voice"      satmd_botnet_opcontrol_voice_pub
bind pub -|- "$satmd_botnet(cmdchar)devoice"    satmd_botnet_opcontrol_devoice_pub
bind pub -|- "$satmd_botnet(cmdchar)kick"       satmd_botnet_opcontrol_kick_pub
bind pub -|- "$satmd_botnet(cmdchar)ban"        satmd_botnet_opcontrol_ban_pub
bind pub -|- "$satmd_botnet(cmdchar)unban"      satmd_botnet_opcontrol_unban_pub
#DO NOT UNCOMMENT THE LINE BELOW. RISK OF ABUSE/FLOODING!
#bind pub -|- "$satmd_botnet(cmdchar)bans"       satmd_botnet_opcontrol_bans_pub
bind pub -|- "$satmd_botnet(cmdchar)log"        satmd_botnet_opcontrol_log_pub
bind pub -|- "$satmd_botnet(cmdchar)mode"       satmd_botnet_opcontrol_mode_pub

setudef flag "satmd_botnet_opcontrol"


proc satmd_botnet_opcontrol_mode_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [matchattr [nick2hand $nick] o|o $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1 } {
		set tmode [join [lindex $text 0]]
		set ttext [join [lrange $text 1 end]]
		putloglev "k"  "$channel" "$satmd_botnet(cmdchar)mode $tmode $ttext by $nick on $channel"
		pushmode "$channel" "$tmode" "$ttext"
	}
	return 1
}

proc satmd_botnet_opcontrol_op_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [matchattr [nick2hand $nick] o|o $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1} {
		set target [lindex $text 0]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { $target != "" } {
			pushmode "$channel" "+o" "$target"
			putloglev "k" "$channel" "opcontrol.tcl: !op $target on $channel by $nick"
		}
	}
	return 1
}

proc satmd_botnet_opcontrol_deop_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [matchattr [nick2hand $nick] o|o $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1} {
		set target [lindex $text 0]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { $target != "" } {
			pushmode "$channel" "-o" "$target"
			putloglev "k" "$channel" "opcontrol.tcl: !deop $target on $channel by $nick"
		}
	}
	return 1
}

proc satmd_botnet_opcontrol_halfop_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1} {
		set target [lindex $text 0]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { $target != "" } {
			pushmode "$channel" "+h" "$target"
			putloglev "k" "$channel" "opcontrol.tcl: !halfop $target on $channel by $nick"
		}
	}
	return 1
}

proc satmd_botnet_opcontrol_dehalfop_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [matchattr [nick2hand $nick] o|o $channel]  ) && [channel get $channel "satmd_botnet_opcontrol"] == 1} {
		set target [lindex $text 0]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { $target != "" } {
			pushmode "$channel" "-h" "$target"
			putloglev "k" "$channel" "opcontrol.tcl: !dehalfop $target on $channel by $nick"
		}
	}
	return 1
}

proc satmd_botnet_opcontrol_voice_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1} {
		set target [lindex $text 0]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { $target != "" } {
			pushmode "$channel" "+v" "$target"
			putloglev "k" "$channel" "opcontrol.tcl: !voice $target on $channel by $nick"
		}
	}
	return 1
}

proc satmd_botnet_opcontrol_devoice_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1 } {
		set target [lindex $text 0]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { $target != "" } {
			pushmode "$channel" "-v" "$target"
			putloglev "k" "$channel" "opcontrol.tcl: !devoice $target on $channel by $nick"
		}
	}
	return 1
}

proc satmd_botnet_opcontrol_kick_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1 } {
		set target [lindex $text 0]
		set reason [join [lrange $text 1 end]]
		if { $target == "" } {
			set target $nick
		}
		if { ! [onchan $target $channel ] } {
			set target ""
		}
		if { [isop $nick $channel] == 0 && [isop $target $channel] == 1 } {
			set target ""
		}
		if { [isop $nick $channel] == 0 && [ishalfop $target $channel] == 1 } {
			set target ""
		}
		if { $target != "" } {
			putkick $channel $target "$satmd_botnet(cmdchar)kick: <$nick> $reason"
			putloglev "k" "$channel" "opcontrol.tcl: !kick $target $reason on $channel by $nick"
		}
	}
	return 1
}


proc satmd_botnet_opcontrol_ban_pub { nick uhost handle channel text } {
	global botnick
	if { ( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel]  ) && [channel get $channel "satmd_botnet_opcontrol"] == 1 } {
		set text [split $text]
		set duration [satmd_botnet_timespec2mins [lindex $text 1]]
		set target [lindex $text 0]
		set reason [join [lrange $text 2 end]]

		if { ![regexp "^\[0-9\]+" [lindex $text 1]] } {
			set reason [join [lrange $text 1 end]]
			set duration 0
		}
		if { $reason == "" } { set reason "Unwanted" }
		

		if { ($duration != "-1") && ($duration >= 0) && $target != ""} {
			if { [onchan $target] } {
				set target [satmd_botnet_genericbanmask $target [getchanhost $target]]
			} elseif { ([string match -nocase "&R:*" $target] && ![satmd_botnet_checkregexp $target]) } {
				putnotc $nick "opcontrol: ban denied. (broken regexp)"
				return 0
			}

			if { ![isban $target $channel]}  {
				newchanban $channel $target "$nick/$handle" "$nick: $reason" $duration
				if { ![string match -nocase "&R:*" $target] } {
					pushmode $channel +b $target
				}
				putnotc $nick "(Local Ban) Banmask:($target) Reason:($reason) Duration:($duration) added."
				putloglev "k" "$channel" "opcontrol.tcl: !ban $target $reason on $channel by $nick/$handle"
			} else {
				putnotc $nick "(Local Ban) Banmask:($target) already exists. Nothing added."
			}

		} else {
			putnotc $nick "Syntax: !ban <mask/nick> \[lifetime\] \[reason\]"
		}
		
	}
	return 1
}

# Handle public UNBAN
proc satmd_botnet_opcontrol_unban_pub { nick uhost handle channel text } {
	global botnick
	if { ( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel]  ) && [channel get $channel "satmd_botnet_opcontrol"] == 1 } {
		set text [split $text]
		set target [lindex $text 0]

		if { [killchanban $channel $target] } {
			putnotc $nick "(Local Ban) Banmask:($target) removed"
			putloglev "k" "$channel" "opcontrol.tcl: !unban $target on $channel by $nick/$handle"
		} else {
			putnotc $nick "(Local Ban) Banmask:($target) not exists. Nothing removed."
		}

		# if a "ghost" is still there, do it always:
		pushmode "$channel" "-b" "$target"
	}
	return 1
}


proc satmd_botnet_opcontrol_bans_pub { nick uhost handle channel text } {
	global satmd_botnet
	set text [split $text]
	if { ( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr [nick2hand $nick] ol|ol $channel] ) && [channel get $channel "satmd_botnet_opcontrol"] == 1 } {
		set chanbans "[banlist $channel]"
		set chanbans_count "[llength $chanbans]"
		set chanbans_index 0
		while { [lindex $chanbans $chanbans_index] != "" } {
			set chanbans_this [lindex $chanbans $chanbans_index]
			set chanbans_this_mask [join [lindex $chanbans_this 0]]
			set chanbans_this_comment [join [lindex $chanbans_this 1]]
			set chanbans_this_creator [join [lindex $chanbans_this 5]]
			putnotc $nick "banlist: $chanbans_this_mask by $chanbans_this_creator \[Reason: $chanbans_this_comment\]"
			incr chanbans_index
		}
		putloglev "k" "$channel" "opcontrol.tcl: !bans on $channel by $nick"
	}
	return 1
}

#Successfull
set satmd_botnet(version,opcontrol) "0.2.1"
return 1
