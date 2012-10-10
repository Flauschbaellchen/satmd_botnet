# MODULE regexp_bans
#
# Search through the (local-) banlist and match $nick!$uhost against &R: regexp-bans and ban the user if needed
# Works only on nickchange/join
# All bans will be in form of *!*@$host width a timeline of 1h
#

bind join - "*" satmd_botnet_regexp_bans_join
bind nick - "*" satmd_botnet_regexp_bans_nick

proc satmd_botnet_regexp_bans_join { nick uhost handle channel } {
	satmd_botnet_regexp_bans "$nick!$uhost" $channel
}

proc satmd_botnet_regexp_bans_nick { nick uhost handle channel newnick } {
	if { $channel != "*" } {
		satmd_botnet_regexp_bans "$newnick!$uhost" $channel
	}
}

proc satmd_botnet_regexp_bans { mask channel } {
	set nick "[lindex [split $mask !] 0]"
	set banmask [satmd_botnet_genericbanmask $nick [lindex [split $mask !] 1]]
	foreach bban [banlist $channel] {
		set ban_mask [lindex $bban 0]
		set ban_comment [lindex $bban 1]
		set ban_author [lindex $bban 5]
		if { [string match -nocase "&R:*" $ban_mask] } {
			set ban_realmask [string range $ban_mask 3 end]
			set success 0
			catch {
				if { [regexp -nocase $ban_realmask $mask] } {
					newchanban $channel $banmask $ban_author "$ban_comment \[$nick\]" 60
				}
				set success 1
			}
				if { $success == 0 } {
					putloglev "1" "*" "regexp_ban.tcl WARNING: broken regex $ban_mask"
				}
		}
	}
	foreach bban [banlist] {
		set ban_mask [lindex $bban 0]
		set ban_comment [lindex $bban 1]
		set ban_author [lindex $bban 5]
		if { [string match "&R:*" $ban_mask] } {
			set ban_realmask [string range $ban_mask 3 end]
			set success 0
			catch {
				if { [regexp -nocase $ban_realmask $mask] } {
					newban $banmask $ban_author "$ban_comment \[$nick\]" 60
				}
				set success 1
			}
			if { $success == 0 } {
				putloglev "1" "*" "regexp_ban.tcl: WARNING: broken regex $ban_mask"
			}
		}
	}
}

#Successfull
set satmd_botnet(version,regexp_bans) "0.4.2"
return 1
