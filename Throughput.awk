#!/usr/bin/awk -f
BEGIN {
	recvdSize = 0
	startTime = 1000
	stopTime = 0
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
    
END {	print("\n=== Throughput.awk ===")
	printf("Average \n Throughput:\t%.2f kbps\nStartTime: \t%.2f \nStopTime: \t%.2f\n",(recvdSize/(stopTime-startTime))*(8/1000),startTime,stopTime)
}
