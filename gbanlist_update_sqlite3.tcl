# MODULE gbanlist_update
#
# This will send a copy of each matched ban to a defined bot
# That bot will then replay it via SQL.
#

satmd_botnet_require sqlite3

if { [isbotnick $satmd_botnet(gbanlist_updater,target)] } {
	package require Tcl 8.4
}

bind bot - "satmd_botnet_gban_update" satmd_botnet_gban_update

proc satmd_botnet_gban_update { from keyword text } {
	global satmd_botnet
	if { ![matchattr $from $satmd_botnet(flag)] } { return 0 }
	set banmask [lindex $text 0]
	set now [unixtime]
	sqlite3-gban eval { UPDATE gban_seen SET seen=$now WHERE banmask=$banmask; }
	sqlite3-gban eval { UPDATE gban_seen SET bot=$from WHERE banmask=$banmask; }
}

catch { source $satmd_botnet(basepath)/gbanlist_update.tcl }

# Success
set satmd_botnet(version,gbanlist_update_sqlite3) "0.3.2"
return 1

