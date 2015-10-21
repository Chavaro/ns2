#!/usr/bin/awk -f
BEGIN {
	sendLine = 1;
	recvLine = 1;
	fowardLine = 1;
}

$0 ~/^r.* AGT/ {
	recvLine ++ ;
}

$0 ~/^s.* AGT/ {
	sendLine ++ ;
}

$0 ~/^f.* RTR/ {
	fowardLine ++ ;
}

END {	print("\n=== pdr.awk ===")
	printf "CBR \n s:\t%d \n r:\t%d \n Ratio:\t%.4f \n f:\t%d \n", sendLine, recvLine, (recvLine/sendLine),fowardLine;
}
