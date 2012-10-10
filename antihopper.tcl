# MODULE antihopper
#
# [GBAN] If someone is joining your channel and immediately leaving again, this indicates
# drone activity (gathering information). This module is not that effective actually because
# the drone has parted already, but it can inform regular users that happen to have the same ip/host
# of drone activity on their machine. Trojans?

satmd_botnet_require gban

setudef int "satmd_botnet_antihopper_delay"
catch { deludef int "antihopper-delay" }
bind join -|- "% *" satmd_botnet_antihopper_join
bind part -|- "% *" satmd_botnet_antihopper_part

proc satmd_botnet_antihopper_join { nick uhost handle channel } {
	global botnick satmd_botnet
	if { ([isbotnick $nick]) || ($handle != "*") } { return 0}
	set delay [channel get $channel "satmd_botnet_antihopper_delay"]
	if { $delay != 0 } {
		set satmd_botnet(antihopper,$channel,$nick) "[unixtime]"
		after [expr $delay * 2000 ] [list unset satmd_botnet(antihopper,$channel,$nick)]
	}
}

proc satmd_botnet_antihopper_part { nick uhost handle channel text} {
	global botnick satmd_botnet
	if { ([isbotnick $nick]) || ($handle != "*") } { return 0}
	set delay [channel get $channel "satmd_botnet_antihopper_delay"]
	if { $delay != 0 } {
		if { [info exists satmd_botnet(antihopper,$channel,$nick)] } {
			set stamp2 [unixtime]
			set stamp1 $satmd_botnet(antihopper,$channel,$nick)
			if { [expr $stamp2 - $stamp1] < $delay } {
				set banmask [satmd_botnet_genericbanmask $nick $uhost]
				satmd_botnet_gban_add $banmask "30m" "antihopper@$botnick" $botnick "channelhopper $nick on channel [string range $channel 1 end]" 1
			}
		}
	}
}

# Sucessful
set satmd_botnet(version,antihopper) "0.5"
return 1
