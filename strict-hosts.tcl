# MODULE strict-hosts
#
# Attempts to set hosts for handles in a way that makes
# strict-hosts irrelevant ... strict-hosts defaults to be enabled
# and is supposed to be removed in a next release.
# I hate eggheads decision on forcing this feature to 1.
# "identd is NOT a security feature and as such should never be relied on"
# That's why I'm counter-forcing the system to list hosts with and without ~
# This module will be OBLIGATORY from the moment I made it. period.
# -- satmd 2010/09/10

catch {
set repeat_me 1
while { $repeat_me == 1 } {
	set repeat_me 0
	set actions {}
	foreach u [userlist] {
		foreach h [getuser $u HOSTS] {
			set this_u [lindex [split $h !] 0]
			set this_ih [lindex [split $h !] 1]
			set this_i [lindex [split $this_ih @] 0]
			set this_h [lindex [split $this_ih @] 1]
			if { $this_u == "" || $this_i == "" || $this_h == "" } {
				#putloglev d "*" "User with empty nick!ident@host: $u $h"
				continue
			} elseif {
				[string match "*@*@*" $h] ||
				[string match "*!*!*" $h] } {
					#putloglev d "*" "User with broken host: $u $h"
					continue
			} elseif {
					[string index $this_i 0] == "*" ||
					[string index $this_i 0] == "?" } {
				continue
			} elseif { [string index $this_i 0] == "~" } {
				if { [string length $this_i] >=9 } {
					set new_i "[string range $this_i 1 8]?"
				} else {
					set new_i "[string range $this_i 1 8]"
				}
				if { [lsearch -exact $h "$this_u!$new_i@$this_h"] == -1 } {
					set actions [lappend actions [list $u "$this_u!$new_i@$this_h"]]
				}
			} else {
				if { [string length $this_i] >=9 } {
					set new_i "~[string range $this_i 0 8]"
				} else {
					set new_i "~$this_i"
				}
				if { [lsearch -exact $h "$this_u!$new_i@$this_h"] == -1 } {
					set actions [lappend actions [list $u "$this_u!$new_i@$this_h"]]
				}
			}
		}
	}
	foreach a $actions {
		set this_u [lindex $a 0]
		set this_h_new [lindex $a 1]
		set this_h [getuser $this_u HOSTS]
		if { [lsearch -exact $this_h $this_h_new] == -1 } {
			# the docs say: *1* host will be added
			setuser $this_u HOSTS $this_h_new
			putloglev d "*" "strict-hosts: User $this_u missing host $this_h_new"
			set repeat_me 1
		}
	}
}
}
unset repeat_me

set satmd_botnet(version,strict-hosts) "0.1"
