# MODULE gban
#
# This module provides a botnet-global ban system WITHOUT sharing module
# Look at satmd_botnet_gban_gettime before using this module!
# Examples:
# !gban banmask duration reason
# !gunban banmask [reason]
# .gban add banmask duration reason
# .gban del banmask [reason]

# 0.7.6: fixed SERIOUS bug about split/join/lindex/lrange
# 0.7.7: catch'ing calls to _report
# .....: various small typos
# 0.8.3: make use of a better reason syntax and hash-crc32

satmd_botnet_require hooks
satmd_botnet_require prefixaq

# bind GBAN commands
bind pub nG|G  "$satmd_botnet(cmdchar)gban"                 satmd_botnet_gban_pub
bind pub -|-  "$satmd_botnet(cmdchar)gunban"                satmd_botnet_gunban_pub
bind pub nt|- "$satmd_botnet(cmdchar)mgban"                 satmd_botnet_massgban_pub
bind bot -|-  "gban"                   satmd_botnet_gban_bot
bind dcc nGU|GU  "gban"                  satmd_botnet_gban_dcc
bind dcc nG|G  "+gban"       satmd_botnet_gban_dcc_add
bind dcc nmGU|nGU  "-gban"           satmd_botnet_gban_dcc_del
bind join -|- "% *"                    satmd_botnet_gban_blacklist_join
bind dcc nmol|nmol "testgban"         satmd_botnet_gban_test_dcc
bind pub nmol|nmol  "$satmd_botnet(cmdchar)testgban"        satmd_botnet_gban_test_pub
bind msg nmol|nmol  "testgban"         satmd_botnet_gban_test_msg

# Create GBAN udef
setudef flag "satmd_botnet_gban"
catch { deludef flag "gban" }

setudef flag "satmd_botnet_gban_blacklisted"

# Handle public GBAN
proc satmd_botnet_gban_pub { nick uhost handle channel text } {
	global botnick
	set text [split $text]
	set target [lindex $text 0]
	if { [onchan $target] } {
		set target [satmd_botnet_genericbanmask $target [getchanhost $target]]
	} elseif { [string match -nocase "&R:*" $target] && ![satmd_botnet_checkregexp $target] } {
		putnotc $nick "gban: denied. (broken regexp)"
		return 0
	}
	set duration [lindex $text 1]
	set reason [join [lrange $text 2 end]]
	if { [lindex $text 1] == "force" } {
		set duration [lindex $text 2]
		set reason [join [lrange $text 3 end]]
	if { [matchattr $handle "nG|-"] } {
		putnotc $nick "gban: forcefully accepted."
	} else {
		putnotc $nick "gban: denied. invalid syntax (\"force\" is reserved)"
	return 0
	}
	} else { 
		if { ![satmd_botnet_issecureban "nick" $nick $target] } { 
			putnotc $nick "gban: denied."
			return 0
		} else {
			set duration [lindex $text 1]
			set readon [join [lrange $text 2 end]]
		}
	}
	set hash [satmd_botnet_hash_crc32 $target]
	satmd_botnet_hooks_call gban_pub
	set reason "(Global Ban) Handle:($handle) Hash:($hash) Expiry:([strftime "%x" [expr [unixtime] + 60 * [satmd_botnet_timespec2mins $duration]]]) Reason:($reason)"
	if { [satmd_botnet_gban_add $target $duration "$nick!$uhost" $handle $reason 1] } {
		putnotc $nick "Added $target: $reason"
	}
	return 0
	}

# Handle public GUNBAN
proc satmd_botnet_gunban_pub { nick uhost handle channel text } {
	global botnick
	set text [split $text]
	if { [matchattr $handle GU|GU $channel] || (( [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle olGN|olG $channel] ) && [channel get $channel "satmd_botnet_gban"] == 1)} {
		set target [lindex $text 0]
		set reason [join [lrange $text 1 end]]
		satmd_botnet_hooks_call gunban_pub
		if { [satmd_botnet_gban_del $target "$nick!$uhost" "$handle" $reason 1] } {
			putnotc $nick "(Global Ban) Banmask:($target) removed"
		}
	}
	return 0
}

