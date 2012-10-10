# MODULE securebotlinks
#
# if the module is loaded any bot which will try to connect to the botnet need to be in the bots userlist - if not it will get a +r (reject) flag and will be booted out.
#

bind dcc n|n "satmd_botnet_botlinks" satmd_botnet_securebotlinks

proc satmd_botnet_securebotlinks { handle idx text } {
	foreach bot [botlist] {
		set botname [lindex $bot 0]
		if { ![validuser $botname] } {
			if { ![matchattr $botname b] } {
				set botuplink [lindex $bot 1]
				set botversion [lindex $bot 2]
				set botshare [lindex $bot 3]
				if { [islinked $botuplink] } {
					dccbroadcast "\002WARNING:\002 Unauthorized bot $botname is linked to $botuplink, rejecting uplink $botuplink"
				}
				botattr $botuplink +r
				unlink $botuplink
			}
		}
	}
	return 0
}

bind link - * satmd_botnet_securebotlinks_link
proc satmd_botnet_securebotlinks_link { botname via	} {
	if { ![validuser $botname] } {
		if { ![matchattr $botname b] } {
			if { ![matchattr $via f] } {
				dccbroadcast "\002WARNING:\002 Unauthorized bot $botname is linked to $via, rejecting uplink $via"
				botattr $via "-h+r"
				unlink $via
			}
		}
	}
}

set satmd_botnet(securebotlinks,version) "0.1"

return 1


