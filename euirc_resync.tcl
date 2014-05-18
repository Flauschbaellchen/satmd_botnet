# MODULE euirc_resync
#
# This module checks the bots opinion of channels for desyncs and tries to fix itself
#

# Make sure to prefix flags/procs/udefs/binds with satmd_botnet_ !
# listen is NOT handled yet!

bind time - "* * * * *" satmd_botnet_euirc_resync_time

proc satmd_botnet_euirc_resync_time { a b c d e } {
	global botnick
	foreach c in [chanlist] {
		set chanjoin -1
		set needresync 0
		catch {
			set chanjoin [getchanjoin $botnick $c]
		}
		if { $chanjoin < 100 || $chanjoin > [unixtime] } {
			set needresync 1
		}

		if { $needresync == 1 } {
			putloglev d "$c" "euirc_resync: I seem to be out of sync for channel $c, trying to sync up..."
			putserv "NAMES $c"
		}
	}
}

set satmd_botnet(version,template) "0.1"

return 1
