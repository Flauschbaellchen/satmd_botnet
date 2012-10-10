# MODULE version
#
# Needed in order to reply to .satmd_botnet_version [all]
#

bind bot - "satmd_botnet_version" satmd_botnet_version_bot
bind bot - "satmd_botnet_version2" satmd_botnet_version2_bot

proc satmd_botnet_version_bot { from keyword text } {
	global satmd_botnet
	global version
	set text [string tolower [split $text]]
	if { [matchattr $from $satmd_botnet(flag)] } {
		if { $text == "all" } {
			foreach ver [array names satmd_botnet] {
				if { [string match "version,*" $ver] } {
					set tmodule [lindex [split $ver ,] 1]
					putbot $from "satmd_botnet_version2 module $tmodule: $satmd_botnet($ver)"
				}
			}
		}
		putbot $from "satmd_botnet_version2 $satmd_botnet(version) ($satmd_botnet(v_stamp)) (TCL: [info tclversion], eggdrop: $version)"
		putloglev "db" "*" "satmd_botnet:version $from asked for version info"
	} else {
		putloglev "db" "*" "satmd_botnet:version $from asked for version info but was denied (no flags)"
	}
}

proc satmd_botnet_version2_bot { from keyword text } {
	putloglev "db" "*" "satmd_botnet_version: $from $text"
}

bind dcc n|- "satmd_botnet_version" satmd_botnet_version_dcc

proc satmd_botnet_version_dcc { hand idx text } {
	global botnick
	set text [string tolower [split $text]]
	global satmd_botnet
	global version
	putidx $idx "Acquiring versions..." 
	if { $text == "all" } {
		foreach ver [array names satmd_botnet] {
			if { [string match "version,*" $ver] } {
				set tmodule [lindex [split $ver ,] 1]
				putloglev "db" "*" "satmd_botnet_version: $botnick module $tmodule: $satmd_botnet($ver)"
			}
		}
	}
	putloglev "db" "*" "satmd_botnet_version: $botnick $satmd_botnet(version) ($satmd_botnet(v_stamp)) (TCL: [info tclversion], eggdrop: $version)"
	foreach tbot [bots] {
#		if { [matchattr $tbot $satmd_botnet(flag)] } {
			putbot $tbot "satmd_botnet_version $text"
#		}
	}
}

# Successful
set satmd_botnet(version,version) "0.2"
return 1


