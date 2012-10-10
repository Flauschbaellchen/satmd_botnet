# EXPERIMENTAL WORK - DO NOT USE

listen 3666 script satmd_botnet_irc_grab

proc satmd_botnet_ircemu_dcclist {} {
	global satmd_botnet
	set result ""
	foreach dcc [dcclist script] {
		set type [lindex $dcc 4]
		if { [string match "* satmd_botnet_irc_emulation" $type] } {
			if { $satmd_botnet(ircemu,[lindex $dcc 0],pass) == "1" } {
				lappend result [lindex $dcc 0]
			}
		}
	}
	return $result
}

proc satmd_botnet_irc_grab { newidx } {
	global satmd_botnet
	set satmd_botnet(ircemu,$newidx,idx) $newidx
	set satmd_botnet(ircemu,$newidx,pass) "0"
	control $newidx satmd_botnet_irc_emulation
}

proc satmd_botnet_irc_emulation { idx text } {
	global satmd_botnet
	if { $text == "" } {
		foreach item [array names satmd_botnet "ircemu,$idx,*"]	{
			unset satmd_botnet($item)
		}
		set source ""
		foreach dcc [dcclist] {
			if { [lindex $dcc 0] == $idx } { set source [lindex [split [lindex $dcc 2] @] 1] }
		}
		foreach oidx [satmd_botnet_ircemu_dcclist] {
			putidx $oidx ":bot NOTICE $satmd_botnet(ircemu,$oidx,nick) :*** User $satmd_botnet(ircemu,$idx,nick) disconnected from $source"
		}
	}	elseif { [string match -nocase "PASS muh" $text] } {
		set satmd_botnet(ircemu,$idx,pass) "1"
		catch { after del $satmd_botnet(ircemu,$idx,passwait) }
		catch { putidx $idx ":bot NOTICE $satmd_botnet(ircemu,$idx,nick) :*** Identification successful" }
			set source ""
			foreach dcc [dcclist] {
				if { [lindex $dcc 0] == $idx } { set source [lindex [split [lindex $dcc 2] @] 1] }
			}
		foreach oidx [satmd_botnet_ircemu_dcclist] {
			putidx $oidx ":bot NOTICE $satmd_botnet(ircemu,$oidx,nick) :*** User $satmd_botnet(ircemu,$idx,nick) connecting from $source"
		}
	} elseif { [string match -nocase "NICK *" $text] } {
		set satmd_botnet(ircemu,$idx,nick) [lindex [split $text] 1]
		putidx $idx ":bot 351 $satmd_botnet(ircemu,$idx,nick) eggdrop-BNC 0.0 bot"
		putidx $idx ":bot 001 $satmd_botnet(ircemu,$idx,nick) Hi there"
		putidx $idx ":bot 002 $satmd_botnet(ircemu,$idx,nick) Are you okay?"
		putidx $idx ":bot 003 $satmd_botnet(ircemu,$idx,nick) I am a bnc mode eggdrop"
		putidx $idx ":bot 004 $satmd_botnet(ircemu,$idx,nick) <place for more info>"
		putidx $idx ":bot 005 $satmd_botnet(ircemu,$idx,nick) CMDS=KNOCK MAXCHANNELS=20 NICKLEN=30 CHANNELLEN=30 TOPICLEN=255 KICKLEN=255 AWAYLEN=255 MAXTARGETS=20 WALLCOPS :are supported by this server"
		putidx $idx ":bot 005 $satmd_botnet(ircemu,$idx,nick) MODES=12 CHANTYPES=# PREFIX=(ohv)@%+ EXCEPTS INVEX NETWORK=eggdropBNC :are supported by this server"
		putidx $idx ":bot NOTICE $satmd_botnet(ircemu,$idx,nick) :*** You need to identify NOW..."
		set satmd_botnet(ircemu,$idx,passwait) [after 6000 [list satmd_botnet_ircemu_kill $idx]]
	} elseif { [string match -nocase "USER *" $text] } {
		# do nothing
	} elseif { [string match -nocase "PING *" $text] } {
		# do nothing
	} elseif { [string match -nocase "MODE $satmd_botnet(ircemu,$idx,nick) *" $text] } {
		# do nothing
	} elseif { $satmd_botnet(ircemu,$idx,pass) != "1" } {
		putidx $idx "ERROR: Authorization required"
		return 1
	} elseif { [string match -nocase "PRIVMSG *" $text] } {
		putserv $text
	} elseif { [string match -nocase "JOIN *" $text] } {
		set channellist [string trim [join [lrange [split $text] 1 end]]]
		foreach channel [split $channellist ,] {
			if { [validchan $channel ] } {
				putidx $idx ":$satmd_botnet(ircemu,$idx,nick) JOIN :$channel"
				foreach person [chanlist $channel] {
					set symbol ""
					if { [isop $person $channel] } { set symbol "@" }
					if { [ishalfop $person $channel] } { set symbol "%" }
					if { [isvoice $person $channel] } { set symbol "+" }
					putidx $idx ":bot 353 $satmd_botnet(ircemu,$idx,nick) = $channel :$symbol$person"
				}
				foreach person [chanlist $channel] {
					set symbol ""
					if { [isop $person $channel] } { set symbol "@" }
					if { [ishalfop $person $channel] } { set symbol "%" }
					if { [isvoice $person $channel] } { set symbol "+" }
				putidx $idx ":bot 352 $satmd_botnet(ircemu,$idx,nick) $channel [lindex [split [getchanhost $person]] 0] [string trim [lindex [split [getchanhost $person]] 1]] bot $person H$symbol :0 _"
				}
				putidx $idx ":bot 315 $satmd_botnet(ircemu,$idx,nick) $channel :End of /WHO list."
				putidx $idx ":bot 332 $satmd_botnet(ircemu,$idx,nick) $channel [topic $channel]"
			}
		}
	} elseif { [string match -nocase "TOPIC *" $text] } {
		putserv $text
	} elseif { [string match -nocase "KICK *" $text] } {
		putserv $text
	} elseif { [string match -nocase "BOT *" $text] } {
		catch { putidx $idx "RAW execution: [[lrange [split $text] 1 end]]" }
	}
#	putidx $idx ":bot NOTICE $satmd_botnet(ircemu,$idx,nick) :$satmd_botnet(ircemu,$idx,nick) $text"
	return 0
}

