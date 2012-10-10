# MODULE gbanlist_update
#
# This will send a copy of each matched ban to a defined bot
# That bot will then replay it via SQL.
#

satmd_botnet_require gban

if { [isbotnick $satmd_botnet(gbanlist_updater,target)] } {
	package require Tcl 8.4
	package require mysqltcl
}

bind bot - "satmd_botnet_gban_update" satmd_botnet_gban_update

proc satmd_botnet_gban_update { from keyword text } {
	global satmd_botnet
	if { ![matchattr $from $satmd_botnet(flag)] } { return 0 }
	set banmask [lindex $text 0]
	set db_handle [mysqlconnect -db $satmd_botnet(db,database) -host $satmd_botnet(db,host) -user $satmd_botnet(db,user) -password $satmd_botnet(db,password)]
	set sql "UPDATE gban_seen SET seen=NOW() WHERE banmask='[mysqlescape $banmask]';"
	catch { mysqlquery $db_handle $sql }
	set sql "UPDATE gban_seen SET bot='[mysqlescape $from]' WHERE banmask='[mysqlescape $banmask]';"
	catch { mysqlquery $db_handle $sql }
	mysqlclose $db_handle
}

catch { source $satmd_botnet(basepath)/gbanlist_update.tcl }

# Success
set satmd_botnet(version,gbanlist_update_mysql) "0.3"
return 1

