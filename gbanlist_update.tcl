# MODULE gbanlist_update
#
# This will send a copy of each matched ban to a defined bot
# That bot will then replay it via SQL.
#

if { [isbotnick $satmd_botnet(gbanlist_updater,target)] } {
	package require Tcl 8.4
}

bind mode - "% +b" satmd_botnet_gban_mode

proc satmd_botnet_gban_mode { nick uhost handle channel mchange victim } {
	global satmd_botnet botnick
	set banmask "$victim"
	if { [isbotnick $satmd_botnet(gbanlist_updater,target)] } {
		satmd_botnet_gban_update $botnick satmd_botnet_gban_update $banmask
	} else {
		putbot $satmd_botnet(gbanlist_updater,target) "satmd_botnet_gban_update $banmask"
	}
}

# Success
set satmd_botnet(version,gbanlist_update) "0.3"
return 1
