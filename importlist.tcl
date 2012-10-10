# MODULE importlist
#
# Read lists from files and provide matching
#

proc satmd_botnet_importlist_import { listname filename } {
	global satmd_botnet
	set satmd_botnet(importlist,lists,$listname) ""
	catch {
		set filehandle [open $filename r]
		while { ![eof $filehandle] } {
			gets $filehandle line
			if { $line != "" } {
				lappend satmd_botnet(importlist,lists,$listname) $line
			}
		}
		close $filehandle
	}
	putloglev "d" "*" "importlist.tcl: Built list $listname using [llength $satmd_botnet(importlist,lists,$listname)] item(s) from $filename"
}

foreach item [array names satmd_botnet "importlist,files,*"] {
	set itemname [join [lrange [split $item ","] 2 end] ","]
	satmd_botnet_importlist_import $itemname $satmd_botnet(importlist,files,$itemname)
}

set satmd_botnet(version,importlist) "0.2.1"

# succesful
return 1


