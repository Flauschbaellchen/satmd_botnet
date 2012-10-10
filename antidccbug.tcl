# antidccbug: auto-gban mIRC DCC exploits

satmd_botnet_require gban

bind msgm -|- "\001DCC*" satmd_botnet_antidccbug_msgm
bind pubm -|- "\001DCC*" satmd_botnet_antidccbug_pubm
bind ctcp -|- "DCC" satmd_botnet_antidccbug_ctcp

proc satmd_botnet_antidccbug_ctcp { nick uhost handle dest keyword text } {
	global botnick
	set dcc_type [string toupper [lindex $text 0]]
	if { $dcc_type == "SEND"  && ( [string length $text] > 200 || [satmd_botnet_antidccbug_count $text " "] > 20) } {
		putloglev "cmdw1" "*" "mIRC DCC SEND exploit detected @ $nick!$uhost/$handle:$dest"
		set banmask1 "$nick!*@*"
		set banmask2 "*!*@[lindex [split $uhost @] 1]"
		catch { satmd_gban_add $banmask1 $botnick "EXPLOIT: mIRC DCC SEND" }
		catch { satmd_gban_add $banmask2 $botnick "EXPLOIT: mIRC DCC SEND" }
		satmd_botnet_gban_add "$banmask1" "90d" "antidccbug@$botnick" "$botnick" "mIRC DCC exploit detected" 1
		satmd_botnet_gban_add "$banmask2" "15d" "antidccbug@$botnick" "$botnick" "mIRC DCC exploit detected" 1
		return 1
	}
	return 0
}

proc satmd_botnet_antidccbug_msgm { nick uhost handle text } {
	set text [split $text]
	global botnick
	set dcc_type [string toupper [lindex $text 0]]
	if { $dcc_type == "SEND"  && ( [string length $text] > 200 || [antidccbug_count $text " "] > 20) } {
		putloglev "cmdw1" "*" "mIRC DCC SEND exploit detected @ $nick!$uhost/$handle:$botnick"
		set banmask1 "$nick!*@*"
		set banmask2 "*!*@[lindex [split $uhost @] 1]"
		catch { satmd_gban_add $banmask1 $botnick "EXPLOIT: mIRC DCC SEND" }
		catch { satmd_gban_add $banmask2 $botnick "EXPLOIT: mIRC DCC SEND" }
		satmd_botnet_gban_add "$banmask1" "90d" "antidccbug@$botnick" "$botnick" "mIRC DCC exploit detected" 1
		satmd_botnet_gban_add "$banmask2" "15d" "antidccbug@$botnick" "$botnick" "mIRC DCC exploit detected" 1
		return 1
	}
	return 0
}

proc satmd_botnet_antidccbug_pubm { nick uhost handle channel text } {
	global botnick
	set dcc_type [string toupper [lindex $text 0]]
	if { $dcc_type == "SEND"  && ( [string length $text] > 200 || [satmd_botnet_antidccbug_count $text " "] > 20) } {
	putloglev "cmdw1" "*" "mIRC DCC SEND exploit detected @ $nick!$uhost/$handle:$channel"
	set banmask1 "$nick!*@*"
	set banmask2 "*!*@[lindex [split $uhost @] 1]"
	satmd_botnet_gban_add "$banmask1" "90d" "antidccbug@$botnick" "$botnick" "mIRC DCC exploit detected" 1
	satmd_botnet_gban_add "$banmask2" "15d" "antidccbug@$botnick" "$botnick" "mIRC DCC exploit detected" 1
	return 1
	}
	return 0
}


proc satmd_botnet_antidccbug_count { haystack needle } {
	set count 0
	for { set pos 0 } { $pos <[string length $haystack]} {incr pos} {
		if { [string index $haystack $pos] == $needle} { incr count }
	}
	return $count
}

set satmd_botnet(antidccbug,version) "0.2.1"
