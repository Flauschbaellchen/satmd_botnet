#
# MODULE autoinactive
#
# Set a channel automatically to +inactive if beeing kicked out and channelflag +satmd_botnet_autoinactive is set.
# If satmd_botnet(autoinactive,delay) is set in the settings the bot will rejoin after this period of time (in minutes)
#

setudef flag satmd_botnet_autoinactive
bind kick - "*" satmd_botnet_autoinactive
proc satmd_botnet_autoinactive {nick uhost hand chan victim reason} {
	global satmd_botnet
	if {[channel get $chan "satmd_botnet_autoinactive"] && [isbotnick $victim]} {
		putloglev d $chan "botnet.tcl:satmd_botnet:autoinactive $nick!$uhost on $chan reason: $reason"
		catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:autoinactive $nick!$uhost on $chan reason: $reason" }
		channel set $chan +inactive
		if { [info exists satmd_botnet(autoinactive,delay)] } {
			after [expr $satmd_botnet(autoinactive,delay) * 60000] [list { channel set $chan -inactive ; putserv "JOIN $chan" }]
		}
	}
	return 0
}

# Sucessful
set satmd_botnet(version,autoinactive) "0.1"
return 1
