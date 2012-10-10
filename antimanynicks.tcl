# MODULE antimanynicks
#
# this module checks if someone on the same IP join the channel with multiple nicks in a short time
# ban *!*@$host if the limit is five or more
# users with a handle, Guest* or with *.euirc.net are ignored
#
# to refresh/delete one host use !resetantimanynicks *!*@$host
# or
# prefer !unlocker *!*@$host if unlocker.tcl is loaded
#

satmd_botnet_require gban

setudef flag "satmd_botnet_antimanynicks"

bind join -|- "% *" satmd_botnet_antimanynicks_join
bind time -|- "* * * * *" satmd_botnet_antimanynicks_timer
bind dcc n "resetantimanynicks" satmd_botnet_antimanynicks_reset_dcc
bind pub mno|mno "$satmd_botnet(cmdchar)resetantimanynicks" satmd_botnet_antimanynicks_reset_pub

proc satmd_botnet_antimanynicks_join { nick uhost handle channel} {
	global botnick satmd_botnet
	if {
		([isbotnick $nick]) ||
		($handle != "*") ||
		(![channel get $channel "satmd_botnet_antimanynicks"]) ||
		([string match "Guest*" $nick]) ||
		([string match -nocase "*.euirc.net" $uhost]) ||
		[satmd_botnet_isCGIClient $nick $uhost] } {
		return 0
	} else {
		set hostmask [lindex [split $uhost @] 1]
		if { [info exists satmd_botnet(antimanynicks,nicks,$hostmask)] } {
			set oldnick 0
			foreach nicklist [split $satmd_botnet(antimanynicks,nicks,$hostmask)] {
				if { $nick == $nicklist } { set oldnick 1 }
			}
			if { $oldnick == 0 } {
				lappend satmd_botnet(antimanynicks,nicks,$hostmask) $nick
				set satmd_botnet(antimanynicks,timer,$hostmask) [unixtime]
			}
		} else {
			set satmd_botnet(antimanynicks,nicks,$hostmask) $nick
			set satmd_botnet(antimanynicks,timer,$hostmask) [unixtime]
		}
		catch {
			foreach listname [array names satmd_botnet "importlist,lists,*"] {
				if { [lsearch -exact $satmd_botnet($listname) $nick] != -1 } {
					lappend satmd_botnet(antimanynicks,nicks,$hostmask) $nick
				}
			}
		}
		if { [llength $satmd_botnet(antimanynicks,nicks,$hostmask)] > 4 } {
			putloglev dk "*" "manynicks function activated on $hostmask"
			satmd_botnet_gban_add "*!*@$hostmask" "14d" "antimanynicks@$botnick" "$botnick" "Nick changing bot detected" 1
		}
	}
}

proc satmd_botnet_antimanynicks_timer { a b c d e } {
	global satmd_botnet
	foreach item [array names satmd_botnet "antimanynicks,nicks,*"] {
	set host [lindex [split $item ,] 2]
	if { $satmd_botnet(antimanynicks,timer,$host) + 600 < [unixtime] } {
	unset satmd_botnet($item)
	unset satmd_botnet(antimanynicks,timer,$host)
	}
	}
}

proc satmd_botnet_antimanynicks_reset_dcc { handle idx text } {
	set hostmask [lindex [split $text] 0]
	if { [info exists satmd_botnet(antimanynicks,nicks,$hostmask)] } {
		unset satmd_botnet(antimanynicks,nicks,$hostmask)
		unset satmd_botnet(antimanynicks,timer,$hostmask)
		putidx $idx "antimanynicks.tcl: reset data for $hostmask"
	} else {
		putidx $idx "antimanynicks.tcl: no such record"
	}
}

proc satmd_botnet_antimanynicks_reset_pub { nick uhost handle channel text } {
	set hostmask [lindex [split [lindex [split $text] 0] @] 1]
	if { [info exists satmd_botnet(antimanynicks,nicks,$hostmask)] } {
		unset satmd_botnet(antimanynicks,nicks,$hostmask)
		unset satmd_botnet(antimanynicks,timer,$hostmask)
		putnotc $nick "antimanynicks.tcl: reset data for $hostmask"
	} else {
		putnotc $nick "antimanynicks.tcl: no such record"
	}

}

# Sucessful
set satmd_botnet(version,antimanynicks) "0.1.11"
return 1

