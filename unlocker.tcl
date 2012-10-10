# MODULE unlocker
#
# Same as !resetantimanynicks in antimanynicks.tcl but also deletes the gban which were added
#


bind pubm -|- "% !unlocker *" satmd_botnet_unlocker_pub

proc satmd_botnet_unlocker_pub { nick uhost handle channel text } {
	global satmd_botnet botnick
	set tnick [lindex [split $text !] 0]
	set tuhost [lindex [split $text !] 1]
	set tident [lindex [split $tuhost @] 0]
	set thost [lindex [split $tuhost @] 1]
	catch { 
		unset satmd_botnet(antimanynicks,nicks,$thost)
		unset satmd_botnet(antimanynicks,timer,$thost)
		putnotc $nick "antimanynicks: cleared"
	}
	catch {
		if { [satmd_botnet_gban_del "*!*@$thost" "unlocker@$botnick" "$handle" "fixage" 1 ] } {
			putnotc $nick "gban: cleared *!*@$thost"
		}
	}
}

set satmd_botnet(version,unlocker) "0.2"

# successful
return 1


