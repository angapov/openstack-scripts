#!/bin/bash
NAME=cache-tier-with-cfq
RUNTIME=2400
OUTPUT=$NAME
OUTPUT_FORMAT=json

IO_PATTERNS="randrw rw" #read write rw, randread randwrite randrw
BLOCKSIZE="4k 4m"
RBD_IMAGE="rbd-test4m"
RW_MIXREAD="0 75 100"
#RANDOM_DISTRIBUTION="--random_distribution=zipf:1.2"
RAMP_TIME=600
RAMP="--ramp_time=$RAMP_TIME"

OPTIONS="--norandommap --per_job_logs=0 --time_based $RAMP --runtime=$RUNTIME --log_avg_msec=1000 --iodepth=16 --randrepeat=0 --direct=1 --buffered=0 --ioengine=rbd --clientname=admin --output-format=$OUTPUT_FORMAT"
mkdir -p $NAME; cd $NAME
for pattern in $IO_PATTERNS; do
  for blocksize in $BLOCKSIZE; do
    for image in $RBD_IMAGE; do
      for i in $RW_MIXREAD; do
        pool=`echo "$image" | cut -d'-' -f1`
        rbd=`echo "$image" | cut -d'-' -f2`
        JOBNAME="${image}-${pattern}${i}-bs${blocksize}"
        echo 3 > /proc/sys/vm/drop_caches; sync
        fio $OPTIONS --pool=$pool --rbdname=$rbd --rw=$pattern --write_bw_log=$JOBNAME --write_lat_log=$JOBNAME --write_iops_log=$JOBNAME --blocksize=$blocksize --name=$JOBNAME --rwmixread=$i --output=${JOBNAME}.json 
      done
    done
  done
done
rm -f *_clat*.log *_slat*.log
#sed -i 's/, 1, 0//g' *.log
#awk -i inplace '{print $1/1000,$2}' OFMT="%3.1f" *.log
#sed -i 's/,//g' *.log
#awk -i inplace '{print $1,$2/1000}' OFMT="%3.1f" *lat.1.log
