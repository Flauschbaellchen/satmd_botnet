# MODULE anticgiirc
#
# This module will check joins for cgi:irc style ips in the
# ident and will ban for excessive hits
# will set a +b on the ident
# will add a default gban on the host at 1d
#

satmd_botnet_require gban
setudef int satmd_botnet_anticgiirc_limit

bind join - "*" satmd_botnet_anticgiirc_join

proc satmd_botnet_anticgiirc_join { nick uhost handle channel } {
	set setting [channel get $channel "satmd_botnet_anticgiirc_limit"]
	if { $setting == 0 } { return 0 }
	set ident [lindex [split $uhost @] 0]
	set hits 0
	set bans ""
	if { (![string match "~\[a-f0-9\]\[a-f0-9\]\[a-f0-9\]\[a-f0-9\]\[a-f0-9\]\[a-f0-9\]\[a-f0-9\]\[a-f0-9\]" $ident]) } {
		return 0
	}
	regsub -all "~" $ident "" ident
	foreach user [chanlist $channel] {
		set user_uhost [getchanhost $user]
		set user_ident [lindex [split ${user_uhost} @] 0]
		set user_host [lindex [split ${user_uhost} @] 1]
		if {[string match "~$ident" ${user_ident} ] ||
			[string match "$ident" ${user_ident} ] } {
			set user_banmask "*!*@${user_host}"
			incr hits
			if { [lsearch bans $user_banmask] == 0 } {
				lappend bans $user_banmask
			}
		}
	}
	if { $hits >= $setting } {
		if { [llength $bans] >= $setting } {
			pushmode $channel "+b" "*!*$ident@*"
			putloglev "d" "*" "anticgiirc.tcl: CGI:IRC flood detected ($hits), banning $bans"
			foreach ban $bans {
				satmd_botnet_gban_add "$ban" "1d" "anticgiirc@$botnick" "$botnick" "CGI:IRC abuse detected" 1
			}
		}
	}
	return 0
}

set satmd_botnet(version,anticgiirc) "0.3"

return 1
