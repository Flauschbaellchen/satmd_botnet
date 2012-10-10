# MODULE whois
# usage: satmd_botnet_whois nick channel reverse_proc [list <place for more needed shit>]
# example: 
#         bind join - * reverse_whois
#         proc reverse_whois {nick uhost realname registered chanlist server away idle oper id info} {
#         putlog "$nick $uhost $realname $registered $chanlist $server $away $idle $oper $id $info"
#         }
# <place for more needed shit> is come back in your reverse_proc with $info
# $id is the id of the timer that will be remove the stored whois datas
# if nick is not on irc every value beside $nick will return -1
# values e.g. "$registered" "$oper" returns 0 (not opered,not registered) or 1 (opered,registered)


# we have one configuration variable
# this is the time in minutes how long storing whois datas
set satmd_botnet(whoissave,time) "5"



bind raw - "402" satmd_botnet_parse_whois
bind raw - "311" satmd_botnet_parse_whois
bind raw - "307" satmd_botnet_parse_whois
bind raw - "319" satmd_botnet_parse_whois
bind raw - "312" satmd_botnet_parse_whois
bind raw - "301" satmd_botnet_parse_whois
bind raw - "317" satmd_botnet_parse_whois
bind raw - "313" satmd_botnet_parse_whois
bind raw - "318" satmd_botnet_parse_whois


setudef flag "satmd_botnet_whois"

proc satmd_botnet_whois {nick reverse {infodata {}}} {
	global botnick
	global satmd_botnet
	set nick [string tolower $nick]
	if {[isbotnick $nick]} {
		return 0
	}
	if {[info exists satmd_botnet(whois,$nick,callbacks)]} {
		if { ![string match -nocase "*$reverse*" "$satmd_botnet(whois,$nick,callbacks)"] } {
			lappend satmd_botnet(whois,$nick,callbacks) [list $reverse $infodata]
		}
	} else {
		lappend satmd_botnet(whois,$nick,callbacks) [list $reverse $infodata]
	}
	if {[info exists satmd_botnet(whois,$nick,state)]} {
		if {$satmd_botnet(whois,$nick,state) == "1"} {
			after cancel [list "$satmd_botnet(whois,$nick,id)"]
			set satmd_botnet(whois,$nick,id) [after [expr 60000 * $satmd_botnet(whoissave,time)] [list satmd_botnet_whois_clear $nick]]
			set result(nick) $satmd_botnet(whois,$nick,nick)
			set result(uhost) $satmd_botnet(whois,$nick,uhost)
			set result(realname) $satmd_botnet(whois,$nick,realname)
			set result(registered) $satmd_botnet(whois,$nick,registered)
			set result(chanlist) $satmd_botnet(whois,$nick,chanlist)
			set result(server) $satmd_botnet(whois,$nick,server)
			set result(away) $satmd_botnet(whois,$nick,away)
			set result(idle) $satmd_botnet(whois,$nick,idle)
			set result(id) $satmd_botnet(whois,$nick,id)
			set result(state) $satmd_botnet(whois,$nick,state)
			set result(oper) $satmd_botnet(whois,$nick,oper)
			satmd_botnet_whois_callback [array get result]
			foreach item [array names result] {
				unset result($item)
			} 
			return 0
		}
		if {$satmd_botnet(whois,$nick,state) == "0"} {
			return 0
		}
	}
	set satmd_botnet(whois,$nick,away) ""
	set satmd_botnet(whois,$nick,registered) "0"
	set satmd_botnet(whois,$nick,oper) "0"
	set satmd_botnet(whois,$nick,state) "0"
	set satmd_botnet(whois,$nick,chanlist) { }
	puthelp "WHOIS $nick $nick"
}

