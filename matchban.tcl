# MODULE matchban
#
#### This script will search through the banlist for entries which matches your mask or the $nick!$uhost of the nick you specified
#### Also the script has got a self-synchronisation of channel bans which were manual set so they can be included in your search because eggdrop ignores those bans in [banlist $chan]
#
# Public/Dcc/Msg/Notc all the same:
# ($trigger)matchban <mask/nick> [-global] [-local] [-all] [-standalone] [-regexp] [-channels channel1 [channel2] [channel3] ...]
#
# Only users with nG|G will be able to use it.
#
# Flags:
# -global      : Search through the global banlist
# -local       : Search through the local banlist
# -channels    : List of channels seperated by spaces which should be searched
# -all         : If you want the output how many bans which aren't activ yet exists you can enable this (now this is specified as default)
# -active      : Show only bans which have been active yet
# -standalone  : If specified no requests will be send to other bots in the botnet
# -regexp      : if the mask should be a regexp string
#
# Default flags are -global -local -all -botnet
#
#
# To make the bot response to public channel-requests you need to set +satmd_botnet_matchban
#
# All replies will go out where you have requested them (msg->msg and so on)
#
#
# Synchronisation of manual channel bans will be happen every rehash - also automatically if the bot will join a channel
# The script will try to fetch banreasons by kicks for this banlist
#
#### Script by Noxx, irc.euirc.net if there are any questions, bugs or suggestions :)

bind pub  nG|G "$satmd_botnet(cmdchar)matchban" satmd_botnet_matchban_pub
bind msg  nG   "matchban"                       satmd_botnet_matchban_msg
bind notc nG   "matchban*"                      satmd_botnet_matchban_notc
bind dcc  nG   "matchban"                       satmd_botnet_matchban_dcc
bind bot  -|-  "matchban_request"               satmd_botnet_matchban_bot_request
bind bot  -|-  "matchban_result"                satmd_botnet_matchban_bot_result

bind raw   -  "367"                             satmd_botnet_matchban_banlist_parse
bind raw   -  "368"                             satmd_botnet_matchban_banlist_parse
bind evnt "*" rehash                            satmd_botnet_matchban_banlist_rehash
bind mode  -  "* -b"                            satmd_botnet_matchban_banlist_bandel
bind mode  -  "* +b"                            satmd_botnet_matchban_banlist_banadd

setudef flag "satmd_botnet_matchban"

satmd_botnet_require whois

# set up splitted binds to one
proc satmd_botnet_matchban_pub { nick uhost handle channel text } {
	if { ![channel get $channel "satmd_botnet_matchban"] } { return }
	satmd_botnet_matchban "pub:$channel:$nick" $text 1
}

proc satmd_botnet_matchban_msg { nick uhost handle text } {
	satmd_botnet_matchban "msg:$nick:$nick" $text 1
}

proc satmd_botnet_matchban_notc { nick uhost handle text {dest ""}} {
	set text [split $text]
	set text [lrange $text 1 end]
	satmd_botnet_matchban "notc:$nick:$nick" $text 1
}

proc satmd_botnet_matchban_dcc { hand idx text } {
	satmd_botnet_matchban "dcc:$idx:$hand" $text 1
}

# botrequest trigger
proc satmd_botnet_matchban_bot_request { frombot keyword text } {
#	if { [matchattr $frombot "G"] } {
		set text [split $text]
		satmd_botnet_matchban "bot:$frombot:$frombot:[lrange $text 0 2]" [lrange $text 3 end] 0
#	}
}

proc satmd_botnet_matchban_bot_result { frombot keyword text } {
#	if { [matchattr $frombot "G"] } {
		set text [split $text]
		satmd_botnet_matchban_reply "[lindex $text 0]:[lindex $text 1]:[lindex $text 2]" [join [lrange $text 3 end] " "]
#	}
}

