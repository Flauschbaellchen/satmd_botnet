# MODULE antimasshilight
#
# This module will kick a user for hilighting more nicks in a channel
# than defined at satmd_botnet_antimasshilight_limit
#

setudef int "satmd_botnet_antimasshilight_limit"

bind pubm -|- "*" satmd_botnet_antimasshilight_pubm

proc satmd_botnet_antimasshilight_pubm { nick uhost handle channel text } {
	if { [isop $nick $channel] || [ishalfop $nick $channel] || [isvoice $nick $channel] || [matchattr $handle "mnofl|mnofl" $channel ]} { return 0 }
	if { [channel get $channel "satmd_botnet_antimasshilight_limit"] < 1 } {
		return 0
	}
	set hits 0
	set hitlist ""
	foreach user [chanlist $channel] {
		set user_safe [matchsafe $user]
		if { [regexp -- "\[@!*%+~&,: \]${user_safe}\[ ,:\]" " $text"] } {
			lappend hitlist $user
			incr hits
		} else {
			putloglev "d" "$channel" "antimasshilight.tcl: no match on $user -> $text"
		}
	}
	if { $hits >= [channel get $channel "satmd_botnet_antimasshilight_limit"] } {
		putloglev "k" "$channel" "antimasshilight.tcl: $nick matched $hits nicks, kicked"
		putkick $channel $nick "Mass hilighting not permitted in this channel"
	}
	return 0
}

set satmd_botnet(version,antimasshilight) "0.2.2"

return 1
