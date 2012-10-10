# MODULE antirejoin
#
# [GBAN] This module gbans everybody by *!*@host who rejoins ... does NOT work on kicks!

satmd_botnet_require gban

setudef int "satmd_botnet_antirejoin_delay"

bind join -|- "% *" satmd_botnet_antirejoin_join
bind part -|- "% *" satmd_botnet_antirejoin_part

proc satmd_botnet_antirejoin_part { nick uhost handle channel text } {
	global botnick satmd_botnet
	if { ([isbotnick $nick]) || ($handle != "*") } { return 0}
	set delay [channel get $channel "satmd_botnet_antirejoin_delay"]
	if { $delay != 0 } {
		set satmd_botnet(antirejoin,$channel,$nick) "[unixtime]"
		after [expr $delay * 2000 ] [list unset satmd_botnet(antirejoin,$channel,$nick)]
	}
}

proc satmd_botnet_antirejoin_join { nick uhost handle channel} {
	global botnick satmd_botnet
	if { ([isbotnick $nick]) || ($handle != "*") } { return 0}
	set delay [channel get $channel "satmd_botnet_antirejoin_delay"]
	if { $delay != 0 } {
		if { [info exists satmd_botnet_antirejoin($channel,$nick)] } {
			set stamp2 [unixtime]
			set stamp1 $satmd_botnet(antirejoin,$channel,$nick)
			if { [expr $stamp2 - $stamp1] < $delay } {
				set banmask [satmd_botnet_genericbanmask $nick $uhost]
				satmd_botnet_gban_add "$banmask" "30m" "antirejoin@$botnick" $botnick "antirejoin" 1
				satmd_botnet_gban_add "$banmask" "15d" "noxdcccatcher@$botnick" "$botnick" "xdcc catcher not allowed" 1
			}
		}
	}
}

# Sucessful
set satmd_botnet(version,antirejoin) "0.2.2"
return 1
