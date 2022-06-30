#!/bin/sh

#SBATCH --output=output_%j.out
#SBATCH --error=output_%j.err
#SBATCH --nodes=3
#SBATCH --exclusive
#SBATCH --job-name=spark01_single
#SBATCH --time=00:02:00

module load intel/2018.1 singularity/3.5.2

# THIS CREATES A SINGLE-NODE SPARK CLUSTER IN MARENOSTRUM-IV
# MN-IV NODES -> 48 CORES; 96GB RAM
# DEFAULT SPARK WORKER (ALL RESOURCES)

###############################################################################
## EXPERIMENT PREPARATION

IMAGE=dcc-spark02.simg

BSC_USER=XXXXX
BSC_GROUP=YYYYY

# COPY THE EXPERIMENT FILES INTO WORK DIRECTORY
HOME_DIR=/gpfs/projects/$BSC_GROUP/$BSC_USER/spark-test
WORK_DIR=/gpfs/scratch/$BSC_GROUP/$BSC_USER/spark-test

mkdir -p $WORK_DIR
cd $WORK_DIR

# COPY EXPERIMENT, DATA FILES, AND IMAGE (IF NEEDED)
cp $HOME_DIR/mobydick.txt $WORK_DIR/
cp $HOME_DIR/example.* $WORK_DIR/
if [ ! -d $WORK_DIR/$IMAGE ]; then
    cp $HOME_DIR/$IMAGE $WORK_DIR/ ;
fi

# SPARK SCRIPT TO BE SUBMITTED (SCALA, PYTHON OR R)
EXPERIMENT=example.scala
#EXPERIMENT=example.py
#EXPERIMENT=example.R

###############################################################################
## SPARK CONFIGURATION (YOU PROBABLY DON'T NEED TO TOUCH THIS)

SPARK_WORKER_ARGS=''    # By default '' (All resources). Set explicit values, e.g. for 16 cores & 125GB per worker: '-c 16 -m 125g'.
WORKERS_NODE=1          # By default 1 (All resources). Compose workers and resources in homogeneous nodes.

###############################################################################
## SPARK EXECUTION (YOU SHOULDN'T NEED TO TOUCH THIS PART)

# GET GRANTED HOSTS AND CORES PER HOST
HS=`srun hostname |sort`
H_LIST=`echo ${HS} | awk '{ for (i=1; i<=NF; i+=1) print $i }'`

# CREATE SPARK ENVIRONMENT
MASTER_OUT=spark_master_${SLURM_JOBID}
WORKER_OUT=spark_worker_${SLURM_JOBID}

REAL_WORK_DIR=$WORK_DIR
SPARK_TEMP=$TMPDIR/spark-work
mkdir -p $SPARK_TEMP

# SPARK MASTER
echo "Starting Master $HOSTNAME"
singularity run $IMAGE "org.apache.spark.deploy.master.Master" --host $HOSTNAME > ${MASTER_OUT}.out 2> ${MASTER_OUT}.err &
sleep 5;

# SPARK WORKERS
for node in $H_LIST; do
        for (( i=0; i<$WORKERS_NODE; i++ )); do
                echo "Starting Worker $node (master $HOSTNAME)"
                ssh -q $node "module load intel/2018.1 SINGULARITY/3.5.2; cd ${WORK_DIR}; nohup singularity run ${IMAGE} 'org.apache.spark.deploy.worker.Worker' -d ${SPARK_TEMP} ${SPARK_WORKER_ARGS} spark://$HOSTNAME:7077 > ${WORKER_OUT}_${node}_${i}.out 2> ${WORKER_OUT}_${node}_${i}.err &";
        done;
done;

# SPARK APPLICATION
echo "Launching Application"
cd $REAL_WORK_DIR
case $( echo $EXPERIMENT | awk -F'.' '{ print tolower($NF) }' ) in
scala)
        SHELL=spark-shell
        ;;
py)
        SHELL=pyspark
        ;;
r)
        SHELL=sparkR --vanilla
        ;;
*)
        echo "Not recognized script file"
        SHELL=spark-shell
esac
singularity exec $IMAGE $SHELL --master spark://$HOSTNAME:7077 < $EXPERIMENT ;

# KILL SPARK SESIONS
echo "Cleaning Spark Nodes"
H_LIST_REV=`for i in $H_LIST; do echo $i; done | tac`
for node in $H_LIST_REV; do
        ssh -q $node "kill \$( ps aux | grep spark | grep -v grep | awk '{ print \$2 }' ) "
done;

###############################################################################
## EXPERIMENT WRAP-UP

# CREATE HOME EXPERIMENT FOLDER
mkdir -p $HOME_DIR/experiment_${SLURM_JOBID}

# COPY SPARK OUTPUT BACK TO HOME
mv $WORK_DIR/${MASTER_OUT}* $HOME_DIR/experiment_${SLURM_JOBID}/
mv $WORK_DIR/${WORKER_OUT}* $HOME_DIR/experiment_${SLURM_JOBID}/

# COPY RESULTS BACK TO HOME
mv $WORK_DIR/wc-result.data $HOME_DIR/experiment_${SLURM_JOBID}/
mv $WORK_DIR/mobydick.txt $HOME_DIR/experiment_${SLURM_JOBID}/
mv $WORK_DIR/example.* $HOME_DIR/experiment_${SLURM_JOBID}/

# THAT'S ALL, FOLKS!
echo "Bye!"
exit
