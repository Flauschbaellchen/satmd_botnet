# MODULE limiter
#
# Provide an API for limiting invokations of commands
#
# a) set satmd_botnet(limiter,name,NAMEOFCHOICE) "INVOCATIONS:INTERVAL"
# b) include catch { if { [satmd_botnet_limiter_check "NAMEOFCHOICE"] } { return 0}}
#    in the proc you want to limit
#

satmd_botnet_require hooks

proc satmd_botnet_limiter_check { id } {
	global satmd_botnet
	set limit_data ""
	set id_list [split $id ,]
	for { set pos [llength $id_list] ; incr pos -1  } { $pos > -1 } { incr pos -1 } {
		set id_local [join [lrange $id_list 0 $pos] ,]
		if {[info exists satmd_botnet(limiter,name,$id_local)]} {
			putloglev d "*" "limiter.tcl: using $id -> $id_local"
			set limit_data [split $satmd_botnet(limiter,name,$id_local) :]
			break
		}
	}
	if { $limit_data == "" } { return 0}
	set limit_maxvalue [lindex $limit_data 0]
	set limit_interval [lindex $limit_data 1]
	set limit_locktime [lindex $limit_data 2]
	if { $limit_locktime == "" } { set limit_locktime 60 }
	if { [info exists satmd_botnet(limiter,counters,$id)] == 1 } {
		set limit_hits $satmd_botnet(limiter,counters,$id)
	} else {
		set limit_hits 0
	}
	if { [info exists satmd_botnet(limiter,locked,$id)] } {
		return 1
	} elseif { $limit_hits >= $limit_maxvalue } {
		putloglev "d" "*" "limiter.tcl: hit limit for $id"
		satmd_botnet_hooks_call limiter_flud
		set satmd_botnet(limiter,locked,$id) [after [expr $limit_locktime * 1000] [list satmd_botnet_limiter_unlock $id]]
		return 1
	} else {
		putloglev "d" "*" "limiter.tcl: incrementing limit $id to [expr $limit_hits +1]"
		set satmd_botnet(limiter,counters,$id) [expr $limit_hits + 1]
		after [expr $limit_interval * 1000 ] [list satmd_botnet_limiter_decrease $id]
		return 0
	}
}

proc satmd_botnet_limiter_decrease { id } {
	global satmd_botnet
	if { ![info exist satmd_botnet(limiter,counters,$id)] } { return 0 }
	if { $satmd_botnet(limiter,counters,$id) > 0 } {
		set satmd_botnet(limiter,counters,$id) [expr $satmd_botnet(limiter,counters,$id) - 1]
	} else {
		unset satmd_botnet(limiter,counters,$id)
	}
}

proc satmd_botnet_limiter_unlock { id } {
	global satmd_botnet
	if { [info exist satmd_botnet(limiter,locked,$id) ] } {
		unset satmd_botnet(limiter,locked,$id)
	}
}

set satmd_botnet(version,limiter) "0.1.1"

return 1
