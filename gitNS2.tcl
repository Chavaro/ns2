#####################################################################################
#  Hierarchical Cluster Tree over 802.15.4                                          #
#             (No-beacon enabled)                                                   #
# ----------------------------------------------------------------------------------#
# Autor: Ing. Miguel Alejandro Chavarín                                             #
#   used resources:                                                                 #
#     - http://jhshi.me/2013/12/13/simulate-random-mac-protocol-in-ns2-part-i/      #
#####################################################################################

# ======================================================================
# Project Parameters
# ======================================================================
set val(duration)       10                    ;# Simulation duration in secs                
set val(packetsize)     70                    ;# Size in Bytes
set val(repeatTx)       10                    ;# Number of Packets
set val(interval)       0.02                  ;# BitRate in secs
set val(x)              50                    ;# X=50m
set val(y)              50                    ;# Y=50m
set val(nam_file)       "gitNS2.nam"
set val(trace_file)     "gitNS2.tr"
set val(stats_file)     "gitNS2.stats"
set val(node_size)      5                     ;# Nodes size in nam

# ======================================================================
# Define Node Options
# ======================================================================
set val(chan)     Channel/WirelessChannel     ;# channel type
set val(prop)     Propagation/TwoRayGround   	;# radio-propagation model
set val(netif)		Phy/WirelessPhy/802_15_4   	;# network interface type
set val(mac)  		Mac/802_15_4               	;# MAC type
set val(ifq)  		Queue/DropTail/PriQueue    	;# interface queue type
set val(ll)     	LL                         	;# link layer type
set val(ant)    	Antenna/OmniAntenna        	;# antenna model
set val(ifqlen) 	50                         	;# max packet in ifq
set val(nn)     	11                         	;# number of nodes: 1 SN, 3 CH, 6 MN, 1WN
set val(rp)     	DSDV                        ;# Destination Sequence Distance Vector routing protocol. USE THIS ONE!
#set val(rp)     	TORA                       	 ;# Temporally ordered Routing Algorithm routing protocol
#set val(rp)     	DSR                        	 ;# Dynamic Source Routing routing protocol
#set val(rp)     	AODV	                      ;# Adhoc On-demand Distance Vector routing protocol
#set val(rp)      PUMA                        ;# Protocol for Unified Multicasting Through Announcements routing protocol
set val(traffic)	cbr                        	;# cbr||poisson||ftp||tcp

#read command line arguments
proc getCmdArgu {argc argv} {
        global val
        for {set i 0} {$i < $argc} {incr i} {
                set arg [lindex $argv $i]
                if {[string range $arg 0 0] != "-"} continue
                set name [string range $arg 1 end]
                set val($name) [lindex $argv [expr $i+1]]
        }
}
getCmdArgu $argc $argv

# ======================================================================
# Main Program
# ======================================================================

# Initialize Global Variables
#Create an instance of the simulator
set ns_		                  [new Simulator]

#Setup trace support
set   tracefd	              [open ./$val(trace_file) w]
$ns_  trace-all             $tracefd

#Setup stats file
set stats                   [open $val(stats_file) w]

#Setup nam file
set   namtrace              [open ./$val(nam_file) w]
$ns_  namtrace-all-wireless $namtrace $val(x) $val(y)