proc satmd_botnet_ircemu_kill { idx } {
	global satmd_botnet
	putidx ":bot NOTICE $satmd_botnet(ircemu,$idx,nick) :ERROR: Authorization required"
	after 2000 [list killdcc $idx]
	set source ""
	foreach dcc [dcclist] {
		if { [lindex $dcc 0] == $idx } { set source [lindex [split [lindex $dcc 2] @] 1] }
	}
	foreach oidx [satmd_botnet_ircemu_dcclist] {
		putidx $oidx ":bot NOTICE $satmd_botnet(ircemu,$oidx,nick) :*** User $satmd_botnet(ircemu,$idx,nick) did not authorized (was disconnected) from $souce"
	}
}

bind pubm - "*" satmd_botnet_irc_fetch_pub
proc satmd_botnet_irc_fetch_pub { nick uhost handle channel text } {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		putidx $idx ":$nick!$uhost PRIVMSG $channel :$text"
	}
}

bind join - "*" satmd_botnet_irc_fetch_join
proc satmd_botnet_irc_fetch_join {nick uhost handle channel } {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		putidx $idx ":$nick!$uhost JOIN :$channel"
	}
}
bind part - "*" satmd_botnet_irc_fetch_part
proc satmd_botnet_irc_fetch_part {nick uhost handle channel text } {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		if { $text == "" } {
			putidx $idx ":$nick!$uhost PART $channel :$text"
		} else {
			putidx $idx ":$nick!$uhost PART $channel :$text"
		}
	}
}
bind sign - "*" satmd_botnet_irc_fetch_quit
proc satmd_botnet_irc_fetch_quit { nick uhost handle channel text } {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		if { $text == "" } {
			putidx $idx ":$nick!$uhost PART $channel :QUIT:"
		} else {
			putidx $idx ":$nick!$uhost PART $channel :QUIT: $text"
		}
	}
}

bind mode - "*" satmd_botnet_irc_fetch_mode
proc satmd_botnet_irc_fetch_mode { nick uhost handle channel mc victim} {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		if { $victim == "" } {
			putidx $idx ":$nick!$uhost MODE $channel $mc"
		} else {
			putidx $idx ":$nick!$uhost MODE $channel $mc $victim"
		}
	}
}

bind msgm - "*" satmd_botnet_irc_fetch_msgm
proc satmd_botnet_irc_fetch_msgm { nick uhost handle text } {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		putidx $idx ":$nick!$uhost PRIVMSG $satmd_botnet(ircemu,$idx,nick) :$text"
	}
}

bind notc - "*" satmd_botnet_irc_fetch_notc
proc satmd_botnet_irc_fetch_notc { nick uhost handle target text } {
	global satmd_botnet
	set target1 $target
	foreach idx [satmd_botnet_ircemu_dcclist] {
		if { ![string match "#*" $target1] } { set target1 $satmd_botnet(ircemu,$idx,nick) }
		putidx $idx ":$nick!$uhost NOTICE $target :$text"
	}
}

bind kick - "*" satmd_botnet_irc_fetch_kick
proc satmd_botnet_irc_fetch_kick { nick uhost handle channel target reason} {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		putidx $idx ":$nick!$uhost KICK $channel $target :$reason"
	}
}

bind topc - "*" satmd_botnet_irc_fetch_topc
proc satmd_botnet_irc_fetch_topc { nick uhost handle channel text} {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		putidx $idx ":$nick!$uhost TOPIC $channel :$text"
	}
}

bind nick - "*" satmd_botnet_irc_fetch_nick
proc satmd_botnet_irc_fetch_nick { nick uhost handle channel newnick } {
	global satmd_botnet
	foreach idx [satmd_botnet_ircemu_dcclist] {
		putidx $idx ":$nick!$uhost NICK $newnick"
	}
}
set satmd_botnet(version,ircemu) "0.1"
#Successfull
return 1
