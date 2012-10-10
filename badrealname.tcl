# MODULE badrealname
# this module will whois all users which join a channel where +satmd_botnet_whois is set
# if the user's realname match against a &G: ban he will be kicked out and banned


satmd_botnet_require "whois"
satmd_botnet_require "gban"

bind join - * satmd_botnet_badrealname

proc satmd_botnet_badrealname {nick uhost hand channel} {
	global satmd_botnet
	if {[channel get $channel "satmd_botnet_whois"] == 1} {
		satmd_botnet_whois $nick satmd_botnet_badrealname_check
	}
}

proc satmd_botnet_badrealname_check {nick uhost realname registered chanlist server away idle oper id info} {
	global botnick
	global satmd_botnet
	set hand [nick2hand $nick]
	set banmask [satmd_botnet_genericbanmask $nick $uhost]
	foreach bban [banlist] {
		set ban_mask [lindex $bban 0]
		set ban_comment [lindex $bban 1]
		set ban_author [lindex $bban 5]
		if { [string match -nocase "[matchsafe [striprep [lindex $bban 0]]]" "&G:[striprep $realname]!*@*"] } {
			satmd_botnet_gban_add $banmask "1d" "badrealname@$botnick" $botnick "user $nick removed for bad realname" 1
			catch {
				satmd_botnet_report $satmd_botnet(report,target) "$nick!$uhost/$hand triggered a whois:badrealname to $botnick ($realname)"
			}
		}
	}
}

#Successfull
set satmd_botnet(version,badrealname) "0.3.2"
return 1
