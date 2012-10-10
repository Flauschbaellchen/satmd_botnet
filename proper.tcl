# module proper - depricated
#
# proper and bot info about channels
# usage: .proper <#channel>

bind dcc - "proper" satmd_botnet_proper


proc satmd_botnet_proper {hand idx text} {
	set chan [lindex $text 0]
	foreach pban [banlist] {
		set ban [lindex $pban 0]
		set reason [lindex $pban 1]
		set duration [lindex $pban 2]
		if {[string match -nocase "[matchsafe [lindex $pban 0]]" "&P:$chan!*@*"]} {
			regsub -all -- {-- gban} $reason "" reason
			putlog "$chan $reason"
			return 0
		}
	}
	putlog "$chan no properinfo found"
}

# Sucessful
putloglev "db" "*" "satmd_botnet:proper.tcl is depricated due to no use of this module."
set satmd_botnet(version,proper) "0.2"
return 1
