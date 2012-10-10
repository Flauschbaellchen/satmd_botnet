# MODULE maxpatch
#
# This module is designed for some error in eggdrop <1.6.16
# It simply forgets its settings.
#

bind evnt -|- rehash satmd_botnet_rehash_event

# React on rehash
proc satmd_botnet_rehash_event { type } {
	global max-bans max-modes max-exempts max-invites
	set max-bans 60
	set max-modes 60
	set max-exempts 60
	set max-invites 60
}

# Successful
set satmd_botnet(version,maxpatch) "0.2"
return 1