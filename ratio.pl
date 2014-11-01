#!/usr/bin/perl

my @s1,@s2;
my $i,$j;
open RD,"<","res.txt";
foreach(<RD>)
{
/^S1\s*(\d.*)/ and $s1[$i++]=$1; 
/^S2\s*(\d.*)/ and $s2[$j++]=$1;
}
for($i=0;$i<=$#s1;$i++){
$res[$i]=$s1[$i]/$s2[$i];
print "Case $i:Res[$i]=$res[$i]\n";
}
close RD;
