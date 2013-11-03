# floodreact

satmd_botnet_require report

setudef flag "satmd_botnet_floodreact"

bind pub -|- "$satmd_botnet(floodreact,trigger_request)" satmd_botnet_floodreact_request
bind pub mno|mno "$satmd_botnet(floodreact,trigger_secured)" satmd_botnet_floodreact_secured

proc satmd_botnet_floodreact_request { nick uhost handle channel text } {
	if { $text != "" } { return 0 } 
	global satmd_botnet
	if { ![channel get $channel "satmd_botnet_floodreact"] } { return 0}
	if { ![info exists satmd_botnet(floodreact,active,$channel)] } {
		set satmd_botnet(floodreact,active,$channel) 1
		after 600000 [list unset satmd_botnet(floodreact,active,$channel)]
		set usermask "$nick!$uhost/$handle"
		putnotc $nick "Der Request wurde angenommen. Der Botmaster wurde informiert."
		#putnotc $channel "Der Channel wurde als \002FLOODED\002 markiert. Restriktionen werden aktiviert."
	set reporttext "satmd_botnet:flood: Flood in $channel wurde von $usermask ("
	if { [matchattr $handle "mno|mno" $channel ] } {
		set reporttext "${reporttext}~"
	}
	if { [isop $nick $channel] } {
		set reporttext "${reporttext}@"
	} elseif { [ishalfop $nick $channel] } {
		set reporttext "${reporttext}%"
	} elseif { [isvoice $nick $channel]} {
		set reporttext "${reporttext}+"
	}

	set reporttext "${reporttext}) gemeldet."
	satmd_botnet_report $satmd_botnet(report,target) "$reporttext"
	satmd_botnet_floodreact_activate "$channel"
	} else {
		putnotc $nick "Ein Request liegt bereits vor. Anforderung abelehnt."
	}
}

proc satmd_botnet_floodreact_secured { nick uhost handle channel text } {
	if { $text != "" } { return 0 }
	global satmd_botnet
	if { ![channel get $channel "satmd_botnet_floodreact"] } { return 0} 
	if { (![matchattr $handle "mnoly|mnolyF" $channel]) && (![isop $nick $channel])} { return 0}
	putnotc $nick "Der Channel wurde in den Zustand SECURED versetzt. Normale Aktivitaet."
	#putnotc $channel "Der Channel wurde als \002SECURED\002 markiert. Restriktionen werden aufgehoben."
	set usermask "$nick/$handle"
	satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:flood: Die Flood-Meldung fuer $channel wurde von $usermask geloescht."
	satmd_botnet_floodreact_deactivate "$channel"
	if { [info exists satmd_botnet(floodreact,active,$channel)] } {
		unset satmd_botnet(floodreact,active,$channel)
	}
}

proc satmd_botnet_floodreact_activate { channel } {
	catch { channel set $channel +slennox-sentinel }
	catch { channel set $channel +slennox-repeat }
	catch { channel set $channel +nopubseens }
	catch { channel set $channel +opcontrol }
	catch { channel set $channel "flood-join 5:60" }
	catch { channel set $channel "flood-ctcp 3:60" }
	catch { channel set $channel "flood-nick 5:90" }
	catch { channel set $channel "flood-deop 3:60" }
	catch { channel set $channel "flood-kick 4:10" }
	#catch { channel set $channel "+noclones" }
	catch { channel set $channel "+chanserv-unban" }
	catch { pushmode "$channel" "+C" }
	catch { pushmode "$channel" "+S" }
	catch { mkdir "floodreact" }
	logfile jkpscw $channel "floodreact/$channel.log"
	catch { putloglev "d" "*" "floodreact:activate" }
}

proc satmd_botnet_floodreact_deactivate { channel } {
	catch { pushmode $channel "-R" }
	catch { logfile "" $channel "floodreact/$channel.log" }
	putloglev "d" "*" "floodreact:deactivate"	
}

# Sucessful
set satmd_botnet(version,floodreact) "0.4"
return 1
