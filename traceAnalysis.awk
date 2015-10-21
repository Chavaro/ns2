#!/usr/bin/awk -f
BEGIN {
	seqno = -1; 
	droppedPackets = 0;
	receivedPackets = 0;
	count = 1;
}

{
	event = $1;
        time = $2;
	node_id = $3;
	layer = $4;
	flags = $5;
	seqID = $6;
	type = $7;
	pktSize = $8;

	#traffType = "tcp";
	traffType = "cbr";

	#packet delivery ratio
	if(layer == "AGT" && event == "s" && seqno < seqID) {
		seqno = seqID;
	} else if((layer == "AGT") && (event == "r")) {
		receivedPackets++;
	} else if (event == "D" && type == traffType && pktSize > 80){
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
}
 
END { 
	print("\n=== traceAnalysis.awk ===")
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
}