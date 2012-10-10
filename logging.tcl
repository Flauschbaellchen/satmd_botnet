# MODULE logging
#
# This module provides logging infrastructure
#
# Example
#	set satmd_botnet(logging) {
#		log {
#			destination broadcast;
#		}
#		log {
#			source user g0d;
#			substitute "(.*)g0d(.*)" "\$1d3v1l\$1"
#			destination privmsg #logchannel;
#		}
#		log {
#			source bot godzilla;
#			match wildcard "*stupid*spammessage*";
#			destination notice Killbot;
#		}
#		log {
#			source proctree "*::satmd_botnet_gban";
#			destination putloglev 8 *;
#		}
#	}

bind bot -|- "satmd_botnet_log" satmd_botnet_logging_bot

proc satmd_botnet_logging_bot { frombot command text } {
	satmd_botnet_log "bot:$frombot" "$text"
}

bind dcc tnmo|- "log" satmd_botnet_logging_dcc

proc satmd_botnet_logging_dcc { handle idx text } {
	satmd_botnet_log "user:$handle" $text
}

proc satmd_botnet_log { logsource logmessage } {
	global satmd_botnet
	set leveltree ""
	for { set i 1 } { $i < [info level] } { incr i } {
		set leveltree "::[lindex [info level $i] 0]${leveltree}"
	}
	if { $logsource == "*" } {
		putloglev d "*"  "leveltree: $leveltree";
		set logsource "proctree:$leveltree"
	}

	set i [interp create -safe]
	interp alias $i break {} satmd_botnet_interp_break $i
	interp alias $i log {} satmd_botnet_interp_log $i $logsource $logmessage
	interp alias $i source {} satmd_botnet_interp_source $i
	interp alias $i destination {} satmd_botnet_interp_destination $i
	interp alias $i substitute {} satmd_botnet_interp_substitute $i
	interp alias $i match {} satmd_botnet_interp_match $i
	interp alias $i eval {} satmd_botnet_interp_eval $i
	catch {
		interp eval $i $satmd_botnet(logging)
	}
}
proc satmd_botnet_interp_break { i args } {
	return -code error
}

proc satmd_botnet_interp_log { i logsource logmessage logexpr } {
	catch { 
		interp eval $i $logexpr
	}
}
proc satmd_botnet_interp_source { i args } {
	set args_limit [llength $args] 
	upvar logsource logsource
	switch [lindex $args 0] {
		"user" {
			set breaker 1
			for { set index 1 } { $index < $args_limit } { incr index} {
				if { [string match "user:[lindex $args $index]" $logsource] } {
					set breaker 0
				}
			}
			if { $breaker == 1 } {
				interp eval $i break;
			}
		}
		"userflag" {
			if { ( [lindex [split $logsource :] 0] != "user") && ([lindex [split $logsource :] 0] != "bot") &&
				(![matchattr [lindex $args 1] [lindex [split $logsource :] 1]]) } {
				interp eval $i break;
			}
		}
		"bot" {
			set breaker 1
			for { set index 1 } { $index < $args_limit } { incr index} {
				if { [string match "bot:[lindex $args $index]" $logsource] } {
					set breaker 0
				}
			}
			if { $breaker == 1 } {
				interp eval $i break;
			}
		}
		"proctree" {
			set leveltree ""
			for { set i 0 } { $i < [info level] } { incr i } {
				set leveltree "::[lindex [info level $i] 0]${leveltree}"
			}
			set breaker 1
			for { set index 1 } { $index < $args_limit } { incr index} {
				if { [string match "proctree:[lindex $args $index]" $logsource] } {
					set breaker 0
				}
			}
			if { $breaker == 1 } {
				interp eval $i break;
			}
		}
		default {
				#puts "--- UNKNOWN: $args"
		}
	}
}

proc satmd_botnet_interp_destination {i args } {
	upvar logmessage logmessage
	switch [lindex $args 0] {
		"loglevel" -
		"putloglvl" {
			putloglev [lindex $args 1] [lindex $args 2] $logmessage
		}
		"broadcast" {
			putallbots "satmd_botnet_log $logmessage"
		}
		"bot"	{
			putbot [lindex $args 1] "satmd_botnet_log $logmessage"
		}
		"privmsg" {
			putserv "PRIVMSG [lindex $args 1] :$logmessage"
		}
		"notice" {
			putserv "NOTICE [lindex $args 1] :$logmessage"
		}
		"raw" -
		"server" {
			putquick "$logmessage"
		}
		"debug" {
			putloglev d * $logmessage
		}
		default {
			#puts "--- UNKNOWN: $args"
		}
	}
}

proc satmd_botnet_interp_substitute { i args } {
	upvar logmessage logmessage
	set newmessage [lindex $args 1]
	set indice 0
	foreach regmatch [regexp -inline [lindex $args 0] $logmessage] {
		set newmessage [regsub -all "\\\$$indice" $newmessage $regmatch]
		incr indice
	}
	set logmessage $newmessage
}

proc satmd_botnet_interp_match { i args } {
	upvar logmessage logmessage
	switch [lindex $args 0] {
		"regex" -
		"regexp" {
			if { ![regexp [lindex $args 1] $logmessage] } {
				interp $i break;
			}
		}
		"wildcard" {
			if { ![string match [lindex $args 1] $logmessage] } {
				interp $i break;
			}
		}
		default {
			if { ![string match [lindex $args 0] $logmessage] } {
				interp $i break;
			}
		}
	}
}

proc satmd_botnet_interp_eval { i args } {
	upvar logmessage logmessage
	upvar logsource logsource
	catch {
		if { [llength $args] == 1 } {
			set logmessage [[lindex $args 0] $logmessage]
		} else {
			set replacement [subst [lindex $args 1]]
			set logmessage [regsub -all [lindex $args 0] $logmessage $replacement]
		}
	}
}

set satmd_botnet(version,logging) "0.1"

return 1
