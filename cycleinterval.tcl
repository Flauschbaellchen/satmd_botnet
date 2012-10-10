# MODULE cycleinterval
#
# This will make the bot rejoin a channel by a set interval
#

setudef int "satmd_botnet_cycleinterval"

bind time - "* * * * *" satmd_botnet_cycleinterval_timer

proc satmd_botnet_cycleinterval_timer { aTIM bTIM cTIM dTIM eTIM } {
	foreach c [channels] {
		if { ![channel get $c inactive] } {
			set found 0
			foreach a [after info] {
				set afterline  [join [lindex [after info $a] 0]]
				set afterproc  [lindex $afterline 0]
				set afterparm0 [lindex $afterline 1]
				if { ($afterproc == "satmd_botnet_cycleinterval_rejoin") && ($afterparm0 == "$c") } {
					set found $a
				}
			}
			set needed [channel get $c "satmd_botnet_cycleinterval"]
			if { ($needed > 0) && ($found == 0) } { 
				after [expr [expr [channel get $c "satmd_botnet_cycleinterval"] -1 ] * 60000] [list satmd_botnet_cycleinterval_rejoin $c]
			} elseif { ($needed <= 0 ) && ($found != 0) } {
				after cancel $found
			}
		}
	}
}

proc satmd_botnet_cycleinterval_rejoin { channel } {
	putserv "PART $channel rejoining!"
	putserv "JOIN $channel"
	return 1
}

# Sucessful
set satmd_botnet(version,cycleinterval) "0.2.3"
return 1