## set up search query
proc satmd_botnet_matchban { action text forward } {

	if { $text == "" } { return }

	#display requester
	set requester [lindex [split $action :] 2]
	if { [lindex [split $action :] 0] != "bot" } {
		putloglev "o" "*" "<<$requester>> ![nick2hand $requester]! matchban: $text"
	} else {
		set nick [lindex [split [lindex [split $action :] 3]] 2]
		putloglev "o" "*" "<<$nick@$requester>> !$nick@[nick2hand $requester]! matchban: $text"
	}

	set text [split $text]
	set banmask [lindex $text 0]
	set options [lrange $text 1 end]

	if { $forward == 1 && ![regexp -nocase -- {-botnet} $options] && ![regexp -nocase -- {-standalone} $options] } {
		set options [string trim "$options -botnet"]
	}

	if { [regexp -nocase -- {-regexp} $options] || [regexp -all {[@.*!%+:]} $banmask] > 0 } {
		satmd_botnet_matchban_search $action [matchsafe $banmask] $options
	} else {
		# searching for specific nick
		satmd_botnet_whois $banmask satmd_botnet_matchban_nick [list "$action" "$options"]
	}
}

# if requested banmask was a nick get the $nick!$uhost information
proc satmd_botnet_matchban_nick { nick uhost realname registered chanlist server away idle oper id info } {
	if { (!("$uhost" == "-1")) } {
		satmd_botnet_matchban_search [lindex $info 0] [matchsafe "$nick!$uhost"] [lindex $info 1]
	} else {
		satmd_botnet_matchban_reply [lindex $info 0] "$nick already disconnected from the server or has changed nick."
	}
}

