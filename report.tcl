# MODULE report
#
# this module will simply report something somewhere
#
# Note: Target is bot:#channel or #channel
#       multiple space-separated targets allowed
#

satmd_botnet_require logging

setudef flag "satmd_botnet_report_flood"

proc satmd_botnet_report { targets text } {
	global botnick
	foreach target [split $targets] {
		catch {
			if { [string match "*:*" $target] } {
				set newtarget [lindex [split $target :] 1]
				set bot [lindex [split $target :] 0]
				putbot $bot "satmd_botnet_report $botnick $newtarget $text"
			} else {
				putserv "PRIVMSG $target :$botnick:$text"
			}
		}
	}
	catch {
		satmd_botnet_log * $text
	}
	return 0
}

bind bot - "satmd_botnet_report" satmd_botnet_report_bot
proc satmd_botnet_report_bot { from command text } {
	global satmd_botnet
	set text [split $text]
	set source [lindex $text 0]
	set target [lindex $text 1]
	set message "[join [lrange $text 2 end]]"
	putserv "PRIVMSG $target :$from:$message"
	putloglev d1 * "satmd_botnet:report: $from ==> $message"
}

bind flud - "*" satmd_botnet_report_flud

proc satmd_botnet_report_flud { nick uhost hand type chan } {
	global satmd_botnet
	if { ![channel get $chan "satmd_botnet_report_flood"] } { return 0 }
	satmd_botnet_report $satmd_botnet(report,target) "satmd_botnet:flood $nick!$uhost/$hand triggered a flood:$type on $chan"
	return 0
}

set satmd_botnet(version,report) "0.3"

return 1
