#module knock
bind raw -|- "NOTICE" satmd_botnet_knock_raw
#bind raw -|- "KNOCK" satmd_botnet_knock_raw
bind notc -|- "% \[KNOCK\] *" satmd_botnet_knock_notc

setudef flag satmd_botnet_knockable

proc satmd_botnet_knock_raw { from keyword text } {
	set text [split $text]
	putloglev "d" "*" "invite(0): [lindex $text 0]"
	putloglev "d" "*" "invite(1): [join [lrange $text 1 end]]"
	if {
		([string match "@#*" [lindex $text 0]]) &&
		([string match -nocase ":\\\[Knock\\\] by *" [join [lrange $text 1 end]]])
	} {
		putloglev "d" "*" "invite(2): damn lemme in"
		set nick [lindex [split [lindex $text 3] !] 0]
		set channel [string range [lindex $text 0] 1 end]
		if { [channel get $channel "satmd_botnet_knockable"] && (![onchan $nick $channel]) } {
			putserv "INVITE $nick $channel"
		}
	}
}

proc satmd_botnet_knock_notc { nick uhost handle channel text } {
	satmd_botnet_knock_raw ":me" "NOTICE" "$channel :\[Knock\] by $nick$uhost ($text)"
}

set satmd_botnet(version,knock) "0.1"

# Sucessful
return 1