$ns_ puts-nam-traceall {# nam4wpan #}		 ;# inform nam that this is a trace file for wpan (special handling needed)
Mac/802_15_4 wpanNam namStatus on		     ;# default = off (should be turned 'on' before other 'wpanNam' commands can work)
Mac/802_15_4 wpanCmd verbose on
Mac/802_15_4 wpanCmd ack4data on
#Mac/802_15_4 wpanNam ColFlashClr gold		;# default = gold
#Mac/802_15_4 wpanNam NodeFailClr grey		;# default = grey

# For model 'TwoRayGround'
set dist(5m)  7.69113e-06
set dist(9m)  2.37381e-06
set dist(10m) 1.92278e-06
set dist(11m) 1.58908e-06
set dist(12m) 1.33527e-06
set dist(13m) 1.13774e-06
set dist(14m) 9.81011e-07
set dist(15m) 8.54570e-07

set dist(16m) 7.51087e-07
set dist(20m) 4.80696e-07
set dist(25m) 3.07645e-07
set dist(30m) 2.13643e-07
set dist(35m) 1.56962e-07
set dist(40m) 1.20174e-07

# Set Transmission Range
Phy/WirelessPhy set CSThresh_ $dist(15m)	;#Carrier Sense: Defines the Energy Detection Treshold to determine if channel is idle or busy.
Phy/WirelessPhy set RXThresh_ $dist(15m)	;#CSThresh must always be less than or equal to RXThresh in ns2

#Create topology object that keeps track of movements of mobile nodes within topological boundary
set topo   	[new Topography]

#Define Topography: X=50m, Y=50m
$topo load_flatgrid $val(x) $val(y)

#Create object GOD (General Operations Director)
set god_ [create-god $val(nn)]

# Create channel #1
set chan_1_ [new $val(chan)]

# Create node(0) "attached" to channel #1
# Configuration of nodes
$ns_ node-config -adhocRouting  $val(rp) \
		 -llType                    $val(ll) \
		 -macType                   $val(mac) \
		 -ifqType                   $val(ifq) \
		 -ifqLen                    $val(ifqlen) \
		 -antType                   $val(ant) \
		 -propType                  $val(prop) \
		 -phyType                   $val(netif) \
		 -topoInstance              $topo \
		 -agentTrace                ON \
		 -routerTrace               ON \
		 -macTrace                  ON \
		 -movementTrace             OFF \
		#-energyModel "EnergyModel" \
                #-initialEnergy 1 \
                #-rxPower 0.3 \
                #-txPower 0.3 \
		 -channel                   $chan_1_

# ======== CREATE NODES =============
#Create the only Sink Node
#variable sink_node
# set   sink_node         [$ns_ node]
# $sink_node              random-motion   0; # disable random motion
# set   sink              [new Agent/LossMonitor]
# $ns_  attach-agent      $sink_node      $sink
# $ns_  initial_node_pos  $sink_node      $val(node_size)

#Create the nn mobilenodes
for {set i 0} {$i < $val(nn) } {incr i} {  
  set node_($i)             [$ns_ node]
  $node_($i)  random-motion 0;
  if { ($i == 0) } {
    set   sink              [new Agent/LossMonitor]
    $ns_  attach-agent      $node_($i)      $sink
  }
}

#Setting time in seconds for Events (Tx): Simulation lapse -> 60 sec
set appTime1    20  ;# in seconds
set appTime2    55  ;# in seconds
set appTime3    80  ;# in seconds 
set stopTime    120 ;# in seconds

#As random-motion is disabled, node position and movement (speed and direction) must be provided
#Initial Node positions, movement and configurations...
source ./gitNS2.scn


Mac/802_15_4 wpanNam PlaybackRate 100ms			        ;#Step of simulation
$ns_ at $appTime1 "puts \"\nTransmitting data ...\n\""

# Setup traffic flow between nodes
proc cbrtraffic { src dst starttime } {
  global ns_ node_ val            ;#Declares use of ns_ and node_ global vars
  set udp_($src) [new Agent/UDP]                          ;#Declares a UDP agent called "udp_"

  #$udp_($src) set class_ $src
  eval $ns_ attach-agent \$node_($src) \$udp_($src)       ;#Attaches the udp agent _ to source node _

  set null_($dst)     [new Agent/Null]                    ;#Creates a null agent
  eval $ns_ attach-agent \$node_($dst) \$null_($dst)      ;#Attaches a null agent to dest node _

  set cbr_($src)      [new Application/Traffic/CBR]       ;#Declares new application for Constant Bit Rate Traffic called cbr_
  eval \$cbr_($src)   set packet_size_  \$val(packetsize) ;#size in Bytes
  eval \$cbr_($src)   set interval_     $val(interval)    ;#bit rate in secs
  eval \$cbr_($src)   set random_       0                 ;#No Random cbr
  #eval \$cbr_($src) set maxpkts_ 10000                    ;#Maximum packets sent in whole simulation 
  eval \$cbr_($src)   attach-agent      $udp_($src)       ;#Attaches udp agent to src node

  eval $ns_ connect   \$udp_($src)      \$null_($dst)     ;#Connects the udp agent on src node to the null agent on dst node.
  #$ns_ connect        $udp_($src)   $sink                 ;#LossMonitor?

  $ns_ at $starttime "$cbr_($src) start"                  ;#Start
  # $ns_ at $val(duration) "$cbr($i) stop"
}

if { ("$val(traffic)" == "cbr") } {
  puts "\nTraffic: $val(traffic)"
  #Mac/802_15_4 wpanCmd ack4data off
  puts [format "Acknowledgement for data: %s" [Mac/802_15_4 wpanCmd ack4data]]

  #PlaybackRate modifying
  $ns_ at $appTime1 "Mac/802_15_4 wpanNam PlaybackRate 5.0ms"
  $ns_ at [expr $appTime1 + 1] "Mac/802_15_4 wpanNam PlaybackRate 100.0ms"

  $ns_ at $appTime2 "Mac/802_15_4 wpanNam PlaybackRate 5.0ms"
  $ns_ at [expr $appTime2 + 1] "Mac/802_15_4 wpanNam PlaybackRate 100.0ms"

  $ns_ at $appTime1 "Mac/802_15_4 wpanNam PlaybackRate 5.0ms"
  $ns_ at [expr $appTime3 + 1] "Mac/802_15_4 wpanNam PlaybackRate 100.0ms"

  #Declaration of the roles of the nodes.
  set dst_node1 10	;#Sink Node
  set dst_node2 10	;#Sink Node
  set dst_node3 10	;#Sink Node
  set src_node  9	  ;#Wild Node

  cbrtraffic $src_node $dst_node1 $appTime1	;#Calls for cbrtraffic proc: node10 -> node1 every 0.2s since time $appTime
  cbrtraffic $src_node $dst_node1 $appTime2	;#Calls for cbrtraffic proc: node10 -> node0 every 0.2s since time $appTime
  cbrtraffic $src_node $dst_node1 $appTime3	;#Calls for cbrtraffic proc: node10 -> node7 every 0.2s since time $appTime

  #$node add-mark [name] [color] [shape]
  $ns_ at $appTime1 "$node_($src_node) add-mark m1 blue circle"
  $ns_ at $appTime1 "$node_($dst_node1) add-mark m2 red circle"
  $ns_ at $appTime1 "$ns_ trace-annotate \"(at $appTime1) cbr traffic from node $src_node to node $dst_node1\""

  $ns_ at $appTime2 "$node_($src_node) delete-mark m1"
  $ns_ at $appTime2 "$node_($dst_node1) delete-mark m2"

  $ns_ at $appTime2 "$node_($src_node) add-mark m1 blue circle"
  $ns_ at $appTime2 "$node_($dst_node2) add-mark m2 red circle"
  $ns_ at $appTime2 "$ns_ trace-annotate \"(at $appTime2) $val(traffic) traffic from node $src_node to node $dst_node2\""

  $ns_ at $appTime3 "$node_($src_node) delete-mark m1"
  $ns_ at $appTime3 "$node_($dst_node2) delete-mark m2"

  $ns_ at $appTime3 "$node_($src_node) add-mark m1 blue circle"
  $ns_ at $appTime3 "$node_($dst_node3) add-mark m2 red circle"
  $ns_ at $appTime3 "$ns_ trace-annotate \"(at $appTime3) $val(traffic) traffic from node $src_node to node $dst_node3\""

  #FlowClr [-p <packetTypeName>] [-s <src>] [-d <dst>] [-c <clrName>]
  Mac/802_15_4 wpanNam FlowClr -p AODV -c tomato	
  Mac/802_15_4 wpanNam FlowClr -p ARP -c green
  Mac/802_15_4 wpanNam FlowClr -p MAC -c navy

  Mac/802_15_4 wpanNam FlowClr -p cbr -s $src_node -d $dst_node1 -c blue
  Mac/802_15_4 wpanNam FlowClr -p cbr -s $src_node -d $dst_node2 -c green4
  Mac/802_15_4 wpanNam FlowClr -p cbr -s $src_node -d $dst_node3 -c red
}

# Defines the node size in nam
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_    initial_node_pos  $node_($i) $val(node_size)
}