# Handle remote (bot) GBAN
proc satmd_botnet_gban_bot { frombot keyword text } {
	# if { [isbotnick $frombot]} { return 1}
	global botnick
	set text [split $text]
	# putlog "DEBUG $text"
	if { [matchattr $frombot "G"] } {
		set action [lindex $text 0]
		switch $action {
			add {
				set target  [lindex $text 1]
				set duration [lindex $text 2]
				set mask [lindex $text 3]
				set handle [lindex $text 4]
				set reason [join [lrange $text 5 end]]
				if { ![satmd_botnet_issecureban "bot" $handle $target] } { return 0 }
				satmd_botnet_hooks_call gban_bot_add
				satmd_botnet_gban_add $target $duration "$mask@$frombot" $handle $reason 0
			}
			del {
				set target [join [lindex $text 1]]
				set mask [lindex $text 2]
				set handle [lindex $text 3]
				set reason [join [lrange $text 4 end]]
				satmd_botnet_hooks_call gban_bot_del
				satmd_botnet_gban_del $target "$mask@$frombot" $handle $reason 0
			}
		}
	}
	return 0
}

# Handle partyline GBAN/GUNBAN
proc satmd_botnet_gban_dcc_add { handle idx text} {
	satmd_botnet_gban_dcc $handle $idx "add $text"
}
proc satmd_botnet_gban_dcc_del { handle idx text} {
	satmd_botnet_gban_dcc $handle $idx "del $text"
}
proc satmd_botnet_gban_dcc {handle idx text} {
	putidx $idx "DEBUG: $text"
	global botnick
	set text [split $text]
	set action [lindex $text 0]
	set target [lindex $text 1]
	putidx $idx "DEBUG: $target"
	if { ([string tolower $action] == "add") && [matchattr $handle nG] } {
		if { [onchan $target] } {
			set target [satmd_botnet_genericbanmask $target [getchanhost $target]]
		} elseif { ([string match -nocase "&R:*" $target] && ![satmd_botnet_checkregexp $target]) } {
				putidx $idx "gban: denied. (broken regexp)"
				return 0
		}
		if { [lindex $text 2] == "force" } {
			if { [matchattr $handle "nG|-"] } {
				set duration [lindex $text 3]
				set reason [join [lrange $text 4 end]]
				putidx $idx "gban: forcefully accepted."
			} else {
				putidx $idx "gban: denied. invalid syntax (\"force\" is reserved )"
				return 0
			}
		} else {
			if { ![satmd_botnet_issecureban "idx" $idx $target] } { 
				putidx $idx "gban: denied."
				return 0
			} else {
				set duration [lindex $text 2]
				set reason [join [lrange $text 3 end]]
			}
		}
		set hash [satmd_botnet_hash_crc32 $target]
		satmd_botnet_hooks_call gban_dcc_add
		set reason "(Global Ban) Handle:($handle) Hash:($hash) Expiry:([strftime "%x" [expr [unixtime] + 60 * [satmd_botnet_timespec2mins $duration]]]) Reason:($reason)"
		satmd_botnet_gban_add $target $duration "[hand2nick $handle]![getchanhost [hand2nick $handle]]" $handle $reason 1
		putcmdlog "satmd_botnet:gban add $target" 
	} elseif { ([string tolower $action] == "del") } {
		set hash [satmd_botnet_hash_crc32 $target]
		set reason [join [lrange $text 2 end]]
		satmd_botnet_hooks_call gban_dcc_del
		satmd_botnet_gban_del $target "[hand2nick $handle]![getchanhost [hand2nick $handle]]" $handle $reason 1
		putcmdlog "satmd_botnet:gban del $target"
	} elseif { $action == "" } {
		putidx $idx "SYNTAX: gban add <hostmask> <duration> <reason>"
		putidx $idx "        gban del <hostmask> \[<reason>\]"
	}
	return 0
}


# main GBAN function
proc satmd_botnet_gban_add { target duration mask handle reason forward } {
	global satmd_botnet
	set duration [satmd_botnet_timespec2mins $duration]
	if { ($duration != "-1") && ($duration >= 0) } {
		if { ![isban $target]}  {
			newban $target $handle $reason $duration
			putcmdlog "satmd_botnet:gban add $target \[$reason\] by $mask ($handle) (duration:$duration)"
		}
		if { $forward == 1 } {
			putallbots "gban add $target $duration $mask $handle $reason"
		}
	}
	satmd_botnet_hooks_call gban_add
	catch { gbanlist_add $target $reason $handle}
	return 1
}

