# MODULE ctcphelper
#
# Implements /ctcp request and reply as tcl bindings
#

# putctcp
proc putctcp { target keyword } {
	putserv "PRIVMSG $target :\001$keyword\001"
}

# putctcr
proc putctcr { target keyword text } {
	putserv "NOTICE $target :\001[string toupper $keyword] $text\001"
}

# Successful
set satmd_botnet(version,ctcphelper) "0.1"
return 1