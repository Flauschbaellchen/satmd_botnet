# MODULE gban_compat
# compatibility for old gban-scripts
#

satmd_botnet_require gban

proc satmd_gban_add { a b c} {
	putlog "warning: using deprecated gban functions, ignored"
}
proc satmd_gban_del { a b c} {
	putlog "warning: using deprecated gban functions, ignored"
}

# Successful
set satmd_botnet(version,gban_compat) "0.1"
return 1
