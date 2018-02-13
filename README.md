# Apache Spark in Nord3
Scripts to launch Spark executions on Nord3

## Singularity Image
### Build Singularity image
```
sudo singularity build dcc-spark01.simg dcc-spark01.singularity
```

### Test shell
```
singularity run shell dcc-spark01.simg 
```

### Run image (in local!)
```
singularity exec dcc-spark01.simg spark-class "org.apache.spark.deploy.master.Master" --host 127.0.0.1
singularity exec dcc-spark01.simg spark-class 'org.apache.spark.deploy.worker.Worker' -d /tmp/spark-worker spark://127.0.0.1:7077
singularity exec dcc-spark01.simg pyspark --master spark://127.0.0.1:7077 < example.py
```

### Kill images
```
kill $( ps aux | grep spark | grep -v "grep" | awk "{print $2}" )
```

## Run scripts in Nord3

Nord3 has machines with 16 CPU and 127GB RAM. Queues can be checked with _bqueues_ (usual queues are **debug** and **bsc_cs**).

Using _modules avail_ you can list the available modules to be activated (e.g. java, python, singularity, gcc...).

Example of script header, at debug queue, 20 minutes to timeout, 32 cores (2 machines), and in exclusive, then load intel module and run stuff:
```
#BSUB -J example_spark01_single
#BSUB -q debug 
#BSUB -W 00:20
#BSUB -oo output_%J.out
#BSUB -eo output_%J.err
#BSUB -n 32 
#BSUB -x

modules load intel

Here bash script...
```

Usage manuals:
* https://www.bsc.es/support/MN4BasiscsLife.pdf (use _bsub_ instead of slurm better)
* https://www.bsc.es/user-support/nord3.php (check commands _bsub_, _bjobs_, _bkill_, _bhosts_, _lshosts_)


### Run regular scripts

Script submission process:
* Copy experiment files through **dt0{1,2,3}.bsc.es** (e.g., use scp)
* Connect through Nord3 login **nord{1,2,3}.bsc.es** (using ssh)
* Create script with totally automated experiment (and execution permissions)
  * Move experiments to /gpfs/scratch/...
  * Execute stuff
  * Retrieve experiments to /gpfs/home/...
* Execute **bsub < script.sh**

### Run Spark scripts

Compile the Singularity image, and copy it to your Node3 **HOME** (or whatever inside the GPFS)

Get the example script, and modify only the *Experiment preparation* and *Experiment wrap-up*.
* Copy the image to the scratch directory (shared or local)
* Copy the experiment files to scratch (shared or local)
* Edit the script file to match with your experiments (in *preparation* and *wrap-up*)
  * Variable **EXPERIMENT** contains the script to be submitted to Spark
  * Variable **SPARK_WORKER_ARGS** and **WORKERS_NODE** contain the worker configuration. By default there is a worker per node, and all node resources available to the worker. If more workers per node are given, SPARK_WORKER_ARGS must be adjusted (e.g. WORKERS_NODE=2 -> SPARK_WORKER_ARGS='-c 8 -m 62g')
* Submit your job with **bsub < script.sh**

The example script is set to copy the Singularity image to _scratch_ only if it doesn't exist. If you modify the image, be sure to remove the image in /gpfs/scratch/...

### Environment
* Your shared home is at /gpfs/home/bsc31/bsc31XXX (don't run things from here -> **NOT a working directory**)
* Your shared scratch is at /gpfs/scratch/bsc31/bsc31XXX (**working directory**. It is temporary storage, without backup)
* Your shared archive is at /gpfs/archive/bsc31/bsc31XXX (long term storage)
* Local scratch is only seen locally (not shared scratch), and is lost at the end of the execution (**working directory**)

Finally, be sure to have configured your access to BSC machines with RSA key exchange.