# main program to get all entries
proc satmd_botnet_matchban_search { action banmask options } {
	global botnick
	global satmd_botnet

	# small spamfilter, if a +G user made a request in a botnet-channel more than usefull bots will response to him if he got +G on more than one bot
	# ignore same requests within 5 seconds
	if { [info exists satmd_botnet(matchban,banlist,request,$banmask)] } { return 0 }
	set satmd_botnet(matchban,banlist,request,$banmask) 1
	after 5000 [list unset satmd_botnet(matchban,banlist,request,$banmask)]


	#nothing found yet, isn't it?
	set foundlasttime -1

	set action [split $action :]
	#default options
	if { ![regexp -nocase -- {-local} $options] && ![regexp -nocase -- {-global} $options] } {
		set options [string trim "$options -local -global"]
	}

	if { ![regexp -nocase -- {-active} $options] && ![regexp -nocase -- {-all} $options] } {
		set options [string trim "$options -all"]
	}

	#if lasttime ist specified get it done, specially for botrequests so we won't get any replys twice or more, standard is -1 to include bans which was never active yet ($lasttime = 0)
	set lasttime -1
	if { [regexp -nocase -- {-lasttime} $options] } {
		regexp -nocase -- {([0-9]+)} $options lasttime
		# set lasttime plus 5 seconds due to lag while adding bans, I don't think we will lose/ignore any bans by doing this
		set lasttime [expr $lasttime + 5]
	}


	# 0 hostmask
	# 1 comment
	# 2 expiration timestamp
	# 3 time added
	# 4 last time active
	# 5 creator
	# 6 channel
	# 7 bantype


	#search through active banlist in all channels
	if { ![info exists satmd_botnet(matchban,banlist)] } { set satmd_botnet(matchban,banlist) "" }

	foreach banline $satmd_botnet(matchban,banlist) {
		#check if the bot got the channel in the intern channellist otherwise it was deleted and we should stop here and continue with the next one
		if { ![validchan [lindex $banline 6]] } { continue }
		#ignore if bot is not onchan and thus the banlist is not uptodate
		if { ![botonchan [lindex $banline 6]] } { continue }
		#ignore this channel due to restrictions?
		if { ![regexp -nocase -- {-global} $options] } {
			if { [lsearch $options "-channels"] && ![lsearch $options "-channels *[lindex $banline 6]"] } { continue }
		}
		# working between catch { } so we don't get a tcl error if we run into defect regexp-code
		catch {
			if {
				(
					(![regexp -nocase -- {-regexp} $options] && ([string match -nocase [matchsafe [lindex $banline 0]] $banmask] || [string match -nocase $banmask [lindex $banline 0]]))
					|| ([regexp -nocase -- {-regexp} $options] && [regexp -nocase -- $banmask [lindex $banline 0]])
				)
				&& $lasttime < [lindex $banline 4] && 
				(
					[regexp -nocase -- {-global} $options] || ![lsearch [lindex $banline 7] "global"]
				)
			} {
				#entry found, add to list, set key to "lastactive_timeadded" to be able to order it later
				set searchresults([lindex $banline 4][lindex $banline 3]) $banline
				if { $foundlasttime < [lindex $banline 4] } { set foundlasttime [lindex $banline 4] }
			}
		}
	}


	#after saved all active bans, look up if there are other bans which are in the intern banlist but aren't active
	if { [regexp -nocase -- {-global} $options] } {
		# global search
		foreach banline [banlist] {
			#if we run into a ban which is active ignore it... really bad workaround but don't have any other ideas
			set break 0
			foreach activebanline $satmd_botnet(matchban,banlist) {
				if { [lindex $activebanline 0] == [lindex $banline 0] } { set break 1; break }
			}
			if { $break } { continue }

			# working between catch { } so we don't get a tcl error if we run into defect regexp-code
			catch {
				if {
					(
						(![regexp -nocase -- {-regexp} $options] && ([string match -nocase [matchsafe [lindex $banline 0]] $banmask] || [string match -nocase $banmask [lindex $banline 0]]))
						|| ([regexp -nocase -- {-regexp} $options] && [regexp -nocase -- $banmask [lindex $banline 0]])
						|| ([string match -nocase "&R:*" [lindex $banline 0]] && [regexp -nocase -- [string range [lindex $banline 0] 3 end] $banmask])
					)
					&& $lasttime < [lindex $banline 4] && 
					(
						[lindex $banline 4] != "0"
						|| [regexp -nocase -- {-all} $options]
					)
				} {
					#entry found, add to list, set key to "lastactive_timeadded" to be able to order it later
					if { [lindex $banline 4] != 0 } {
						set searchresults([lindex $banline 4][lindex $banline 3]) [lappend banline "" "global"]
						if { $foundlasttime < [lindex $banline 4] } { set foundlasttime [lindex $banline 4] }
					} else {
						set neverused([lindex $banline 4][lindex $banline 3]) [lappend banline "" "global"]
					}
				}
			}
		}
	}

	if { [regexp -nocase -- {-local} $options] || [regexp -nocase -- {-channels} $options] } {
		# local search
		foreach channel [channels] {
			if { [lsearch $options "-channels"] && ![lsearch $options "-channels *$channel"] } { continue }
			foreach banline [banlist $channel] {
				#if we run into a ban which is active ignore it... really bad workaround but don't have any other ideas
				set break 0
				foreach activebanline $satmd_botnet(matchban,banlist) {
					if { [lindex $activebanline 0] == [lindex $banline 0] } { set break 1; break }
				}
				if { $break } { continue }

				# working between catch { } so we don't get a tcl error if we run into defect regexp-code
				catch {
					if {
						(
							(![regexp -nocase -- {-regexp} $options] && ([string match -nocase [matchsafe [lindex $banline 0]] $banmask] || [string match -nocase $banmask [lindex $banline 0]]))
							|| ([regexp -nocase -- {-regexp} $options] && [regexp -nocase -- $banmask [lindex $banline 0]])
							|| ([string match -nocase "&R:*" [lindex $banline 0]] && [regexp -nocase -- [string range [lindex $banline 0] 3 end] $banmask])
						)
						&& $lasttime < [lindex $banline 4] && 
						(
							[lindex $banline 4] != "0"
							|| [regexp -nocase -- {-all} $options]
						)
					} {
						#entry found, add to list, set key to "lastactive_timeadded" to be able to order it later
						if { [lindex $banline 4] != 0 } {
							set searchresults([lindex $banline 4][lindex $banline 3]) [lappend banline "$channel" "local"]
							if { $foundlasttime < [lindex $banline 4] } { set foundlasttime [lindex $banline 4] }
						} else {
							set neverused([lindex $banline 4][lindex $banline 3]) [lappend banline "$channel" "local"]
						}
					}
				}
			}
		}
	}

	if { [lindex $action 0] != "bot" && [regexp -nocase -- {-botnet} $options] } {
		# our most recent timestamp - we wouldn't like to get any replies twice, do we?
		set options [string trim "$options -lasttime $foundlasttime"]
		putallbots "matchban_request [lindex $action 0] [lindex $action 1] [lindex $action 2] $banmask $options"
	}


	# break up if this was made by botrequest and nothing was found
	if { [lindex $action 0] == "bot" && [array size searchresults] == 0 && [array size neverused] == 0 } {
		return 1
	}

	# otherwise put out the results:

	set i 0
	set more " - More:"
	# botname? yeay, just 'cause it's looks better :)
	if { [lindex $action 0] == "bot" } {
		set person_i $botnick
		set person_my $botnick
	} else {
		set person_i "I"
		set person_my "My"
	}

	# 0 hostmask
	# 1 comment
	# 2 expiration timestamp
	# 3 time added
	# 4 last time active
	# 5 creator
	# 6 channel
	# 7 bantype
	foreach entry [lsort -decreasing [array names searchresults]] {
		if { [lindex $searchresults($entry) 7] != "global" } { set bantype "[lindex $searchresults($entry) 7]/[lindex $searchresults($entry) 6]" } else { set bantype [lindex $searchresults($entry) 7] }
		if { [string length [lindex $searchresults($entry) 6]] > 0 } { set lastactive ", still on [lindex $searchresults($entry) 6]" } else { set lastactive "" }

		if { $i == 0 } {
			lappend mostrecententry "$person_my most recent entry is ([lindex $searchresults($entry) 0]) Bantype:($bantype/[lindex $searchresults($entry) 5]) Created:([clock format [lindex $searchresults($entry) 3] -format "%d-%m-%Y at %H:%M:%S"]) Lastactive:([clock format [lindex $searchresults($entry) 4] -format "%d-%m-%Y at %H:%M:%S"]$lastactive) Reason:([lindex $searchresults($entry) 1])." 
		} else {
			lappend mostrecententry "$more ($bantype/[lindex $searchresults($entry) 5] [lindex $searchresults($entry) 0])"
			set more ""
		}
		if { $i >= 2 } { break }
		set i [expr $i + 1]
	}

	if { [array size neverused] > 0 } {
		set i 0
		foreach entry [lsort -decreasing [array names neverused]] {
		if { [lindex $neverused($entry) 7] != "global" } { set bantype "[lindex $neverused($entry) 7]/[lindex $neverused($entry) 6]" } else { set bantype [lindex $neverused($entry) 7] }
			if { $i == 0 } {
				lappend mostrecententry " Additionally $person_i got [array size neverused] entrie(s) which were never active: ($bantype/[lindex $neverused($entry) 5] [lindex $neverused($entry) 0])" 
			} else {
				lappend mostrecententry " ($bantype/[lindex $neverused($entry) 5] [lindex $neverused($entry) 0])"
			}
			if { $i >= 2 } { break }
			set i [expr $i + 1]
		}
	}

	# if nothing was found
	lappend mostrecententry ""
	set result "$person_i got [array size searchresults] hit(s). [join $mostrecententry ""]"

	set destination [lindex $action 1]
	switch [lindex $action 0] {
		bot { putbot $destination "matchban_result [lindex $action 3] $result" }
		default { satmd_botnet_matchban_reply "[lindex $action 0]:[lindex $action 1]:[lindex $action 2]" $result }
	}
}


