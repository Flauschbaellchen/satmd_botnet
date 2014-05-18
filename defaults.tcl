# settings.tcl

## GLOBAL ##
#
# command character
#
set satmd_botnet(cmdchar) "!"
#
# Default bantime for gban (in seconds, default is 14 days)
set satmd_botnet(defaultbantime) [expr 14 * 24 * 60]
#
# Modules to load (list)
set satmd_botnet(modules) "maxpatch banhelper ctcphelper update"
#
set satmd_botnet(flag) "Nb"

## MODULE UPDATE ##
#
# update command
set satmd_botnet(update,command) "git pull --rebase"

## db_access
#
#
set satmd_botnet(db,database) ""
set satmd_botnet(db,host) ""
set satmd_botnet(db,user) ""
set satmd_botnet(db,password) ""

## gbanlist_update
#
# Where to send +b matches (botnick or empty)
set satmd_botnet(gbanlist_updater,target) "chii-chan"

## deadsocket
#
# How long to ban
set satmd_botnet(deadsocket,banduration) 300

## report
#
# What is the default target?
set satmd_botnet(report,target) "antispam:#antispam"

## floodreact
#
set satmd_botnet(floodreact,trigger_request) "$satmd_botnet(cmdchar)flood"
set satmd_botnet(floodreact,trigger_secured) "$satmd_botnet(cmdchar)secured"

## gban
#
# ban will be denied (unless forced) if it matches more than X promille
set satmd_botnet(gban,safe_threshold,local) 8
set satmd_botnet(gban,safe_threshold,global) 20

## balance
#
#
set satmd_botnet(balance,timeout) "5"
set satmd_botnet(balance,bans,prefix) "gban"
set satmd_botnet(balance,exempts,prefix) "gexempt"
## MODULE antispam
#
set satmd_botnet(importlist,files,gban_whitelist) "scripts/satmd_botnet/gban_whitelist.txt"
set satmd_botnet(importlist,files,gban_blacklist) "scripts/satmd_botnet/gban_blacklist.txt"

## MODULE watch
set satmd_botnet(watch,nicks) ""

## MODULE servicewatch
#
set satmd_botnet(servicewatch,nick) "NickServ"

## MODULE nickserv
#
set satmd_botnet(nickserv,nickserv) "*"


## MODULE logging
#
set satmd_botnet(logging) { 
	log {
		source proctree "*::satmd_botnet_report" "*::satmd_botnet_report::*";
		destination loglevel 8 *;
		destination broadcast;
	}
}

# Successful
set satmd_botnet(version,settings) "0.1"
return 1
