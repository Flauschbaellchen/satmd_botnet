# Module enforcebanhelper
#
# provides help against known spambots or -users when enforceban is off for some reason
# kicks users matching against a global ban but leaves users there if not
#

bind mode - "% +b" satmd_botnet_enforcebanhelper
setudef flag "satmd_botnet_enforcebanhelper"

proc satmd_botnet_enforcebanhelper { nick uhost handle channel modechange victim } {
	global satmd_botnet

	if { ([channel get $channel "satmd_botnet_enforcebanhelper"] == 1) && ([channel get $channel "enforcebans"] == 0) } {
		foreach banentry [banlist] {
			if { [string match -nocase $victim [lindex $banentry 2]] } {
				foreach user [chanlist $channel] {
					if { [getchanhost $user]!="" && [matchban $user![getchanhost $user]] && ![isbotnick $user]} {
						catch { putkick $channel $user "[lindex $banentry 2]" }
						#putloglev "d" "*" "enforcebanshelper-kick... [getchanhost $user] - [matchban $user![getchanhost $user]] - $user"
					}
				}
			}
		}
	}
}

# Successful
set satmd_botnet(version,enforcebanhelper) "0.1.1"
return 1
