if { $argc != 2 } {
        puts "Invalid usage!"
        puts "For example: ns $argv0 <TCP_Flavor> <case_no>"
        puts "Please try again."
    }
set flavor [lindex $argv 0]
set case [lindex $argv 1]
if {$case > 3 || $case < 1} { 
	puts "Invalid case $case" 
   	exit
}
global flav, delay
set delay 0
switch $case {
	global delay
	1 {set delay "12.5ms"}
	2 {set delay "20ms"}
	3 {set delay "27.5ms"}
}
if {$flavor == "SACK"} {
	set flav "Sack1"
} elseif {$flavor == "VEGAS"} {
	set flav "Vegas"
} else {
	puts "Invalid TCP Flavor $flavor"
	exit
}
set f1 [open out1.tr w]
set f2 [open out2.tr w]
set ns [new Simulator]
set file "out_$flavor$case"
set cnt 0;
set tput1 0;
set tput2 0;
proc finish {} {
        global ns nf file tput1 tput2 cnt
	#parse $file-S1.tr 2 0.0 4.0 100
	#parse $file-S2.tr 2 1.0 5.0 100
	puts "Avg throughput for Src1=[expr $tput1/$cnt] MBits/sec\n"
	puts "Avg throughput for Src2=[expr $tput2/$cnt] MBits/sec\n"
#	exec xgraph out1.tr out2.tr -geometry 800x400 &
        exit 0
}
proc record {} {
        global null1 null2 f1 f2 tput1 tput2 cnt
        set ns [Simulator instance]
        set time 0.5
        set bw1 [$null1 set bytes_]
        set bw2 [$null2 set bytes_]
        set now [$ns now]
        puts $f1 "$now [expr $bw1/$time*8/1000000]"
        puts $f2 "$now [expr $bw2/$time*8/1000000]"
	set tput1 [expr $tput1+$bw1/$time*8/1000000]
	set tput2 [expr $tput2+$bw2/$time*8/1000000]
	set cnt [expr $cnt+1]
        #Reset the bytes_ values on the traffic sinks
        $null1 set bytes_ 0
        $null2 set bytes_ 0
        #Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}

proc parse {filename destnode fromport toport granularity } {

	set clk 0
	set sum 0
	set grantsum 0
	set trfile [open  $filename  r]
	while { [gets $trfile line] >= 0 } {
	set theWords [regexp -all -inline {\S+} $line]
	set x0 [lindex $theWords 0]
	set x1 [lindex $theWords 1]
	set x2 [lindex $theWords 2]
	set x3 [lindex $theWords 3]
	set x4 [lindex $theWords 4]
	set x5 [lindex $theWords 5]
	set x8 [lindex $theWords 8]
	set x9 [lindex $theWords 9]
	set delta [expr $x1-$clk]
  	#puts "$delta < $granularity"
      	if {$delta < $granularity} {
	if {$x0=="r"} {
            if {$x3 == $destnode && $x8 == $fromport && $x9 == $toport} {
               if {$x4 == "tcp"} {
		  set sum [expr $sum+$x5]
            	  set grantsum [expr $grantsum+$x5]
               }
            }
         }
	} else {
         set throughput [expr 0.000008*$sum/$granularity]

	 set clk [expr $clk+$granularity]
         if {$x0 == "r" && $x3 == $destnode && $x8 == $fromport && $x9 == $toport && $x4 == "tcp"} {
            set sum [expr $x5]
            set grantsum [expr $grantsum+$x5]
         } else {
            set sum 0;
         }
	 set del [expr $x1-$clk]
         while {$del > $granularity} {
	 set clk [expr $clk+$granularity]
         }
      	}
    	}
	set throughput [expr {0.000008*$sum/$granularity}]
   	#puts "$clk $sum $throughput\n";
	set clk [expr $clk+$granularity]
	set avgtput [expr 0.000008*$grantsum/$clk]
   	puts "Avg throughput $fromport - $toport = $avgtput MBytes/sec \n";

}

set src1 [$ns node]
set src2 [$ns node]
set r1 [$ns node]
set r2 [$ns node]
set rcv1 [$ns node]
set rcv2 [$ns node]


#switch $flavor {
#	1 {set flav "Sack1"}
#	2 {set flav "Vegas"}
#}

set tcp1 [new Agent/TCP/$flav]
$ns attach-agent $src1 $tcp1
set tcp2 [new Agent/TCP/$flav]
$ns attach-agent $src2 $tcp2

$ns duplex-link $src1 $r1 10Mb 5ms DropTail
$ns duplex-link $src2 $r1 10Mb $delay DropTail
$ns duplex-link $r1 $r2 1Mb 5ms DropTail
$ns duplex-link $r2 $rcv1 10Mb 5ms DropTail
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

$ns at 0 "record"
$ns at 0 "$ftp1 start"
$ns at 400 "$ftp1 stop"

$ns at 0 "$ftp2 start"
$ns at 400 "$ftp2 stop"

$ns at 400 "finish"

set tfile1 [open "$file-S1.tr" w]
$ns trace-queue  $src1  $r1  $tfile1

set tfile2 [open "$file-S2.tr" w]
$ns trace-queue  $src2  $r1  $tfile2

$ns run
