# MODULE debug

proc debug { args } {
	set current [info level]
	while { $current >= 0 } {
		putloglev d "*" "TRACE: $current -> [info level $current]"
		incr current -1
	}
}

# Success
set satmd_botnet(debug.version) "0.1"
return 1
