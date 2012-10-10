# MODULE sqlite3
#
# This is just a dependency loader
#
package require sqlite3

set satmd_botnet(version,sqlite3) "0.1"
foreach item [array names satmd_botnet "sqlite3,db,*"] {
	set key [lindex [split $item ,] end]
	set value $satmd_botnet($item)
	sqlite3 "sqlite3-$key" $value
	putloglev "d" "*" "sqlite3.tcl: Associated $key -> $value"
}

return 1
