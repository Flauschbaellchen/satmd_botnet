# MODULE nickserv
#
# This module interfaces NickServ
# NickServ is a common means of nick registration.
# for each nick to identify, you need to add
#  set satmd_botnet(nickserv,password,*NICK*) "*PASSWORD*"
# to settings.tcl
#
# NOTE: If you use this script standalone, you can add the setting to *any*
#       script file, including nickserv.tcl itself or eggdrop's config
#

bind notc -|- "*This nickname is registered*" satmd_botnet_nickserv_identify_notc
bind notc -|- "*Dieser Chatname ist registriert*" satmd_botnet_nickserv_identify_notc
#bind notc -|- "*nickname*not registered*" satmd_botnet_nickserv_identify_notc

bind time -|- "00 20 * * *" satmd_botnet_nickserv_notify_timed

bind dcc m|m "satmd_botnet_lastidentify" satmd_botnet_nickserv_lastidentify

proc satmd_botnet_nickserv_identify_notc { nick uh hand text dest } {
	global botnick satmd_botnet
	set pw ""
	catch { set pw $satmd_botnet(nickserv,password,$botnick) }
	if { [string match $satmd_botnet(nickserv,nickserv) "$nick!$uh"] && ($pw != "") } {
		putquick "PRIVMSG NickServ :IDENTIFY $pw" "-next"
		putloglev "d" "*" "satmd_botnet:nickserv IDENTIFYing for $botnick"
	}
	set satmd_botnet(nickserv,lastident,$botnick) [unixtime]
	return 1
}

proc satmd_botnet_nickserv_notify_timed { a b c d e } {
	global satmd_botnet botnick
	# this proc forcibly tries an identify to overcome stupid euirc's
	# services that will drop ANY nick that hasn't identified for too 
	# long even though the nick is ONLINE.
	set nickserv $satmd_botnet(nickserv,nickserv)
	set nick [lindex [split $nickserv !] 0]
	set uhost [lindex [split $nickserv !] 1]
	satmd_botnet_nickserv_identify_notc $nick $uhost "*" "This is a fscking workaround for euIRC" $botnick
	set satmd_botnet(nickserv,lastident,$botnick) [unixtime]
}

proc satmd_botnet_nickserv_lastidentify { from idx text } {
	global botnick satmd_botnet
	set lastidentify "(before we loaded this script or never)"
	catch {
		set lastidentify [ctime $satmd_botnet(nickserv,lastident,$botnick)]
	}
	putidx $idx "The bot last identified to nick $botnick at $lastidentify"
}

# Successfull
set satmd_botnet(version,nickserv) "0.2.1"
return 1
