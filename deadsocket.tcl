# MODULE deadsocket
# Place a ban on $uhost for quitters having quitmsg=="Dead Socket"
# Default timeline of 5 minutes can be changed via settings.tcl ($satmd_botnet(deadsocket,banduration))

bind sign -|- "*" satmd_botnet_deadsocket_sign
proc satmd_botnet_deadsocket_sign { nick uhost handle channel reason} {
	global satmd_botnet
	if { $reason == "Dead Socket" && (!([isop $nick $channel] || [ishalfop $nick $channel])) && ($channel != "#muh") }  {
		pushmode $channel +b [satmd_botnet_genericbanmask $nick $uhost]
		after [expr $satmd_botnet(deadsocket,banduration) * 1000] [list pushmode $channel -b "*!$uhost"]
	}
}

# Success full
set satmd_botnet(deadsocket,version) "0.2b"
return 1
