# MODULE sendmail

# This module will handle outgoing mail

proc satmd_botnet_sendmail { mfrom mto msubject mbody } {
	set fs [open "|/usr/sbin/sendmail $mto" w]
	puts $fs "From: $mfrom"
	puts $fs "Subject: $msubject"
	puts $fs "To: $mto\n"
	puts $fs $mbody
	catch { close $fs }
}

# Successfull
set satmd_botnet(version,sendmail) "0.3"
return 1
