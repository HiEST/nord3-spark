#BSUB -J example_spark01_single
#BSUB -q debug
#BSUB -W 00:20
#BSUB -oo output_%J.out
#BSUB -eo output_%J.err
#BSUB -n 32
#BSUB -x

module load intel/2018.1 singularity/3.5.2

# THIS CREATES A SINGLE-NODE SPARK CLUSTER IN NORD3
# NORD3 NODES -> 16 CORES; 127GB RAM
# DEFAULT SPARK WORKER (ALL RESOURCES) -> 16 CORES; 125GB RAM

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

SPARK_WORKER_ARGS=''	# By default '' (All resources). Set explicit values, e.g. for 16 cores & 125GB per worker: '-c 16 -m 125g'.
WORKERS_NODE=1 		# By default 1 (All resources). Compose workers and resources in homogeneous nodes.

###############################################################################
## SPARK EXECUTION (YOU SHOULDN'T NEED TO TOUCH THIS PART)

# GET GRANTED HOSTS AND CORES PER HOST
H_LIST=`echo ${LSB_MCPU_HOSTS} | awk '{ for (i=1; i<=NF; i+=2) print $i }'`
H_CORE=`echo ${LSB_MCPU_HOSTS} | awk '{ for (i=2; i<=NF; i+=2) print $i }'`

# CREATE SPARK ENVIRONMENT
MASTER_OUT=spark_master_${LSB_JOBID}
WORKER_OUT=spark_worker_${LSB_JOBID}

REAL_WORK_DIR=$WORK_DIR
SPARK_TEMP=$TMPDIR/spark-work
mkdir -p $SPARK_TEMP

# SPARK MASTER
echo "Starting Master $HOSTNAME"
singularity exec $IMAGE spark-class "org.apache.spark.deploy.master.Master" --host $HOSTNAME > ${MASTER_OUT}.out 2> ${MASTER_OUT}.err &
sleep 5;

# SPARK WORKERS
for node in $H_LIST; do
	for (( i=0; i<$WORKERS_NODE; i++ )); do
		echo "Starting Worker $node"
		ssh -q $node "module load intel/2018.1 singularity/3.5.2; cd ${WORK_DIR}; nohup singularity exec ${IMAGE} spark-class 'org.apache.spark.deploy.worker.Worker' -d ${SPARK_TEMP} spark://${HOSTNAME}:7077 ${SPARK_WORKER_ARGS} > ${WORKER_OUT}_${node}_${i}.out 2> ${WORKER_OUT}_${node}_${i}.err &";
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
	SHELL=sparkR
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
mkdir -p $HOME_DIR/experiment_${LSB_JOBID}

# COPY SPARK OUTPUT BACK TO HOME
mv $WORK_DIR/${MASTER_OUT}* $HOME_DIR/experiment_${LSB_JOBID}/
mv $WORK_DIR/${WORKER_OUT}* $HOME_DIR/experiment_${LSB_JOBID}/

# COPY RESULTS BACK TO HOME
mv $WORK_DIR/wc-result.data $HOME_DIR/experiment_${LSB_JOBID}/
mv $WORK_DIR/mobydick.txt $HOME_DIR/experiment_${LSB_JOBID}/
mv $WORK_DIR/example.* $HOME_DIR/experiment_${LSB_JOBID}/

# THAT'S ALL, FOLKS!
echo "Bye!"
exit
