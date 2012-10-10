# MODULE servicewatch
#
# this module will keep an eye of the services (default: nickserv and chanserv)
# a) if services went down the bot will unmoderate the channel if moderated (+satmd_botnet_unmoderate_noservices)
# b) if services reboot or comes up after a netsplit the bot will leave the channel for a short period of time so it will "ignore" the upcoming guestnick flood (+satmd_botnet_guestnick_noflood)
#

satmd_botnet_require watch
satmd_botnet_require hooks

setudef flag satmd_botnet_unmoderate_noservices
setudef flag satmd_botnet_guestnick_noflood

satmd_botnet_hooks_register watch_init satmd_botnet_servicewatch_init
satmd_botnet_hooks_register watch_offline satmd_botnet_servicewatch_offline
satmd_botnet_hooks_register watch_online satmd_botnet_servicewatch_online

proc satmd_botnet_servicewatch_init { } {
	global satmd_botnet
	satmd_botnet_watch_add $satmd_botnet(servicewatch,nick)
}

proc satmd_botnet_servicewatch_offline { } {
	global satmd_botnet
	if { $satmd_botnet(watch,init) == 0 && $nick == $satmd_botnet(servicewatch,nick) } {
		putloglev "d" "*" "servicewatch: services went down"
		foreach channel [channels] {
			if { [channel get $channel "inactive"] == 0 } {  
				if { [channel get $channel "satmd_botnet_unmoderate_noservices"] } {
					pushmode $channel "-m"
				}
			}
		}
	}
}

proc satmd_botnet_servicewatch_online { } {
	global satmd_botnet
		if { $satmd_botnet(watch,init) == 0 && $nick == $satmd_botnet(servicewatch,nick) } {
		putloglev "d" "*" "servicewatch: services went up"
		set waittime 180000
		foreach channel [channels] {
			if { [channel get $channel "inactive"] == 0 } {
				if { [channel get $channel "satmd_botnet_guestnick_noflood"] } {
					channel set $channel "+inactive"
					after $waittime [list channel set $channel "-inactive"]
				}
			}
		}
	}
}

set satmd_botnet(version,servicewatch) "0.3"
return 1

