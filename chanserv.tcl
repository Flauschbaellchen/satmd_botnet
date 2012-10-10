# MODULE chanserv
# 
# This module interacts with ChanServ

# define udefs
setudef flag "satmd_botnet_chanserv_invite"
setudef flag "satmd_botnet_chanserv_limit"
setudef flag "satmd_botnet_chanserv_halfop"
setudef flag "satmd_botnet_chanserv_op"
setudef flag "satmd_botnet_chanserv_unban"
setudef flag "satmd_botnet_chanserv_admin"
setudef flag "satmd_botnet_chanserv_protect"

# bind NEED
bind need - "*" satmd_botnet_chanserv_check
bind raw - 470 satmd_botnet_chanserv_raw470
bind raw - 473 satmd_botnet_chanserv_raw473

proc satmd_botnet_chanserv_raw470 { from keyword text } {
	set channel [lindex $text 1]
	satmd_botnet_chanserv_check $channel unban
}

proc satmd_botnet_chanserv_raw473 { from keyword text } {
	set channel [lindex $text 1]
	satmd_botnet_chanserv_check $channel invite
}

# Process NEED
proc satmd_botnet_chanserv_check { channel type } {
	global botnick
	if { ( [isbotnick $botnick] == 0 ) || ( [channel get $channel "inactive"] == 1 ) } { return 0 }
	if { ( [channel get $channel "satmd_botnet_chanserv_unban"] == 1 ) && ( $type == "unban" ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:UNBAN to $channel"
		putmsg "ChanServ" "UNBAN $channel"
	}
	if { ( [channel get $channel "satmd_botnet_chanserv_invite"] == 1 ) && ( $type == "invite" ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:INVITE to $channel"
		putmsg "ChanServ" "INVITE $channel"
	}
	if { ( [channel get $channel "satmd_botnet_chanserv_limit"] == 1 ) && ( $type == "limit" ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:INVITE to $channel"
		putmsg "ChanServ" "INVITE $channel"
	}
	if { ( [channel get $channel "satmd_botnet_chanserv_admin"] == 1 ) && ( $type == "op" ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:ADMIN on $channel"
		putmsg "ChanServ" "ADMIN $channel $botnick"
	}
	if { ( [channel get $channel "satmd_botnet_chanserv_protect"] == 1 ) && ( $type == "op" ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:PROTECT on $channel"
		putmsg "ChanServ" "PROTECT $channel $botnick"
	}
	if { ( [channel get $channel "satmd_botnet_chanserv_op"] == 1 ) && ( $type == "op" ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:OP on $channel"
		putmsg "ChanServ" "OP $channel $botnick"
		if {[channel get $channel "satmd_botnet_chanserv_admin"] == 1 } {
			putcmdlog "satmd_botnet:chanserv ChanServ:ADMIN on $channel"
			putmsg "ChanServ" "ADMIN $channel $botnick"
		}
		if { ( [channel get $channel "satmd_botnet_chanserv_protect"] == 1 ) && ( $type == "op" ) } {
			putcmdlog "satmd_botnet:chanserv ChanServ:PROTECT on $channel"
			putmsg "ChanServ" "PROTECT $channel $botnick"
		}
	}
	if { ( [channel get $channel "satmd_botnet_chanserv_halfop"] == 1 ) && ( $type == "op" ) && ( [botishalfop $channel] == 0 ) } {
		putcmdlog "satmd_botnet:chanserv ChanServ:HALFOP on $channel"
		putmsg "ChanServ" "HALFOP $channel $botnick"
	}
#	foreach c [channels] {
#		if { ([botonchan $c] == 0) && ([channel get $c "inactive"] == 0) } {
#			if { ( [channel get $c "satmd_botnet_chanserv_unban"] == 1 ) } {
#				putcmdlog "satmd_botnet:chanserv ChanServ:UNBAN on $channel (vhost?)"
#				putmsg "ChanServ" "UNBAN $c"
#			}
#			if { ( [channel get $c "satmd_botnet_chanserv_invite"] == 1 ) } {
#				putcmdlog "satmd_botnet:chanserv ChanServ:INVITE on $channel (vhost?)"
#				putmsg "ChanServ" "INVITE $c"
#			}
#		}
#	}
	return 1
}

# Successful
set satmd_botnet(version,chanserv) "0.3"
return 1
