########################################################################
#  satmd_botnet.tcl : eggdrop enhancements by satmd                    #
#  License   : GPL 2                                                   #
#  (formerly known as botnet.tcl)                                      #
#  version see in satmd_botnet_init                                    #
########################################################################
#
# CHANGELOG
#
# 0.1
#  - Versionsnummern eingefhrt
#  - putctcp und putctcr programmiert
# 0.2
#  - alle Funktionen haben jetzt Prefix satmd_
#  - Channelflag mustjoin eingefhrt 
# 0.2b
#  - mustjoin funktioniert erst ab eggdrop 1.6.15, deshalb Versionskontrolle
# 0.3
#  - gban wurde reorganisiert und doppelter code entfernt
# 0.3b
#  - Zwei Typos in der gban.dcc-Funktion wurden korrigiert
# 0.3c
#  - Kleiner Logikfehler in mustjoin, der unn�ige Bans setzt, wurde beseitigt
# 0.4
#  - Bug in der Versions-Prfung beseitigt
# 0.5
#  - Schoenheitsfehler ;D im gban-teil des scripts
# 0.6
#  - chanserv-unban funktionert jetzt auch, wenn der Bot nen vhost hat
# 0.7
#  -chanserv-invite funktioniert jetzt auch, wenn der Bot nen vhost hat
#  -!mustjoin fr %,@ fr erzwingen von mustjoin z.B. nach netsplit
# 0.7b
#  - kleiner Kosmetikfehler korrigiert
# 0.8
#  - Statt chanmode +b wird jetzt (wieder) newchanban benutzt. 
#    Vorteil: es k�nen mehr als 60 bans pro channel gesetzt werden.
#    ACHTUNG: wenn der Bot nicht max-bans und max-modes 60 in euIRC hat, kommts
#             zu Problemen. In eggdrop v1.6.1x ist dazu ein Patch in den Quellen
#             notwendig, wegen eines Bugs! 
# 0.9 
#  - Hinzufgen von isadmin und botisadmin analog zu isop und botisop,
#    allerdings auf TCL-Ebene (dev)
# 0.9.1
#  - <GBAN> unsichtbar, stattdessen NOTICE an Ausl�er
# 0.9.2
#  - Transfer von banhelper (CS UNBAN support)
# 0.10.0
#  - Neue Funktion stripcontrolcodes (reverse/bold/color/...) fr
#    Filterung von IRC-Steuercodes in TCL
# 0.11.0
#  - GBAN nur noch fr User mit +nGN oder +G #channel
# 0.11.1
#  - gban add/del aktualisiert MysqlDB (wenn vorhanden) [DEFECTIVE]
# 0.12.0
#  - Korrekturen in chanspam/queryspam-Erkennung
#  - Korrektur der Benennung von gban.tcl -> botnet.tcl (logging)
#  - Korrektur putidx -> putcmdlog
# 0.12.1
# - Patch in satmd_euirc_modeRAW (fehler bei der erkennung von {,},[,]
# 0.12.5
#  - mgban [v] [<reason>] geadded (massgban auf alle statuslosen bzw.
#    statuslose + voice user
# 0.12.6
#  - kein GBAN auf * oder *!*@*  ;D
# 0.12.7
#  - chanserv-protect => kompatibilit� mit anopeservices+unrealircd
# 0.13.0
#  - antihopper-delay: gban fr Leute, die nur fr <x Sekunden im channel sind
# 0.13.1
#  - Namenskorrektur in satmd_issecured
# 0.13.2
#  - gunban funktionierte nicht, wenn der bot nicht im channel war
# 0.13.3
#  - gban wirkt nun exakt 14 Tage ... danach wird er gel�cht. Somit verhindern
#    wir, dass der Bot an Bans berl�ft ;)
#    Dieser Wert ist konfigurierbar, 0=> endlos
# 0.13.4
#  - gban wird nicht mehr gemeldet, wenn der betreffende Ban bereits existiert
# 0.14.0
#  - in gban kann man fuer einzelne hostmasks andere bandauern einstellen
#  - Bessere Inline-Doku
# 0.15.0
#  - Korrektur in der Doku
#  - flag cycle-interval (int) erzwingt ein rejoinen des Bots im Channel 
#    (on-join-spam-Erkennung)
# 0.15.1
#  - Aehnlich zu antihopper-delay nun ein antirejoin-delay (rejoins)
# 0.15.2
#  - Aehnlich dazu ein antijoinspam-delay, das *www* und *http* nach join verbietet
# 0.15.3
#  - antijoinspam-delay gilt nicht mehr fr op und halfop aber erkennt nun auch *#*
# 0.15.4
#  - fehler in antijoinspam, antirejoin, antihopper: bug im handling von mehreren channeln
# 0.15.5
#  - gban und gunban setzen +/-b direkt bei aufruf
# 0.20.0
#  - Source-Code komplett berarbeitet und in Teil-Scripte zerlegt [ACTIVE]
# 0.21.0
#  - banhelper patched in killban
# 0.22.0
#  - Namensbereiche der udef aufger�mt, einheitliches satmd_botnet_*
#  - alte werte werden NICHT bernommen!
# 0.22.5
#  - Neues Modul: notes2mail. Sendet notes fuer owner per 
#    sendmail an eine eingetragene email-addy.
# 0.23.0
#  - Neue Module: opcontrol und nickserv
# 0.23.1
#  - Code aufgeraeumt ;)
# 0.23.2
#  - Arcor und adsl.hansenet.de in exception liste fuer gban
#    aufgenommen
#  - neues Modul: noxdcccatcher (alpha)
# 0.24.0
#  - Altes gban-system neu organisiert mit folgenden Neuerungen
#  - Syntax geaendert (siehe gban.tcl)
#  - Interoperatibiltaet mit andern Botnet-Mastern verabredet
#  - Nicht abwaertskompatibel, daher die bot-trigger umbenannt nach "gban"
# 0.24.1
#  - Neue Module report (satmd_botnet_report ziel@bot text) und
#    securebotlinks (unbekannte bots werden nicht akzeptiert, betroffene
#    bots werden unlink'ed und botattr +r (reject)
# 0.24.2
#  - Typo korrigiert
# 0.24.5
#  - gban.tcl has requirements on Tcl 8.4 or something like that...
#    ... we use strings is integer!
# 0.25.0
#  - gban.tcl added support for trojan url handling
# 0.25.1
#  - antijoinspam.tcl: now handling messages split by spaces.
#      This effectively allows us to exempt #<number> from detection.
# 0.26.0
#  - floodreact.tcl: initial import
# 0.27.0
#  - update.tcl, init.tcl: implementing basepath support (automatic means of detecting the script's path e.g. for multi-instance installations)
# 0.28.0
#  - gban.tcl: completely redesign satmd_botnet_issecureban, it now works based on % of hits it would cause to channels and/or globally
#              also implemented .testgban, dcc .+/.-gban
# 0.28.1
#  - matchsafe in *.tcl: string match recognizes \[ZEICHENLISTE\] which
#    we do not want for matching bans 
# 0.28.2
# 0.28.3
#  - interim fixing update.tcl (version change to verify update works)
# 0.29.0
#  - some minor changed to the importlist code, also added white/blacklist-support to antijoinspam (please see defaults.tcl)
# 0.30.0
#  - disabling internal use of update.tcl, version used to denote users' switching
#
# current:
#  - gban allows nicks to be used, transformed to *@host
#
# notes:
#  - gban=>+b is working not efficiently, allowing intruders to use a 
#    large timehole, thus disabling this
#
# INFO: Zur Zeit ist die aktive Weiterentwicklung auf meiner Seite
#       eingestellt, neue Implementierungen werden noch angenommen
#
########################################################################

