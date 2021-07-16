# SmartSim Slurm Demo

This repo holds a docker deployment with SmartSim, Slurm, and a few
demo applications along with instructions for running them.

This is a multi-container Slurm cluster using docker-compose.  The compose file
creates named volumes for persistent storage of MySQL data files as well as
Slurm state and log directories.

The slurm/docker work presented here is largely based off of
  - https://github.com/giovtorres/slurm-docker-cluster

The biggest difference is that the base image is ubuntu and the
SmartSim additions have been made.


# Running SmartSim Demo

Below are the instructions to run the SmartSim demo applications in the slurm docker cluster.

Keep in mind, this demo is setup for computers containing at least 4 cores with hyperthreads.

## Start the Cluster

```console
docker pull spartee/smartsim-slurm-demo:v1.0.1
docker-compose up -d
./register_cluster.sh
docker exec -it slurmctld bash
```

Once inside the head node container, run the following

```console
cd /data/lammps-examples/melt/
salloc -N 3 -t 10:00:00 -n 6
jupyter lab --port 8888 --no-browser --allow-root --ip=0.0.0.0
```

then copy paste the bottom link into your browser, open the
notebook and execute each cell.


# Slurm Docker Infrastructure

The slurm cluster used for the SmartSim demo applications is described below.

## Containers and Volumes

The compose file will run the following containers:

* mysql
* slurmdbd
* slurmctld
* c1 (slurmd)
* c2 (slurmd)
* c3 (slurmd)
* c4 (slurmd)

The compose file will create the following named volumes:

* etc_munge         ( -> /etc/munge          )
* etc_slurm         ( -> /etc/slurm-llnl     )
* slurm_jobdir      ( -> /data               )
* var_lib_mysql     ( -> /var/lib/mysql      )
* var_log_slurm     ( -> /var/log/slurm-llnl )

## Building the Docker Image

Build the image locally:

```console
# instructions to come
```

## Starting the Slurm Cluster

Run `docker-compose` to instantiate the cluster:

```console
docker-compose up -d
```

## Register the Cluster with SlurmDBD

To register the cluster to the slurmdbd daemon, run the `register_cluster.sh`
script:

```console
./register_cluster.sh
```

> Note: You may have to wait a few seconds for the cluster daemons to become
> ready before registering the cluster.  Otherwise, you may get an error such
> as **sacctmgr: error: Problem talking to the database: Connection refused**.
>
> You can check the status of the cluster by viewing the logs: `docker-compose
> logs -f`

## Accessing the Cluster

Use `docker exec` to run a bash shell on the controller container:

```console
docker exec -it slurmctld bash
```

From the shell, execute slurm commands, for example:


## Submitting Jobs

The `slurm_jobdir` named volume is mounted on each Slurm container as `/data`.
Therefore, in order to see job output files while on the controller, change to
the `/data` directory when on the **slurmctld** container and then submit a job:

```console
[root@slurmctld /]# cd /data/
[root@slurmctld data]# sbatch --wrap="uptime"
Submitted batch job 2
[root@slurmctld data]# ls
slurm-2.out
```

## Stopping and Restarting the Cluster

```console
docker-compose stop
docker-compose start
```

## Deleting the Cluster

To remove all containers and volumes, run:

```console
docker-compose stop
docker-compose rm -f
docker volume prune # make sure you don't have others you still want to keep
```
