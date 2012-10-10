# MODULE invites
#
# allow userdefined binds for invites.
# Yeah, ugly as hell :/
# I hope they implement it as a proper bind
# If someone has this as a module, CONTACT ME!
#

proc satmd_botnet_invite_bind { flags mask cproc } {
	global satmd_botnet
	lappend satmd_botnet(invites,binds) [list $flags $mask $cproc]
}

proc satmd_botnet_invite_unbind { flags mask cproc } {
	global satmd_botnet
	set tmp ""
	foreach cbind $satmd_botnet(invites,binds) {
		if { $cbind != [list $flags $mask $cproc } {
			lappend tmp $cbind
		}
	}
	set satmd_botnet(invites,binds) $tmp
}

bind raw - INVITE satmd_botnet_invites_raw
proc satmd_botnet_invites_raw {from word arg} {
	global satmd_botnet
	set bar [split $from "!"]
	set nick [lindex $bar 0]
	set foo [split $arg ":"]
	set name [lindex $foo 0]
	set chan [lindex $foo 1]
	set uhost [lindex $bar 1]
	foreach cbind $satmd_botnet(invites,binds) {
		putloglev "d" "*" "debug :$cbind"
		if { [matchattr [nick2hand $nick] $flags $chan] && [string match $mask $chan] } {
			catch { $cproc $nick $uhost [nick2hand $nick] $chan }
		}
	}
	return 0
}

# Success
set satmd_botnet(version,invites) "0.1"
return 1
