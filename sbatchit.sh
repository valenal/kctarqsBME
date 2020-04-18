#/bin/bash

oname=BOTH00

for tave in 60s H D M Y; do
    for go in L M 1 0; do  #M MI L 1
        
        if [ $tave = 'Y' ];then
            tnums=1 
            eks=(1)
            mem=8g
            qtime=02:00:00
        elif [ $tave = 'M' ]; then
            tnums=13
            eks=(1.5 6 48)
            mem=8g
            qtime=02:00:00
        elif [ $tave = 'D' ]; then
            tnums=378
            eks=(2 10 30.4 1460)
            mem=8g
            qtime=02:00:00
        elif [ $tave = 'H' ]; then
            tnums=1352
            eks=(2 10 24 35040)
            mem=64g
            qtime=02:00:00
        elif [ $tave = '60s' ]; then
            eks=(120 1440 43800 2102400)
            mem=64g
            qtime=06:00:00
        fi

        if [ $go != 'L' ];then
            eks=(0)
        fi

        for eks in "${eks[@]}" ; do
            #for tnum in $(seq 1 $tnums);do
            for tnum in $(seq 1 1); do
                sbatch -t $qtime -o ./LOG/${oname}_${tave}ave_go${go}_tnum${tnum}_eks${eks}.log --mem=$mem --wrap="./run.sh $tave $go $oname $tnum $eks"
                echo sbatch -t $qtime -o ./LOG/${oname}_${tave}ave_go${go}_tnum${tnum}_eks${eks}.log --mem=$mem --wrap="./run.sh $tave $go $oname $tnum $eks"
            done
        done
    done
done