proc satmd_botnet_matchban_reply { destination text } {
	set destination [split $destination :]
	switch [lindex $destination 0] {
		pub { puthelp "PRIVMSG [lindex $destination 1] :[lindex $destination 2], $text" }
		notc { putnotc [lindex $destination 1] "[lindex $destination 2], $text" }
		msg { puthelp "PRIVMSG [lindex $destination 1] :[lindex $destination 2], $text" }
		dcc { putidx [lindex $destination 1] "[lindex $destination 2], $text" }
		default { }
	}
}



###################
# now here comes the code to get a synchronisation of the local banlist of each channel
###################

proc satmd_botnet_matchban_banlist_rehash { evnt } {
	#rehash? maybe we run into some trouble so refresh the banlist - just to be sure it's not THIS script which makes the trouble ;)
	global satmd_botnet
	set satmd_botnet(matchban,banlist) ""
	foreach channel [channels] {
		if { ![botonchan $channel] } { continue }
		puthelp "mode $channel b"
	}
}

proc satmd_botnet_matchban_banlist_parse { from keyword text } {
	global satmd_botnet
	set text [split $text]
	switch $keyword {
		367 {
			satmd_botnet_matchban_banlist_add [lindex $text 3] "-" [nick2hand [lindex $text 3]] [lindex $text 1] "+b" [lindex $text 2] [lindex $text 4]
		}
	}
}

