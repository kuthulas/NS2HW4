set flavor [lindex $argv 0]
set case [lindex $argv 1]

set ns [new Simulator]
set nf [open out.nam w]
$ns namtrace-all $nf

proc finish {} {
        global ns nf
        $ns flush-trace
        close $nf
        exec nam out.nam &
        exit 0
}

set src1 [$ns node]
set src2 [$ns node]
set r1 [$ns node]
set r2 [$ns node]
set rcv1 [$ns node]
set rcv2 [$ns node]

global flav, delay

switch $case {
	1 {set delay "3.75ms"}
	2 {set delay "7.5ms"}
	3 {set delay "11.25ms"}
}

switch $flavor {
	1 {set flav "Sack1"}
	2 {set flav "Vegas"}
}

set tcp1 [new Agent/TCP/$flav]
$ns attach-agent $src1 $tcp1
set tcp2 [new Agent/TCP/$flav]
$ns attach-agent $src2 $tcp2

$ns duplex-link $src1 $r1 10Mb 0ms DropTail
$ns duplex-link $src2 $r1 10Mb $delay DropTail
$ns duplex-link $r1 $r2 1Mb 5ms DropTail
$ns duplex-link $r2 $rcv1 10Mb 0ms DropTail
$ns duplex-link $r2 $rcv2 10Mb $delay DropTail

$ns duplex-link-op $src1 $r1 orient right-down
$ns duplex-link-op $src2 $r1 orient right-up
$ns duplex-link-op $r1 $r2 orient right
$ns duplex-link-op $r2 $rcv1 orient right-up
$ns duplex-link-op $r2 $rcv2 orient right-down

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

set null1 [new Agent/TCPSink] 
$ns attach-agent $rcv1 $null1

set null2 [new Agent/TCPSink] 
$ns attach-agent $rcv2 $null2

$ns connect $tcp1 $null1
$ns connect $tcp2 $null2

$ns at 0 "$ftp1 start"
$ns at 400 "$ftp1 stop"

$ns at 0 "$ftp2 start"
$ns at 400 "$ftp2 stop"

$ns at 400 "finish"

set trace_file [open  "out.tr"  w]
$ns trace-queue  $src1  $r1  $trace_file

$ns run