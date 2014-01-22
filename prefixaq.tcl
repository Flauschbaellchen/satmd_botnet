# MODULE prefixaq
#
# This module adds rudimentary support for
# channel prefix +q/+a
#
# IMPORTANT NOTE:
#	 This does not stop eggdrop from handling
#	 q/a ircnet style!

# setting sane opchars, older eggdrops will ignore it
set opchars "@!*&~"

bind raw - "353" satmd_botnet_prefixaq_parse353
proc satmd_botnet_prefixaq_parse353 { from keyword text } {
	catch {
		global satmd_botnet
		set channel [lindex $text 2]
		set names [join [string replace [lrange $text 3 end] 0 0]]
		catch {
			foreach names_t $names {
				set modechar [string range $names_t 0 0]
				if {   $modechar == "!"
					|| $modechar == "*"
					|| $modechar == "~"
					|| $modechar == "&"
					|| $modechar == "@"
					|| $modechar == "%"
					|| $modechar == "+"
				} {
					set target [string range $names_t 1 end]
				} else {
					set target $names_t
					set modechar ""
				}
				if { $modechar == "!" } { set modechar "&" }
				if { $modechar == "*" } { set modechar "~" }
				set satmd_botnet(prefixaq,$channel,$target) "$modechar"
			}
		}
	}
	return 0
}

bind nick -|- "*" satmd_botnet_prefixaq_nick
proc satmd_botnet_prefixaq_nick { nick uhost handle channel newnick } {
	global satmd_botnet
	catch {
		regsub {^[*~&@%+]} $nick {} nick
		regsub {^[*~&@%+]} $newnick {} newnick
		set satmd_botnet(prefixaq,$channel,$newnick) $satmd_botnet(prefixaq,$channel,$nick)
		unset satmd_botnet(prefixaq,$channel,$nick)
	}
}

bind mode -|- "*" satmd_botnet_prefixaq_mode
proc satmd_botnet_prefixaq_mode { nick uhost handle channel mchange victim } {
	global satmd_botnet
	if { $victim == "" } { return 0 }
	regsub {^[*~&@%+]} $victim {} victim
	set modechar ""
	catch {
		set modechar $satmd_botnet(prefixaq,$channel,$victim)
	}
	if { $mchange == "+q" } {
		set modechar "~"
	} elseif { ($mchange == "+a") && ($modechar != "~") } {
		set modechar "&"
	} elseif { $mchange == "-q" } {
		set modechar ""
	} elseif { ($mchange == "-a") && ($modechar == "&") } {
		set modechar ""
	} else {
		# do nothing
	}
	set satmd_botnet(prefixaq,$channel,$victim) $modechar
	return 0
}

bind rejn -|- "*" satmd_botnet_prefixaq_join
bind join -|- "*" satmd_botnet_prefixaq_join
proc satmd_botnet_prefixaq_join { nick uhost handle channel } {
	global satmd_botnet
	regsub {^[*~&@%+]} $nick {} nick
	set satmd_botnet(prefixaq,$channel,$nick) ""
}

bind part -|- "*" satmd_botnet_prefixaq_partsign
bind sign -|- "*" satmd_botnet_prefixaq_partsign

proc satmd_botnet_prefixaq_partsign { nick uhost handle channel dummy} {
	global satmd_botnet
	regsub {^[*~&@%+]} $nick {} nick
	if { [info exists satmd_botnet(prefixaq,$channel,$nick)] } {
		unset satmd_botnet(prefixaq,$channel,$nick)
	}
}

proc botisadmin { channel } {
	global satmd_botnet botnick
	set result 0
	catch {
		if { $satmd_botnet(prefixaq,$channel,$botnick) == "&" } {
			set result 1
		}
	}
	return $result
}

proc botisfounder { channel } {
	global satmd_botnet botnick
	set result 0
	catch {
		if { $satmd_botnet(prefixaq,$channel,$botnick) == "~" } {
			set result 1
		}
	}
	return $result
}

proc isadmin { channel nick } {
	global satmd_botnet
	set result 0
	regsub {^[*~&@%+]} $nick {} nick
	catch { 
		if { $satmd_botnet(prefixaq,$channel,$nick) == "&" } { 
			set result 1
		}
	}
	return $result
}

proc isfounder { channel nick } {
	global satmd_botnet
	set result 0
	regsub {^[*~&@%+]} $nick {} nick
	catch { 
		if { $satmd_botnet(prefixaq,$channel,$nick) == "~" } { 
			set result 1
		}
	}
	return $result
}

bind raw -|- "MODE" satmd_botnet_prefixaq_modeRAW
proc satmd_botnet_prefixaq_modeRAW { from keyword text} {
	catch {
		set text [split $text]
		set nick [lindex $text 2]
		set mode [lindex $text 1]
		set channel [lindex $text 0]
		regsub {^[*~&@%+]} $nick {} nick
		satmd_botnet_prefixaq_mode "" "" "" $channel $mode $nick
	}
	return 0
}

set satmd_botnet(version,prefixaq) "0.2"

return 1
