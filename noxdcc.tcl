# MODULE noxdcclist
# gban a user which send "xdcc list" via dcc/msg

satmd_botnet_require gban

bind msg -|- "xdcc" satmd_botnet_noxdcc_msg
bind ctcp -|- "xdcc" satmd_botnet_noxdcc_ctcp

proc satmd_botnet_noxdcc_msg { nick uhost handle text } {
	satmd_botnet_noxdcc_proc $nick $uhost $handle
}

proc satmd_botnet_noxdcc_ctcp { nick uhost handle target keyword text } {
	if { [string range $target 0 1] == "#" } { return 0 }
	satmd_botnet_noxdcc_proc $nick $uhost $handle
}

proc satmd_botnet_noxdcc_proc { nick uhost handle } {
	global botnick
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add $banmask "1d" "noxdcc@$botnick" $botnick "no xdcc list on $botnick" 1
	putmsg $nick "Das kitzelt! Lass das! :o"
}


#Successfull
set satmd_botnet(version,noxdcc) "0.2.2"
return 1