# main GUNBAN function
proc satmd_botnet_gban_del { target mask handle reason forward } {
	# putlog "DEBUG del $target $mask $handle $reason $forward"
	global satmd_botnet
	foreach c [channels] { 
		killchanban "$c" "$target"
		# if a "ghost" is still there, do it always:
		pushmode "$c" "-b" "$target"
	}
	if { $forward == 1 } {
		putallbots "gban del $target $mask $handle $reason"
	}
	killban $target
	satmd_botnet_hooks_call gban_del
	catch { gbanlist_del $target }
	putcmdlog "satmd_botnet:gban del $target by $mask ($handle)"
	return 1
}

# handle public MGBAN
proc satmd_botnet_massgban_pub { nick uhost handle channel text } {
	set text [split $text]
	set text [join [lrange $text 1 end]]
	set maxmode ""
	set key [join [lindex $text 0]]
	if { $key == "v" } { set maxmode "v" }
	if { $key == "-" } { set maxmode "-" }
	if { $maxmode == "" } { return 0}
	if { $maxmode != "" } { set text [join [lrange $text 1 end]] }
	foreach n [chanlist $channel] {
		if { ![matchattr [nick2hand $n] "nmol|nmol" $channel] &&
			(![isvoice $n $channel] || $maxmode == "v" ) &&
			(![ishalfop $n $channel] ) &&
			(![isop $n $channel] ) && 
			(![isadmin $n $channel] ) && 
			(![isfounder $n $channel] ) &&
			( [nick2hand $n] == "*" )
		} {
			set banmask [satmd_botnet_genericbanmask $n [getchanhost $n $channel]]
			satmd_botnet_gban_add "$banmask" 86400 "$nick!$uhost" $handle "mgban: $text" 1
		}
	}
}

# Retrieve timings for bans (and send -1 for denies)
#
# Decide wether bans are safe
proc satmd_botnet_issecureban { issuertype issuer banmask { channel ""}} {
	global satmd_botnet
	set global_hostlist ""
	set global_users 0
	set errormsg ""
	foreach c [channels] {
		if { [string match -nocase "$channel" "$c"] || ($channel == "") } {
			set local_hostlist ""
			set local_users 0
			foreach u [chanlist $c] {
				incr local_users
				incr global_users
				set umask "$u![getchanhost $u]"
				# Anchoring + avoiding numerals
				if {[string match "x[matchsafe $banmask]" "x$umask"] } {
					putloglev "d" "$channel" "unsafe banmask matches [matchsafe $banmask] -> $umask"
					lappend global_hostlist $umask
					lappend local_hostlist $umask
				}
			}
			if { [info exists satmd_botnet(gban,safe_threshold,local,$c)] } {
				if { [llength $local_hostlist] > $satmd_botnet(gban,safe_threshold,local,$c) } {
					lappend errormsg "Banmask $banmask is unsafe for $c ([llength $local_hostlist] hit) (max: $satmd_botnet(gban,safe_threshold,local,$c)) -- using channel specific value"
				}
			} else {
				if { [llength $local_hostlist] > $satmd_botnet(gban,safe_threshold,local) } {
					lappend errormsg "Banmask $banmask is unsafe for $c ([llength $local_hostlist] hit) (max: $satmd_botnet(gban,safe_threshold,local))"
				}
			}
		}
	}
	if { ($channel == "") && ([llength $global_hostlist] > $satmd_botnet(gban,safe_threshold,global)) } {
		lappend errormsg "Banmask $banmask is globally unsafe ([llength $global_hostlist] hit)"
	}
	foreach msg $errormsg {
		switch $issuertype {
			idx { putidx $issuer "gban: $msg" }
			nick { putnotc $issuer "gban: $msg" }
			bot { }
		}
	}
	if { $errormsg == "" } {
		return 1
	} else {
		return 0
	}
}

proc satmd_botnet_gban_blacklist_join { nick uhost handle channel } {
	global botnick
	if { [channel get $channel "satmd_botnet_gban_blacklisted"] && ($handle == "*") && (![isbotnick $nick]) } {
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		satmd_botnet_gban_add "$banmask" 86400 "BLACKLIST@$botnick" $botnick "$nick joined blacklisted channel ($channel)" 1
	}
}

proc satmd_botnet_gban_test_dcc { handle idx text } {
	set ban [lindex [split $text ] 0]
	set channel [lindex [split $text ] 1]
	if { [satmd_botnet_issecureban "idx" $idx $ban $channel] } { putidx $idx "Gban is secure" }
}