# sources 
proc satmd_botnet_include { includedef } {
	global satmd_botnet
	set result 0
	catch { set result [source "$satmd_botnet(basepath)/${includedef}.tcl"] }
	if { $result == 0 } {
		putloglev "db" "*" "satmd_botnet: could not load $includedef: $result"
		catch {
			unset satmd_botnet(version,$includedef)
		}
		return 0
	} else {
		if { [info exist satmd_botnet(version,$includedef)] } {
			putloglev "d" "*" "satmd_botnet: module $includedef ($satmd_botnet(version,$includedef))"
		} else {
			putloglev "d" "*" "satmd_botnet: module $includedef"
		}
		return 1
	}
}

proc satmd_botnet_require { includedef } {
	global satmd_botnet
	if { ![info exist satmd_botnet(version,$includedef)] } {
		putloglev "db" "*" "satmd_botnet: INFO: module $includedef required, but not yet loaded - automatically loading now"
		satmd_botnet_include "$includedef"
	}
	return $satmd_botnet(version,$includedef)
}

# INITIALIZE SCRIPT
proc satmd_botnet_init { } {
	global satmd_botnet
#
# VERSION
#########################################################
	set satmd_botnet(version) "0.31.0"
	set satmd_botnet(v_stamp) "Jun 29th, 2009 19:14 CEST"
#########################################################
#
	foreach binddef [binds] {
		set type  [lindex $binddef 0]
		set flags [lindex $binddef 1]
		set param [lindex $binddef 2]
		set count [lindex $binddef 3]
		set tproc [lindex $binddef 4]
		if { [string match "satmd_botnet_*" $tproc]} {
			unbind $type $flags $param $tproc
		}
	}
	foreach var [array names satmd_botnet] { 
		putloglev d "*" "satmd_botnet: removing old value $var"
		if { ($var != "version") && ($var != "v_stamp")} {
			catch { unset satmd_botnet($var) }
		}
	}
	set satmd_botnet(basepath) "[file dirname [info script]]"
	satmd_botnet_include "defaults"
	satmd_botnet_include "settings"
	satmd_botnet_include "depends"
	satmd_botnet_include "version"
	set satmd_botnet(modules,active) ""
	foreach module $satmd_botnet(modules) {
		if { [satmd_botnet_include $module] } { lappend satmd_botnet(modules,active) $module }
	}
	# required default modules, might find better solutions later
	satmd_botnet_include "matchban"
	satmd_botnet_include "strict-hosts"
	putlog "satmd_botnet $satmd_botnet(version) loaded, modules: [join $satmd_botnet(modules,active)]"
}
putloglev "d" "*" "satmd_botnet: INIT"
satmd_botnet_init
putloglev "d" "*" "satmd_botnet: INIT complete"
putloglev "d" "*" "satmd_botnet: version: $satmd_botnet(version)"
putloglev "d" "*" "satmd_botnet: v_stamp: $satmd_botnet(v_stamp)"
putloglev "d" "*" "satmd_botnet: running on TCL [info tclversion]"
putloglev "d" "*" "satmd_botnet: basepath: $satmd_botnet(basepath)"
putloglev "db" "*" "satmd_botnet scripts loaded"
