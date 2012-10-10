# MODULE banhelper
#
# In case of having ChanServ on your network, this will delete any internal bans in the bot matching an -b set by ChanServ
#

bind mode - "% -b" satmd_botnet_unban_modehelper

proc satmd_botnet_unban_modehelper { nick uhost handle channel modechange victim } {
	if  { ( [string tolower $nick] == "chanserv" ) || ( $nick == "" ) } {
		if { [matchban $victim $channel] == 1 && [matchban $victim] == 0 } {
			catch { killchanban $channel $victim }
			catch { killban $victim }
			putloglev "d" "*" "botnet.tcl: unban_modehelper: removing ban for $victim due to mode -b on $channel by $nick!$uhost"
		}
	}
}

# Successful
set satmd_botnet(version,banhelper) "0.1.1"
return 1