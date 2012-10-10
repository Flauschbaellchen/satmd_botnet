# MODULE badchannel
# this module will whois all users which join a channel where +satmd_botnet_whois is set
# if the user's channellist will match a &C:#channel ban he will be kicked out and banned.

satmd_botnet_require "whois"
satmd_botnet_require "gban"

bind join - * satmd_botnet_badchannel

proc satmd_botnet_badchannel {nick uhost hand channel} {
	global satmd_botnet
	if {[channel get $channel "satmd_botnet_whois"] == 1} {
		satmd_botnet_whois $nick satmd_botnet_badchannel_check
	}
}

proc satmd_botnet_badchannel_check {nick uhost realname registered chanlist server away idle oper id info} {
	global botnick
	global satmd_botnet
	set hand [nick2hand $nick]
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	foreach bban [banlist] {
		set ban_mask [lindex $bban 0]
		set ban_comment [lindex $bban 1]
		set ban_author [lindex $bban 5]
		foreach chan $chanlist {
			if { [string match -nocase "[matchsafe [lindex $bban 1]]" "&C:$chan!*@*"] } {
				satmd_botnet_gban_add $banmask "1d" "badchannel@$botnick" $botnick "user $nick found in badchannel" 1
				catch { satmd_botnet_report $satmd_botnet(report,target) "$nick$banmask/$hand triggered a whois:badchannel to $botnick ($chan)" }
			}
		}
	}
}

#Successfull
set satmd_botnet(version,badchannel) "0.2.2"
return 1