proc satmd_botnet_parse_whois {from keyword argument} {
	global satmd_botnet
	set argument [split $argument \ ]
	set nick [string tolower [lindex $argument 1]]
	switch $keyword {
		402 {
			if {![info exists satmd_botnet(whois,$nick,callbacks)]} { 
				return 0 
			}
			set result(nick) $nick
			set result(uhost) -1
			set result(realname) -1
			set result(registered) -1
			set result(chanlist) {}
			set result(server) -1
			set result(away) -1
			set result(idle) -1
			set result(id) -1
			set result(state) -1
			set result(oper) -1
			satmd_botnet_whois_callback [array get result]
			foreach item [array names result] {
				unset result($item)
			} 
			return 0
		}
		311 {
			set satmd_botnet(whois,$nick,nick) "$nick"
			set satmd_botnet(whois,$nick,uhost) "[lindex $argument 3]"
			if { [string match "*\\**" $satmd_botnet(whois,$nick,uhost)] } {
				set satmd_botnet(whois,$nick,uhost) "invalid"
			}
			if { ![string match "*@*" $satmd_botnet(whois,$nick,uhost)] } {
				set satmd_botnet(whois,$nick,uhost) "[lindex $argument 2]@$satmd_botnet(whois,$nick,uhost)"
			}
			set satmd_botnet(whois,$nick,realname) "[lindex [split $argument :] 1]"
		}
		307 {
			set satmd_botnet(whois,$nick,registered) "1"
		}
		319 {
			foreach chan [split [lindex [split $argument :] 1]] {
				lappend satmd_botnet(whois,$nick,chanlist) "$chan"
			}
		}
		312 {
			set satmd_botnet(whois,$nick,server) "[lindex $argument 2]"
		}
		301 {
			set satmd_botnet(whois,$nick,away) "[lindex [split $argument :] 1]"
		}
		313 {
			set satmd_botnet(whois,$nick,oper) "1"
		}
		317 {
			set satmd_botnet(whois,$nick,idle) "[string range [lrange $argument 2 end] 1 end]"
		}
		318 {
			if {![info exists satmd_botnet(whois,$nick,registered)]} {
				return 0
			}
			set satmd_botnet(whois,$nick,id) [after [expr 60000 * $satmd_botnet(whoissave,time)] [list satmd_botnet_whois_clear $nick]]
			set satmd_botnet(whois,$nick,state) "1"
			set result(nick) $satmd_botnet(whois,$nick,nick)
			set result(uhost) $satmd_botnet(whois,$nick,uhost)
			set result(realname) $satmd_botnet(whois,$nick,realname)
			set result(registered) $satmd_botnet(whois,$nick,registered)
			set result(chanlist) $satmd_botnet(whois,$nick,chanlist)
			set result(server) $satmd_botnet(whois,$nick,server)
			# on some ircds this doesn't get set, because of message ordering -- satmd
			set result(away) ""
			catch {
				set result(away) $satmd_botnet(whois,$nick,away)
			}
			set result(idle) $satmd_botnet(whois,$nick,idle)
			set result(id) $satmd_botnet(whois,$nick,id)
			set result(state) $satmd_botnet(whois,$nick,state)
			set result(oper) $satmd_botnet(whois,$nick,oper)
			satmd_botnet_whois_callback [array get result]
			foreach item [array names result] {
				unset result($item)
			} 
			return 0
		}
	}
}

proc satmd_botnet_whois_clear {text} {
	global satmd_botnet
	after cancel [list "$satmd_botnet(whois,$text,id)"]
	foreach item [array names satmd_botnet "whois,$text,*"] {
		unset satmd_botnet($item)
	}
}

proc satmd_botnet_whois_callback {text} {
	global satmd_botnet
	foreach elem $text {
		if {[info exists elem_old]} {
			set $elem_old $elem
			unset elem_old
		} else { set elem_old $elem }
	}

	set chanlist_edit [split $chanlist]
	set chanlist ""
	foreach channel $chanlist_edit {
		lappend chanlist [regsub {^[%@+~*!&]*} $channel ""]
	}

	putloglev d "*" "$satmd_botnet(whois,$nick,callbacks)"
	foreach callback $satmd_botnet(whois,$nick,callbacks) {
		putloglev d "*" "callback: [lindex $callback 0]"
		[lindex $callback 0] $nick $uhost $realname $registered $chanlist $server $away $idle $oper $id [lindex $callback 1]
	}
	unset satmd_botnet(whois,$nick,callbacks)
}

#Successfull
set satmd_botnet(version,whois) "0.4"
return 1
