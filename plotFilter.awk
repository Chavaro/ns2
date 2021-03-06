#!/usr/bin/awk -f

#BEGIN {FS="[[:space:]]|_"} 	# use posix space or underscore for FS
#BEGIN {FS="[[:space:]]"} 	# use posix space for FS
#BEGIN {FS="_"} 		# use underscore for FS

BEGIN {}
{	
	event = $1
	time = $2
	nodeId = $3	#4
	layer = $4	#6
	flags = $5
	seqID = $6
	type = $7
	pktSize = $8
	
	if( event == "r" && layer == "MAC" && type == "cbr" && time > 1 && nodeId == "_10_" ) {
		sec[int(time)]+=pktSize;
		#sec[int(time)]+=(pktSize*8.0/1000.0);	#kbps
	}
}

END {	for( i in sec ) 
		print i, sec[i] 
}
