#!/bin/sh

tave=$1
go=$2
oname=$3
tnum=$4
eks=$5

matlab -nodisplay -nodesktop -nosplash -singleCompThread -batch "bmeKrig('$tave','$go','$oname','$tnum','$eks');" -logfile ./LOG/${oname}_${tave}ave_go${go}_tnum${tnum}_eks${eks}.out

