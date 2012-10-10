# MODULE customtriggers
#
# Allows for customized short triggers
#

proc satmd_botnet_customtrigger_pubm { nick uhost handle channel text } {
	global satmd_botnet
	set parameters [split $text]
	set trigger [lindex $parameters 0]
	set parameter_count 0
	foreach fragment $parameters {
		set parameter${parameter_count} [lindex $parameters ${parameter_count}]
		incr parameter_count
	}
	set answers $satmd_botnet(customtrigger,trigger,$trigger)
	set answer [string trim [lindex $answers [rand [llength $answers]]]]
	regsub -all -- {[\[\]\"\';:]} $answer {\\&} answer_evaluatable
	catch {
		putserv [join [eval list ${answer_evaluatable}]]
	}
	putloglev 1 "*" "customtriggers: activated $trigger: $answer"
	return	
}

foreach trigger [array names satmd_botnet "customtrigger,trigger,*"] {
	set trigger_name [join [lrange [split $trigger ,] 2 end] ,]
	putloglev 1 "*" "customtriggers: initializing ${trigger_name}"
	bind pubm -|- "% ${trigger_name}" satmd_botnet_customtrigger_pubm
	bind pubm -|- "% ${trigger_name} *" satmd_botnet_customtrigger_pubm
}

set satmd_botnet(version,customtriggers) "0.1"

return 1