# Tell nodes when the simulation ends
for {set i 0} {$i < $val(nn)} {incr i} {
  $ns_ at $stopTime "$node_($i) reset";
}

$ns_ at $stopTime "stop"
$ns_ at $stopTime "puts \"\nNS EXITING...\n\""
$ns_ at $stopTime "$ns_ halt"

proc stop {} {
    #global ns_ tracefd appTime val env     #Version 1

    #version 2
    #global ns tracefd nam stats val sink

    #Mixed version
    global ns_ tracefd appTime val env nam stats sink

    #from v2
    set bytes [$sink set bytes_]
    set losts  [$sink set nlost_]
    set pkts [$sink set npkts_]
    puts $stats "bytes losts pkts"
    puts $stats "$bytes $losts $pkts"

    $ns_ flush-trace
    close $tracefd
    close $stats
    set hasDISPLAY 0
    foreach index [array names env] {
        #puts "$index: $env($index)"
        if { ("$index" == "DISPLAY") && ("$env($index)" != "") } {
                set hasDISPLAY 1
        }
    }
    if { ("$val(nam_file)" == "gitNS2.nam") && ("$hasDISPLAY" == "1") } {
    	exec nam gitNS2.nam &
    }

    # From version 2
    # $ns flush-trace
    # close $nam
    # close $tracefd
    # close $stats

}

puts "\nStarting Simulation..."
$ns_ run
