#Q6. Simulate an Ethernet LAN using n nodes (6-10), change error rate and data rate and compare throughput.
#Create Simulator
set ns [new Simulator]

set error_rate 0.00

#Use colors to differentiate the traffic
$ns color 1 Blue
$ns color 2 Red

#Open trace and NAM trace file
set nd [open 6.tr w]
$ns trace-all $nd
set nf [open 6.nam w]
$ns namtrace-all $nf

#Finish Procedure
proc finish {} {
	global ns nf nd
    $ns flush-trace
	#Close the trace files
    close $nf
    close $nd 
	exec nam 6.nam &
    exit 0
}


#Create 6 nodes

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

#Create duplex links between the nodes
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns simplex-link $n2 $n3 0.3Mb 100ms DropTail
$ns simplex-link $n3 $n2 0.3Mb 100ms DropTail

#Node n(3), n(4) and n(5) are considered in a LAN
set lan [$ns newLan "$n3 $n4 $n5" 0.5Mb 10ms LL Queue\DropTail MAC\802_3 Channel]

#Orientation to the nodes
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns simplex-link-op $n2 $n3 orient right

#Setup queue between n(2) and n(3) and monitor the queue
$ns queue-limit $n2 $n3 20
$ns simplex-link-op $n2 $n3 queuePos 0.5

#Set error model on link n(2) and n(3) and insert the error model
set loss_module [new ErrorModel]
$loss_module ranvar [new RandomVariable/Uniform]
$loss_module drop-target [new Agent/Null]
$loss_module set rate_ $error_rate
$ns lossmodel $loss_module $n2 $n3

#Setup TCP Connection between n(0) and n(4)
set tcp [new Agent/TCP/Newreno]
$tcp set fid_ 1
$tcp set window_ 8000
$tcp set packetSize_ 552
$ns attach-agent $n0 $tcp
set sink0 [new Agent/TCPSink/DelAck]
$ns attach-agent $n4 $sink0
$ns connect $tcp $sink0

#Apply FTP Application over TCP
set ftp [new Application/FTP]
$ftp set type_ FTP
$ftp attach-agent $tcp

#Setup UDP Connection between n(1) and n(5)
set udp0 [new Agent/UDP]
$udp0 set fid_ 2
$ns attach-agent $n1 $udp0
set null0 [new Agent/Null]
$ns attach-agent $n5 $null0
$ns connect $udp0 $null0

#Apply CBR Traffic over UDP
set cbr [new Application/Traffic/CBR]
$cbr set type_ CBR
$cbr set packetSize_ 1000
$cbr set rate_ 0.2Mb
$cbr set random_ false
$cbr attach-agent $udp0

#Schedule events
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 124.0 "$ftp stop"
$ns at 124.5 "$cbr stop"
$ns at 125.0 "finish"

#Run Simulation
$ns run
