# MODULE depends
#
# This module is intended to keep some shared procedures for overall usage
# By now, only stripcontrolcodes for removing any mIRC coloring/bold/inverse/bells/underline/...
#

# cleanup strings
proc stripcontrolcodes { inputdata } {
	regsub -all -- {\003[0-9]{0,2}(,[0-9]{0,2})?|\017|\037|\002|\026|\006|\007} $inputdata "" inputdata
	return $inputdata
}
proc striprep { inputdata } {
	set inputdata [stripcontrolcodes $inputdata]
	regsub -all -- {_} $inputdata { } inputdata
	return $inputdata
}
proc matchsafe { inputdata } {
	regsub -all -- {\[|\]|\||\&|\\} $inputdata {\\&} inputdata
	return $inputdata
}

# Hash-Support
set satmd_botnet(temp,crc32_loader) 0
catch {
	package require crc32
	set satmd_botnet(temp,crc32_loader) 1
}
if { $satmd_botnet(temp,crc32_loader) == 0 } {
	source "$satmd_botnet(basepath)/3rd_party_crc32.tcl"
	package require crc32
	putloglev "d" "*" "satmd_botnet: NOTICE: Upgrade your tcllib to at least 1.9     -- using provided preliminary 3rd_party_crc32.tcl"
} else {
	putloglev "d" "*" "satmd_botnet: Using provided crc32"
}
catch { unset satmd_botnet(temp,crc32_loader) }
proc satmd_botnet_hash_crc32 { inputdata } {
	return [string toupper [::crc::crc32 -format "%.8x" $inputdata]]
}

# support for recalculating minutes from a timespec -- v2

proc satmd_botnet_timespec2mins { input } {
	set duration 0
	set temporal 0
	foreach character [split $input {}] {
		switch -glob $character {
			[0-9] {
				# get rid of leading 0 if there is one
				if { $temporal == 0 } { set temporal $character } else { set temporal "${temporal}${character}" }
			}
			[sS] {
				set duration [expr $duration + 1]
				set temporal 0
			}
			[mM] {
				set duration [expr $duration + $temporal]
				set temporal 0
			}
			[hH] {
				set duration [expr $duration + $temporal * 60 ]
				set temporal 0
			}
			[dD] {
				set duration [expr $duration + $temporal * 1440]
				set temporal 0
			}
			[qQ] {
				set duration [expr $duration + $temporal * 129600]
				set temporal 0
			}
			[nN] {
				set duration [expr $duration + $temporal * 43200]
				set temporal 0
			}
			[yY] {
				set duration [expr $duration + $temporal * 525600]
				set temporal 0
			}
			[wW] {
				set duration [expr $duration + $temporal * 10080]
				set temporal 0
			}
			default {
				# unknown chars ignored
			}
		}
	}
	catch {
		set duration [expr $duration + $temporal]
	}
	return $duration
}

# various helper and wrappers (partially overriding alltools.tcl)
proc putctcp { target keyword } {
	putserv "PRIVMSG $target :\001$keyword\001"
}
proc putctcr { target keyword text } {
	putserv "NOTICE $target :\001[string toupper $keyword] $text\001"
}
proc putchan { target text } {
	putserv "PRIVMSG $target :$text"
}
proc putnotc { target text} {
	putserv "NOTICE $target :$text"
}

# errorhandling
proc bgerror { args } {
	set message [lindex $args 0]
	set level [info level]
	if { $level == 1 } {
		putloglev "d" "*" "bgerror: direct invocation!"
	} else {
		set level -1
	}
	set procname [lindex [info level $level] 0]
	set procarglist [lrange [info level $level] 1 end]
	set procargs ""
	foreach procarg $procarglist {
		lappend procargs "\"$procarg\""
	}
	set procargs [join $procargs]
	putloglev "d" "*" "bgerror: $procname { $procargs } -> '$message'"
}

# check if a regexp is valid
proc satmd_botnet_checkregexp { regexp } {
	set success 0
	catch {
		set dummy [regexp -nocase $regexp "some string to test"]
		set success 1
	}
	return $success
}

proc long2ip {long} {
  return [format "%d.%d.%d.%d" \
  [expr ($long >> 24) & 0xff] \
  [expr ($long >> 16) & 0xff] \
  [expr ($long >> 8) & 0xff] \
  [expr $long & 0xff]]
}

#returns a generic banmask and provides global support for proxy-like clients like mibbit.
#currently the value it returns is either the hex-ident (if "proxy") or just the host of the user
proc satmd_botnet_genericbanmask { nick uhost } {
	if { [satmd_botnet_isCGIClient $nick $uhost] } {
		return "*!*[string trimleft [lindex [split $uhost @] 0] ~]@*"
	}

	#default *!*@host
	return "*!*@[lindex [split $uhost @] 1]"
}

proc satmd_botnet_isCGIClient { nick uhost } {
	if {
	[regexp -- {-?[0-9a-f]{8}@.*} $uhost] &&
	(
	    [string match "*.mibbit.com" $uhost] ||
	    [string match "*.penya.de" $uhost] ||
	    [string match "*.majadon.com" $uhost] ||
	    [string match "*.dragonrage.de" $uhost] ||
	    [string match "*.webchat?.cc.euirc.net" $uhost] ||
	    [string match "*@178.63.1.euirc-76b3060f" $uhost] ||
	    [string match "*@176.9.29.euirc-2a32bdbb" $uhost] ||
	    [string match "*@87.98.242.euirc-*" $uhost] ||
	    [string match "*@207.192.75.euirc-e3e19d41" $uhost] ||
	    [string match "*@64.62.228.euirc-1938d731" $uhost] ||
	    [string match "*@78.129.202.euirc-f6e5607d" $uhost] ||
	    [string match "*@109.169.29.euirc-701a4bbb" $uhost]
	)
	} {
		return true
	}
	return false
}

#checks a given ip (not in reverse order) if it is listed on dronebl.org
#variable length of attributes can be given here
#the first argument is used as the callback function called like the normal way "dnslookup" do (with the attributes "realip hostname status")
#all other arguments are appended to the call
proc satmd_botnet_dronebl_check { ip args } {
  set ip [join [lreverse [split $ip .]] .]
  dnslookup "$ip.dnsbl.dronebl.org" satmd_botnet_dronebl_check_callback $args
}
proc satmd_botnet_dronebl_check_callback { realip hostname status original_callback } {
  catch { eval [linsert $original_callback 1 $realip $hostname $status] }
}


# Sucessful
set satmd_botnet(version,depends) "0.2.5"
return 1
