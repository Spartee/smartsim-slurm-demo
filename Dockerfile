FROM ubuntu:20.04

LABEL maintainer="Sam Partee"

ARG DEBIAN_FRONTEND="noninteractive"
ENV TZ=US/Seattle
RUN apt-get update \
    && apt-get install --no-install-recommends -y build-essential \
    git gcc make ruby ruby-dev libpam0g-dev libmysqlclient-dev \
    python3-pip python3 python3-dev wget bzip2 cmake openssl numactl \
    hwloc lua5.3 man2html gosu vim unzip libopenmpi-dev openmpi-bin \
    libhdf5-openmpi-dev \
    && gosu nobody true

RUN ln -s /usr/bin/python3 /usr/bin/python

env MUNGEUSER=966
RUN groupadd -r -g $MUNGEUSER munge
RUN useradd  -r -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge
env SLURMUSER=967
RUN groupadd -r -g $SLURMUSER slurm
RUN useradd  -r -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

# install munge
RUN apt install -y munge libmunge-dev libmunge2 rng-tools slurm-wlm slurmdbd mysql-server -y \
    && rm -rf /var/lib/apt/lists/*
RUN rngd -r /dev/urandom

RUN /usr/sbin/create-munge-key -r -f

RUN sh -c  "dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key"
RUN chown munge: /etc/munge/munge.key
RUN chmod 400 /etc/munge/munge.key

COPY slurm.conf /etc/slurm-llnl/slurm.conf
COPY slurmdbd.conf /etc/slurm-llnl/slurmdbd.conf

RUN mkdir /data
RUN mkdir -p /var/run/slurm-llnl \
    && touch /var/lib/slurm-llnl/slurmd/node_state \
        /var/lib/slurm-llnl/slurmd/front_end_state \
        /var/lib/slurm-llnl/slurmd/job_state \
        /var/lib/slurm-llnl/slurmd/resv_state \
        /var/lib/slurm-llnl/slurmd/trigger_state \
        /var/lib/slurm-llnl/slurmd/assoc_mgr_state \
        /var/lib/slurm-llnl/slurmd/assoc_usage \
        /var/lib/slurm-llnl/slurmd/qos_usage \
        /var/lib/slurm-llnl/slurmd/fed_mgr_state \
    && chown -R slurm:slurm /var/*/slurm-llnl/slurm*

WORKDIR /data
RUN python -m pip install cmake ipython \
    && git clone https://github.com/CrayLabs/SmartSim.git --branch develop --depth=1 \
    && cd SmartSim \
    && pip install -e .[dev] \
    && smart -v --device=cpu --no_tf

ADD LAMMPS-SmartSim /data/lammps-examples/
RUN cd /data/lammps-examples/melt/SmartRedis \
    && pip install -e . \
    && make lib \
    && rm -rf third-party
RUN cd /data/lammps-examples/melt/lammps \
    && mkdir build \
    && cd build \
    && cmake ../cmake -DBUILD_MPI=yes -DPKG_SMARTSIM=ON \
    && make -j $(nproc) \
    && cd ../ && rm -rf examples

RUN pip install jupyter jupyterlab
ENV PATH="/data/lammps-examples/melt/lammps/build/:${PATH}"
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

ADD LAMMPS-SmartSim/melt/lammps_online_da.ipynb /data/lammps-examples/melt/
ADD LAMMPS-SmartSim/melt/PT-processing-and-inference.ipynb /data/lammps-examples/melt/

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
