#!/usr/bin/bash -l

# set up module environment
module purge
module use /scratch2/NCEPDEV/ovp/Lichuan.Chen/modulefiles
module load intel/2022.1.2 impi/2022.1.2 anaconda-work/1.0.0 mmab/1.0.0
module list

FCSTS='n024 f024 f048 f072 f096 f120 f144 f168 f192'
TODAY=`date "+%Y%m%d"`
RUNDATE=${1:-$TODAY}

echo "Rundate: $RUNDATE" 

ENGINES=48
YESTERDAY=`date --date='yesterday' "+%Y%m%d"`
TMPDIR=/scratch2/NCEPDEV/stmp1/$USER
LOGPATH=$TMPDIR/mpi/logs
SRCDIR=/scratch2/NCEPDEV/ovp/Lichuan.Chen/VPPPG/Global_RTOFS/EMC_ocean-prod-gen/z-level

TASK_QUEUE='batch'
TRANSFER_QUEUE='dev_transfer'
WALL='00:20:00'
#PROJ='marine-cpu'
PROJ='ovp'
JOB="rtofs"

mkdir -p $LOGPATH
mkdir -p $TMPDIR/images/mpi/$RUNDATE/large
mkdir -p $TMPDIR/images/mpi/$RUNDATE/small

# clear out the old logs
cd $TMPDIR/mpi
rm -rf profile_mpi
rm -f logs/*.log

# copy profile over to TMPDIR
cp -r /scratch2/NCEPDEV/ovp/Lichuan.Chen/VPPPG/Global_RTOFS/EMC_ocean-prod-gen/z-level/scripts/profile_mpi $TMPDIR/mpi/.

# create per-forecast mpi jobs
for FCST in $FCSTS; do
  echo "******** submitting job ${JOB}_${FCST} ********" 
  job1=$(sbatch --parsable -J ${JOB}_${FCST} -o $LOGPATH/${RUNDATE}_${FCST}.log -q $TASK_QUEUE --account=$PROJ --time $WALL --ntasks=$(($ENGINES + 1)) --nodes=4 --wrap "$python $SRCDIR/ush/global_mpi.py $RUNDATE $FCST $ENGINES")
  job2=$(sbatch --parsable --dependency=afterok:$job1 --partition=service -J ${JOB}_transfer_${FCST} -q $TASK_QUEUE --account=$PROJ --time $WALL --ntasks 1 -o $LOGPATH/${RUNDATE}_transfer_${FCST}.log --wrap "$SRCDIR/scripts/global_transfer.sh nc $FCST $RUNDATE")
done

exit
