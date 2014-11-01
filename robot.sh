#!/bin/sh
clear

flavs="1 2"
cases="1 2 3"

rm -f out_*
rm -f *.tr
rm -f *.nam
rm res.txt 

for a in $flavs
do
	for b in $cases
	do
		ns hw4.tcl $a $b
		perl throughput.pl "out_$a$b-S1.tr" 2 0.0 4.0 100 | awk 'NR > 1 { total += $2; count++ } END { print "S1 " total/count }'>>res.txt
		perl throughput.pl "out_$a$b-S2.tr" 2 1.0 5.0 100 | awk 'NR > 1 { total += $2; count++ } END { print "S2 " total/count }'>>res.txt
	done
done

rm -f *.tr
rm -f *.nam

echo ""
