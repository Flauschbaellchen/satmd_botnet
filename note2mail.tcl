# module note2mail
satmd_botnet_require sendmail
#
# This module checks every 10 minutes for new notes for +n users
# Will only work if sendmail is in the correct place (link is ok) and
# the user has set a valid email address
# INFO: Beware! There is no backup of sent notes! Lost mail == lost note!
#

proc satmd_botnet_handle2mail { handle } {
	return [getuser $handle xtra email]
}

bind time -|- "*0 * * * *" satmd_botnet_note2mail_timer

proc satmd_botnet_note2mail_timer { a b c d e } {
	global botnick owner
	set counter 0
	set from "$botnick <[satmd_botnet_handle2mail $owner]>"
	foreach handle [userlist +n] {
		set target ""
		catch { set target [satmd_botnet_handle2mail $handle] }
		if { $target != "" } {
			while { [notes $handle] > 0 } {
			set thisnote [lindex [notes $handle 1] 0]
			set note_from [lindex $thisnote 0]
			set note_timestamp [ctime [lindex $thisnote 1]]
			set note_text [lindex $thisnote 2]
			satmd_botnet_sendmail $from $target "eggdrop note (from: $note_from)" "Timestamp: $note_timestamp\n$note_text"
			erasenotes $handle 1
			incr counter
		}
#		} else {
#			putloglev "d" "*" "satmd_botnet:note2mail $handle has no email adress
		}
	}
	if { $counter > 0 } {
		putloglev "d" "*" "notes2mail: Send $counter message(s)"
	}
}

set satmd_botnet(version,note2mail) "0.4"
return 1

