# MODULE antijoinspam
# Depricated! Use antispam.tcl instead.
#
# This module defines some strings NOT TO SPEAK directly after joining a channel
#

satmd_botnet_require gban
satmd_botnet_require importlist
setudef int "satmd_botnet_antijoinspam_delay"

bind pubm -|- "*"  satmd_botnet_antijoinspam_pubm
bind notc -|- "*"  satmd_botnet_antijoinspam_notc

proc satmd_botnet_antijoinspam_pubm { nick uhost handle channel text} {
	satmd_botnet_antijoinspam_handler $nick $uhost $handle $text $channel
}

proc satmd_botnet_antijoinspam_notc { nick uhost handle text dest} {
	satmd_botnet_antijoinspam_handler $nick $uhost $handle $text $dest
}

proc satmd_botnet_antijoinspam_handler { nick uhost handle text channel} {
	set doban 0
	set delay -1
	set chanjoin -1
	if { ([string index $channel 0] != "#") } { return 0}
	global botnick satmd_botnet
	catch {
		set chanjoin [getchanjoin $nick $channel]
		set delay [expr [unixtime] - $chanjoin]
	}
	if { $chanjoin <= 0 || $chanjoin > [unixtime] } { 
		putloglev "d" "$channel" "BUG in antijoinspam.tcl: impossible case of chanjoin:$chanjoin and unixtime:[unixtime]"
		return 0 
	}
	if { ($delay < [channel get $channel "satmd_botnet_antijoinspam_delay"]) } {
		if { [isop $nick $channel] || [ishalfop $nick $channel] || [matchattr $handle "mnolfb|mnolfb" $channel] } {
			set doban 2
			return 0
		}
		# 0=undefined, 1=yes, 2=no
		foreach listentry $satmd_botnet(importlist,lists,gban_whitelist) {
			if { [string match $listentry $text] } {
				set doban 2
				break
			}
		}
		if { $doban == 0 } {
			putloglev "d" "*" "antijoinspam.tcl: no whitelist hit, so checking blacklist"
			foreach listentry $satmd_botnet(importlist,lists,gban_blacklist) {
				if { [string match $listentry $text] } {
					set doban 1
					break
				}
			}
		}
	}
	if { $doban == 1 } {
		set banmask [satmd_botnet_genericbanmask $nick $uhost]
		satmd_botnet_gban_add $banmask "15d" "antijoinspam@$botnick" $botnick "user $nick removed for join+spam" 1
		putloglev d $channel "botnet.tcl:antijoinspam: user $nick removed for join+spam"
		return 0
	}
}

# Sucessful
putloglev "db" "*" "satmd_botnet:antijoinspam.tcl is depricated! Use antispam.tcl instead!"
set satmd_botnet(version,antijoinspam) "0.5.3"
return 1
