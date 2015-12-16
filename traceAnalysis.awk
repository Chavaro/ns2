#!/usr/bin/awk -f

#BEGIN {FS="[[:space:]]|_"} 	# use posix space or underscore for FS
#BEGIN {FS="[[:space:]]"} 	# use posix space for FS
#BEGIN {FS="_"} 		# use underscore for FS

BEGIN {
	#Part1
	seqno = -1; 
	droppedPackets = 0;
	receivedPackets = 0;
	count = 1;
	
	#Part2
	recvdSize = 0
	startTime = 1000
	stopTime = 0

	#Part3
	sendLine = 1;
	recvLine = 1;
	fowardLine = 1;
}

#Part3
$0 ~/^r.* AGT/ {
	recvLine ++ ;
}
#Part3
$0 ~/^s.* AGT/ {
	sendLine ++ ;
}
#Part3
$0 ~/^f.* RTR/ {
	fowardLine ++ ;
}


{
	event = $1;
	time = $2;
	node_id = $3;
	layer = $4;
	flags = $5;
	seqID = $6;
	type = $7;
	pkt_size = $8;

	#traffType = "tcp";
	traffType = "cbr";

	#Part1

	#packet delivery ratio
	if(layer == "AGT" && event == "s" && seqno < seqID) {
		seqno = seqID;
	} else if((layer == "AGT") && (event == "r")) {
		receivedPackets++;
	} else if (event == "D" && type == traffType && pkt_size > 80){
		droppedPackets++; 
	}
	
	#end-to-end delay
	if(layer == "AGT" && event == "s") {
		start_time[seqID] = time;
	} else if((type == traffType) && (event == "r")) {
		end_time[seqID] = time;
	} else if(event == "D" && type == traffType) {
		end_time[seqID] = -1;
	}

	#Part2
	# Store start time
 	if (layer == "AGT" && event == "s" && pkt_size >= 80) {
		if (time < startTime) {
			startTime = time
		}
	}
 
	# Update total received packets' size and store packets arrival time
	if (layer == "AGT" && event == "r" && pkt_size >= 80) {
		if (time > stopTime) {
	        	stopTime = time
		}
		# Rip off the header
		hdr_size = pkt_size % 80
		pkt_size -= hdr_size
		# Store received packet's size
		recvdSize += pkt_size
	}
}
 
END {
	#Part1
	for(i=0; i<=seqno; i++) {
		if(end_time[i] > 0) {
			delay[i] = end_time[i] - start_time[i];
			count++;
		}
		else
		{
			delay[i] = -1;
		}
	}
	for(i=0; i<count; i++) {
		if(delay[i] > 0) {
			n_to_n_delay = n_to_n_delay + delay[i];
		} 
	}
	n_to_n_delay = n_to_n_delay/count;
	print "GeneratedPackets = \t" seqno+1;
	print "ReceivedPackets = \t" receivedPackets;
	print "PakDelivery Ratio = \t" receivedPackets/(seqno+1)*100"%";
	print "TotDropped Pakts = \t" droppedPackets;
	print "Average E2E Delay = \t" n_to_n_delay * 1000 " ms";

	#Part2
	printf("Average \n Throughput:\t%.2f kbps\nStartTime: \t%.2f \nStopTime: \t%.2f\n",(recvdSize/(stopTime-startTime))*(8/1000),startTime,stopTime)

	#Part3
	printf "CBR \n s:\t%d \n r:\t%d \n Ratio:\t%.4f \n f:\t%d \n", sendLine, recvLine, (recvLine/sendLine),fowardLine;
}
