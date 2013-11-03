# MODULE update

# This is the NEW update.tcl, using SVN

if { ![info exists satmd_botnet(update_client)]} { set satmd_botnet(update_client) 0 }

bind bot -  "satmd_botnet_update" satmd_botnet_update_bot
bind dcc tn "satmd_botnet_update" satmd_botnet_update_dcc
bind dcc tn "satmd_botnet_rehash" satmd_botnet_update_dcc_rehash
bind dcc tn "satmd_botnet_version" satmd_botnet_update_dcc_version
bind bot -  "satmd_botnet_update_reply" satmd_botnet_update_reply

proc satmd_botnet_update_bot { frombot keyword text } {
	global satmd_botnet
	if { $text == "version" } {
		putbot $frombot "satmd_botnet_update_reply satmd_botnet_version:: [satmd_botnet_update_svnrevision]"
		return
	} elseif { $text == "rehash" } {
		satmd_botnet_update_rehash
	} else {
		putbot $frombot "satmd_botnet_update_reply Update request accepted."
		satmd_botnet_update_intern
	}
}

proc satmd_botnet_update_reply { frombot keyword text } {
	putloglev "do" "*" "satmd_botnet_update:: ${frombot} :> $text"
}

proc satmd_botnet_update_intern { } {
	global satmd_botnet
	set pipe [open "|/bin/sh" w+]
	fconfigure $pipe -blocking false -buffering none
	fileevent $pipe readable [list satmd_botnet_update_fileevent $pipe readable]
	fileevent $pipe writable [list satmd_botnet_update_fileevent $pipe writable]
	puts $pipe "cd \"$satmd_botnet(basepath)\"\n"
	puts $pipe "$satmd_botnet(update,command)\n"
	puts $pipe "exit\n"
	flush $pipe
	return 1
}

proc satmd_botnet_update_dcc { handle idx text } {
	putidx $idx "satmd_botnet: update initiated"
	if { $text == "" } {
		putallbots "satmd_botnet_update"
		satmd_botnet_update_intern
	} else {
		foreach bot [split $text] {
			putbot $bot "satmd_botnet_update"
		}
	}
}
proc satmd_botnet_update_dcc_rehash { handle idx text } {
	putallbots "satmd_botnet_update rehash"
}
proc satmd_botnet_update_dcc_version { handle idx text } {
	putallbots "satmd_botnet_update version"
}

proc satmd_botnet_update_fileevent { channel type } {
	switch $type {
		"readable" {
			if { [eof $channel] } {
				catch { close $channel }
				after 5000 [list satmd_botnet_update_rehash]
				putloglev d "*" "update.tcl: fileevent::close: $channel"
				return
			}
			gets $channel line
			putloglev d "*" "update.tcl: fileevent::read: $channel -> $line"
		}
		"writable" {
		}
		default {
			putloglev d "*" "update.tcl: fileevent::??: $type"
		}
	}
}

proc satmd_botnet_update_svnrevision { } {
	global satmd_botnet
	set version "UNKNOWN"
	catch {
		set version $satmd_botnet(version)
	}
	catch {
		set fileH [open "$satmd_botnet(basepath)/.svn/entries"]
		gets $fileH dummy
		gets $fileH dummy
		gets $fileH dummy
		set version "r[gets $fileH]"
		close $fileH
		unset fileH
	}
	return $version
}

proc satmd_botnet_update_rehash { } {
	global satmd_botnet
	set version [satmd_botnet_update_svnrevision]
	putloglev "d" "*" "satmd_botnet_update result: Updated to r$version"
	rehash
}

# Successful
set satmd_botnet(version,update) "0.7"
return 1