proc satmd_botnet_gban_test_pub { nick uhost handle channel text } {
	set ban [lindex [split $text ] 0]
	set channel [lindex [split $text ] 1]
	if { [satmd_botnet_issecureban "nick" $nick $ban $channel] } { putnotc $nick "Gban is secure" }
}

proc satmd_botnet_gban_test_msg { nick uhost handle text } {
	set ban [lindex [split $text ] 0]
	set channel [lindex [split $text ] 1]
	if { [satmd_botnet_issecureban "nick" $nick $ban $channel] } { putnotc $nick "Gban is secure" }
}

proc satmd_botnet_gban_trojan_pubm { nick uhost handle channel text } {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick] || [isop $nick $channel] || [ishalfop $nick $channel]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "TROJAN@$botnick" $botnick "$nick spreads trojans" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed a trojan ($channel: $text)" }
	putloglev "d" "*" "TROJAN detected: $nick!$uhost"
}

proc satmd_botnet_gban_spam_pubm { nick uhost handle channel text } {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick] || [isop $nick $channel] || [ishalfop $nick $channel]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "SPAM@$botnick" $botnick "$nick removed for spam" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed me ($channel: $text)" }
	putloglev "d" "*" "SPAM detected: $nick!$uhost"
}

proc satmd_botnet_gban_trojan_msgm { nick uhost handle text } {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "TROJAN@$botnick" $botnick "$nick spreads trojans" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed a trojan ($text)" }
	putloglev "d" "*" "TROJAN detected: $nick!$uhost"
}
proc satmd_botnet_gban_spam_msgm { nick uhost handle text } {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "SPAM@$botnick" $botnick "$nick removed for spam" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed me ($text)" }
	putloglev "d" "*" "SPAM detected: $nick!$uhost"
}

proc satmd_botnet_gban_trojan_notc { nick uhost handle text destination} {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick] || [isop $nick $channel] || [ishalfop $nick $destination]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "TROJAN@$botnick" $botnick "$nick spreads trojans" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed a trojan ($destination: $text)" }
	putloglev "d" "*" "TROJAN detected: $nick!$uhost"
}

proc satmd_botnet_gban_spam_notc { nick uhost handle text destination} {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick]  || [isop $nick $channel] || [ishalfop $nick $destination]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "SPAM@$botnick" $botnick "$nick removed for spam" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed me ($destination: $text)" }
	putloglev "d" "*" "SPAM detected: $nick!$uhost"
}

proc satmd_botnet_gban_trojan_quitpart { nick uhost handle channel text } {
	global botnick satmd_botnet
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	if { ($handle != "*") || ([isbotnick $nick] || [isop $nick $channel] || [ishalfop $nick $channel]) } { return 1 }
	satmd_botnet_gban_add "$banmask" 86400 "SPAM@$botnick" $botnick "$nick removed for spam" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed me a trojan ($channel: $text)" }
	putloglev "d" "*" "SPAM detected: $nick!$uhost"
}
proc satmd_botnet_gban_spam_quitpart { nick uhost handle channel text } {
	global botnick satmd_botnet
	if { ($handle != "*") || ([isbotnick $nick] || [isop $nick $channel] || [ishalfop $nick $channel]) } { return 1 }
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	satmd_botnet_gban_add "$banmask" 86400 "SPAM@$botnick" $botnick "$nick removed for spam" 1
	catch { satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:trojan $nick!$uhost spammed me ($channel: $text)" }
	putloglev "d" "*" "SPAM detected: $nick!$uhost"
}


# netgear reset bug abuse
bind pubm - "*DCC * 0 0 0*" satmd_botnet_gban_trojan_pubm

# norton bug abuse
bind pubm - "*startkeylogger*" satmd_botnet_gban_trojan_pubm
bind pubm - "*stopkeylogger*" satmd_botnet_gban_trojan_pubm

# sohbet bot
bind notc - "\001VERSION" satmd_botnet_gban_trojan_notc

# updated sohbet bot
bind msgm - "*h%t%t%p%:%/%/*" satmd_botnet_gban_spam_msgm
bind pubm - "*powered by Albanian Hackers*" satmd_botnet_gban_spam_pubm

# SICORPS
bind sign - "Quit: error 21*" satmd_botnet_gban_trojan_quitpart
bind sign - "error 21*" satmd_botnet_gban_trojan_quitpart

# Successful
set satmd_botnet(version,gban) "0.9.4"
return 1

