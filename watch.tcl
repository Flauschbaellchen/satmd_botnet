# MODULE watch

# satmd_botnet_require hooks

#DO NOT CHANGE!
set satmd_botnet(watch,init) 1 
#DO NOT CHANGE!

bind raw - 601 satmd_botnet_watch_offline
bind raw - 605 satmd_botnet_watch_offline
bind raw - 604 satmd_botnet_watch_online
bind raw - 600 satmd_botnet_watch_online

bind evnt - init-server satmd_botnet_watch_init
proc satmd_botnet_watch_init { type } {
	global satmd_botnet
	foreach nick [split $satmd_botnet(watch,nicks)] {
		satmd_botnet_watch_add $nick
	}
	satmd_botnet_hooks_call watch_init
	set satmd_botnet(watch,init) 1
}

proc satmd_botnet_watch_add { nick } {
	putserv "WATCH +$nick"
}

proc satmd_botnet_watch_del { nick } {
	putserv "WATCH -$nick"
}

proc satmd_botnet_watch_offline {from keyword text } {
	set nick [lindex [split $text] 1]
	putloglev d "*" "DEBUG::watch::offline -> $nick"
	satmd_botnet_hooks_call watch_offline
	set satmd_botnet(watch,init) 0
}
proc satmd_botnet_watch_online { from keyword text } {
	set nick [lindex [split $text] 1]
	putloglev d "*" "DEBUG::watch::online -> $nick"
	satmd_botnet_hooks_call watch_online
	set satmd_botnet(watch,init) 0
}

satmd_botnet_watch_init "*"

set satmd_botnet(version,watch) "0.1"
return 1
