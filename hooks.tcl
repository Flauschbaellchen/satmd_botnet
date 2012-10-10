# MODULE hooks
#
# Provides hook-system
#

proc satmd_botnet_hooks_register { type procname } {
	global satmd_botnet
	set satmd_botnet(hooks,$type,$procname) 1
}

proc satmd_botnet_hooks_unregister { type procname } {
	global satmd_botnet
	catch { unset satmd_botnet(hooks,$type,$procname) }
}

proc satmd_botnet_hooks_call { type } {
	global satmd_botnet
	foreach item [array names satmd_botnet hooks,$type,*] {
		set procname [lindex [split $item ,] end]
		putloglev "d" "*" "hook.tcl: calling $procname of type $type from level [info level]"
		catch {
			uplevel 1 [info body $procname]
		}
	}
}

proc satmd_botnet_hooks_debug { } {
	putloglev "d" "*" "hook.tcl: debug hook invoked"
	putloglev "d" "*" "hook.tcl: $reason"
}

#Example: satmd_botnet_hooks_register gban_dcc_add satmd_botnet_hooks_debug

set satmd_botnet(version,hooks) "0.1"
return 1
