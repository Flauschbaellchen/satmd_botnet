# MODULE noxdcccatcher
#
# Scan for common xdcc-chatcher and gban them
#
# Note: VERSION scanning deactivated due to ctcp flooding.
#
satmd_botnet_require ctcphelper
satmd_botnet_require gban

bind join -|- "*" satmd_botnet_noxdcccatcher_join
bind ctcr -|- "LAG" satmd_botnet_noxdcccatcher_ctcr_lag
bind ctcr -|- "ERROR" satmd_botnet_noxdcccatcher_ctcr_error
# bind ctcr -|- "VERSION" satmd_botnet_noxdcccatcher_ctcr_version
setudef flag satmd_botnet_noxdcccatcher

proc satmd_botnet_noxdcccatcher_join { nick uhost handle channel } {
	after 4000 [list satmd_botnet_noxdcccatcher_join_2 $nick $uhost $handle $channel]
	return 1
}
proc satmd_botnet_noxdcccatcher_join_2 { nick uhost handle channel } {
	if { ![channel get $channel "satmd_botnet_noxdcccatcher"] } { return 0}
	if { ([nick2hand $nick] != "*") || [isop $nick $channel] || [isvoice $nick $channel] || [ishalfop $nick $channel] } { return 0}
	putctcp $nick "LAG"
#  putctcp $nick "VERSION"
	putctcp $nick "ERROR"	
	return 1
}

proc satmd_botnet_noxdcccatcher_ctcr_lag { nick uhost handle dest keyword text } {
	global botnick
	if { $text == "" || $text == " " } {
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		satmd_botnet_gban_add "$banmask" "15d" "noxdcccatcher@$botnick" "$botnick" "xdcc catcher not allowed" 1 
		return 1
	} else {
		return 0
	}
}
proc satmd_botnet_noxdcccatcher_ctcr_error { nick uhost handle dest keyword text } {
	global botnick
	if { $text == "" || $text == " " } {
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		satmd_botnet_gban_add "$banmask" "15d" "noxdcccatcher@$botnick" "$botnick" "xdcc catcher not allowed" 1
		return 1
	} else {
		return 0
	}
}


proc satmd_botnet_noxdcccatcher_ctcr_version { nick uhost handle dest keyword text } {
	global botnick
	if { [string match "XDCC Catcher Basic*" $text] } {
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		satmd_botnet_gban_add "$banmask" "15d" "noxdcccatcher@$botnick" "$botnick" "xdcc catcher not allowed" 1
		return 1
	} else {
		return 0
	}
}

#Successfull
set satmd_botnet(version,noxdcccatcher) "0.3.1"
return 1