proc satmd_botnet_matchban_banlist_bandel { nick uhost handle channel mode target } {
	global satmd_botnet
	if { ![info exists satmd_botnet(matchban,banlist)] } {
		set satmd_botnet(matchban,banlist) ""
		return 0
	}
	set temp ""
	foreach banline $satmd_botnet(matchban,banlist) {
		if { [lindex $banline 0] == $target && [lindex $banline 6] == $channel } { continue }
		lappend temp $banline
	}
	set satmd_botnet(matchban,banlist) $temp
}

proc satmd_botnet_matchban_banlist_banadd { nick uhost handle channel mode target } {
	satmd_botnet_matchban_banlist_add $nick $uhost $handle $channel $mode $target [clock seconds]
}

proc satmd_botnet_matchban_banlist_add { nick uhost handle channel mode target utime } {
	#luckely, we just need to append the new ban to the banlist
	global satmd_botnet
	# 0 hostmask
	# 1 comment
	# 2 expiration timestamp
	# 3 time added
	# 4 last time active
	# 5 creator
	# 6 channel
	# 7 bantype
	if { ![isban $target] && ![isban $target $channel] } {
		lappend satmd_botnet(matchban,banlist) "$target {-manual ban-} 0 $utime $utime {$nick} $channel {manual}"
	} else {
		# global search
		if { [isban $target] } {
			foreach banline [banlist] {
				if { [lindex $banline 0] == $target } {
					lappend satmd_botnet(matchban,banlist) "$target {[lindex $banline 1]} [lindex $banline 2] [lindex $banline 3] $utime [lindex $banline 5] $channel {global}"
				}
			}
		}
		if { [isban $target $channel] } {
			foreach banline [banlist $channel] {
				if { [lindex $banline 0] == $target } {
					lappend satmd_botnet(matchban,banlist) "$target {[lindex $banline 1]} [lindex $banline 2] [lindex $banline 3] $utime [lindex $banline 5] $channel {local}"
				}
			}
		}
	}
}


#horrible workaround to get the bans deleted if the bot was parting the channel due to kick/ban/+inactive or whatever. bind on * part is not really a good idea I think
#also it's a solution to get it one more time synchronised if there is an error ;)
#uncommented because we don't really need this, do we?

#bind time -|- "00 18 * * *" satmd_botnet_matchban_banlist_rehash


set satmd_botnet(version,matchban) "0.2"
return 1

