# MODULE finduser
#
# finds users by nick
# This module is currently not using any botnet enhancements, just checking its local userlist
#

bind dcc lmno|lmno "finduser" satmd_botnet_finduser_dcc

proc satmd_botnet_finduser_dcc {hand idx text} {
#	set text [string trim [split $text]]
	if { $text == "" } {
		putidx $idx "satmd_botnet:finduser SYNTAX: finduser <nick>"
		return 1
	}
	set chanlist ""
	foreach c [channels] {
		if { ( [botonchan $c] ) && ( [onchan $text $c] == 1 ) } {
			if { $chanlist != "" } {
				set chanlist "$chanlist, $c"
			} else {
				set chanlist $c
			}
		}
	}
	if { $chanlist == "" } {
		putidx $idx "satmd_botnet:finduser $text not found"
	} else {
		putidx $idx "satmd_botnet:finduser found $text on $chanlist"
	}
	return 1
}

# Successful
set satmd_botnet(version,finduser) "0.1"
return 1