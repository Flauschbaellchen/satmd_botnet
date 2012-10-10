# MODULE netsplit
#
# Leave channels for a short time when a netsplit occurs.
#

# Make sure to prefix flags/procs/udefs/binds with satmd_botnet_ !
# listen is NOT handled yet!

bind sign -|- "% *" satmd_botnet_netsplit_detect_sign

proc satmd_botnet_netsplit_detect_sign { nick uhost handle channel text } {
	if { [regexp {^[^: ]*\.([^ .]*\.[^. ]*) [^: ]*\.\1$} $text] } {
		satmd_botnet_netsplit_react
	}
}

proc satmd_botnet_netsplit_react {} {
	global satmd_botnet
	if { ![info exists satmd_botnet(netsplit,running)] } {
		after 10000 [list satmd_botnet_netsplit_callback]
		set satmd_botnet(netsplit,running) 1
		foreach c [channels] {
			if { ![channel get $c inactive] } {
				if { [string match "%l% *" [getchanmode $c]] } {
					pushmode $c "-l"
					flushmode $c
				}
				channel set $c +inactive
				lappend satmd_botnet(netsplit,channels) $c
			}
		}
	}
}

proc satmd_botnet_netsplit_callback {} {
	global satmd_botnet
	if { [info exists satmd_botnet(netsplit,running)] } {
		foreach c $satmd_botnet(netsplit,channels) {
			channel set $c -inactive
		}
		unset satmd_botnet(netsplit,running)
		unset satmd_botnet(netsplit,channels)
	} else {
		putloglev "d" "*" "WARNING: This should never happen. You reached satmd_botnet_netsplit_callback without a reason"
	}

}

set satmd_botnet(version,netsplit) "0.1"

return 1
