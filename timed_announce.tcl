# MODULE timed_announce
#
# This module will add a configureable list of timed announces
# the list is done via settings.tcl, but the enabling/disabling
# is done via .chanset
#

setudef str "satmd_botnet_announces"

bind time -|- "*" satmd_botnet_timed_announce_timer

proc satmd_botnet_timed_announce_timer { minute hour day month year } {
	global satmd_botnet
	set currtime [expr int(${hour}.0 * 60 + ${minute}.0)]
	foreach c [channels] {
		set announces [channel get $c "satmd_botnet_announces" ]
		if { $announces != "" } {
#			catch {
				foreach announce [split $announces] {
					set announce_list [split $announce ":"]
					set announce_id [lindex $announce_list 0]
					set announce_timelist [split [lindex $announce_list 1] "+"]
					putloglev "d" "*" "announce? $announce"
					set announce_mod [lindex $announce_timelist 0]
					set announce_offset [lindex $announce_timelist 1]
#					catch {
						if { [expr $currtime % $announce_mod] == $announce_offset } {
							putchan $c "$satmd_botnet(timed_announce,$announce_id)"
						}
#					}
				}
#			}
		}
	}
}

set satmd_botnet(version,timed_announce) "0.3"

return 1
