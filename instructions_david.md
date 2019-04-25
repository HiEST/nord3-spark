## How to use the Singularity file



### Create a container (similar to  creating an abstract class)

In order to build the singularity container specified in a `.singularity` file  we must do:

```
sudo singularity build name_of_image.simg name_of_singularity_descriptor.singularity
```

for example, if we want to build `bscdc_spark.singularity`  :

```
sudo singularity build spark_bscdc_david.simg bscdc_spark.singularity
```



### Create an instance of a container (similar to instantiating an object of a class)

```
singularity instance.start spark_bscdc_david.simg spark_instance
```



### Going inside an object

In order to open a terminal (shell) inside a singularity container you can use `singularity shell instance://name_of_your_instance`

For example:

```david@bsc-laptop:~/Documents/bsc/nord3-spark$ singularity shell instance://spark_instance
 singularity shell instance://spark_instance 
 Singularity: Invoking an interactive shell within container...
```

Once you are inside a container you will see `Singularity` on the left hand side of the terminal

```
Singularity spark_bscdc_david.simg:~/Documents/bsc/nord3-spark>
```



### Closing an opened instance

After finishing your work and exiting from a singularity container instance you can do `singularity instance.stop` 

```
singularity instance.stop spark_instance
```



### Using Multiple workers 

