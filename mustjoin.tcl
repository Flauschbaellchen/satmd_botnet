# MODULE mustjoin
#
# You can force users to join #A and stay there if they want to join
# #B. You'll sure will find a purpose ;)

#satmd_botnet_minversion "1.6.15"

setudef str "satmd_botnet_mustjoin"
catch { deludef str "mustjoin" }
bind join - "*" satmd_botnet_mustjoin_join
# bind sign - "*" satmd_botnet_mustjoin_sign
bind part - "*" satmd_botnet_mustjoin_part
bind kick - "*" satmd_botnet_mustjoin_kick
bind pub - "$satmd_botnet(cmdchar)mustjoin" satmd_botnet_mustjoin_pub

proc satmd_botnet_mustjoin_pub { nick uhost handle channel text } {
	global botnick
	if { ([isop $nick $channel] == 0) && ([ishalfop $nick $channel] == 0) && ([matchattr $handle "+mnol|+mnol" "$channel"]  == 0 )} { return 0 }
	set mustjoin [split [channel get $channel "satmd_botnet_mustjoin"] :]
	set mustjoinchannel [lindex $mustjoin 2]
	set mustjoindelay [lindex $mustjoin 0]
	set mustjoinduration [lindex $mustjoin 1]
	if { $mustjoinchannel == "" || $mustjoindelay == "" || $mustjoinduration == "" } { return 0 }
	putchan $channel "\[mustjoin\] Checking for violations..."
	foreach mustjoinnick [chanlist $channel] {
		if { ( [isop $mustjoinnick $mustjoinchannel] == 0 ) && ( [ishalfop $mustjoinnick $mustjoinchannel] == 0 ) &&  ( [isbotnick $mustjoinnick] ==0 ) && ( [matchattr [nick2hand $mustjoinnick] "+mno|+Ffolmn" "$channel"]  == 0  ) && ([onchan $mustjoinnick $mustjoinchannel] == 0 ) && ( [botonchan $mustjoinchannel] == 1 ) && ( [botonchan $channel] == 1 )} {
			newchanban "$channel" "$mustjoinnick![getchanhost $mustjoinnick]" "$botnick" "You must join $mustjoinchannel. Banned for $mustjoinduration minute(s)" $mustjoinduration 
		}
	}
	putchan $channel "\[mustjoin\] done"
}

proc satmd_botnet_mustjoin_sign { nick uhost handle channel reason } {
	satmd_botnet_mustjoin_join $nick $uhost $handle $channel
}
proc satmd_botnet_mustjoin_join  { nick uhost handle channel } {
	global botnick
	set mustjoin [split [channel get $channel "satmd_botnet_mustjoin"] :]
	set mustjoinchannel [lindex $mustjoin 2]
	set mustjoindelay [lindex $mustjoin 0]
	set mustjoinduration [lindex $mustjoin 1]
	if { $mustjoinchannel == "" || $mustjoindelay == "" || $mustjoinduration == "" } { return 0 }
	after [expr 1000 * $mustjoindelay] [list satmd_botnet_mustjoin_join2 "$nick" "$uhost" "$handle" "$channel"]
}

proc satmd_botnet_mustjoin_join2 { nick uhost handle channel } {
	global botnick
	set mustjoin [split [channel get $channel "satmd_botnet_mustjoin"] :]
	set mustjoinchannel [lindex $mustjoin 2]
	set mustjoindelay [lindex $mustjoin 0]
	set mustjoinduration [lindex $mustjoin 1]
	if { $mustjoinchannel == "" || $mustjoindelay == "" || $mustjoinduration == "" } { return 0 }
	if { ( [onchan $nick $mustjoinchannel ] == 0 ) && ( [isop $nick $mustjoinchannel]== 0 ) && ( [ishalfop $nick $mustjoinchannel] == 0 ) && ( [isbotnick $nick] ==0 ) && ( [matchattr [nick2hand $nick] "+mno|+Ffolmn" "$channel"] == 0 ) && ( [onchan $nick $channel] == 1 ) && ( [botonchan $mustjoinchannel] == 1 ) && ( [botonchan $channel] == 1 )} {
		newchanban "$channel" "$nick!$uhost" "$botnick" "You must join $mustjoinchannel. Banned for $mustjoinduration minute(s)" $mustjoinduration
	}
}

proc satmd_botnet_mustjoin_kick { actor uhost handle channel nick reason } {
	global botnick
	foreach c [channels] {
		set mustjoin [split [channel get $c "satmd_botnet_mustjoin"] :]
		set mustjoinchannel [lindex $mustjoin 2]
		set mustjoindelay [lindex $mustjoin 0]
		set mustjoinduration [lindex $mustjoin 1]
		if { $mustjoinchannel == "$channel" && $mustjoindelay != "" && $mustjoinduration != "" } {
			if { ( [isop $nick $mustjoinchannel] == 0 ) && ( [ishalfop $nick $mustjoinchannel] == 0 ) &&  ( [isbotnick $nick] ==0 ) && ( [matchattr [nick2hand $nick] "+mno|+Ffolmn" "$c"]  == 0  ) && ([onchan $nick $c] == 1 )&& ( [botonchan $mustjoinchannel] == 1 ) && ( [botonchan $channel] == 1 )} {
				newchanban "$c" "$nick![getchanhost $nick $c]" "$botnick" "You must join $mustjoinchannel. Banned for $mustjoinduration minute(s)" $mustjoinduration
			}
		}
	}
}

proc satmd_botnet_mustjoin_part { nick uhost handle channel {msg "" }} {
	global botnick
	foreach c [channels] {
		set mustjoin [split [channel get $c "satmd_botnet_mustjoin"] :]
		set mustjoinchannel [lindex $mustjoin 2]
		set mustjoindelay [lindex $mustjoin 0]
		set mustjoinduration [lindex $mustjoin 1]
		if { $mustjoinchannel == "$channel" && $mustjoindelay != "" && $mustjoinduration != "" } {
			if { ( [isop $nick $mustjoinchannel]== 0 ) && ( [ishalfop $nick $mustjoinchannel] == 0 ) && ( [isbotnick $nick] ==0 ) && ( [matchattr [nick2hand $nick] "+mno|+Ffolmn" "$channel"] == 0 ) && ( [onchan $nick $c] ==1) && ( [botonchan $mustjoinchannel] == 1 ) && ( [botonchan $channel] == 1 )} {
				newchanban "$c" "$nick!$uhost" "$botnick" "You must join $mustjoinchannel. Banned for $mustjoinduration minute(s)" $mustjoinduration
			}
		}
	}
}

# Successful
set satmd_botnet(version,mustjoin) "0.2"
return 1
