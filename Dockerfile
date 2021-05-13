#FROM ubuntu:16.04
#FROM ubuntu:xenial-20160923.1
FROM ubuntu:bionic
# Original maintainer
#MAINTAINER Ewan Barr "ebarr@mpifr-bonn.mpg.de"
#Current MAINTAINER
MAINTAINER Stephen Ord "stephen.ord@csiro.au"

# Suppress debconf warnings
ENV DEBIAN_FRONTEND noninteractive

# Switch account to root and adding user accounts and password
USER root
RUN echo "root:root" | chpasswd && \
    mkdir -p /root/.ssh 

# Create psr user which will be used to run commands with reduced privileges.
RUN adduser --disabled-password --gecos 'unprivileged user' psr && \
    echo "psr:psr" | chpasswd && \
    mkdir -p /home/psr/.ssh && \
    chown -R psr:psr /home/psr/.ssh

# Create space for ssh daemon and update the system
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu bionic main multiverse' >> /etc/apt/sources.list && \
    mkdir -p /var/run/sshd && \
    mkdir -p /run/sshd && \
    apt-get -y check && \
    apt-get -y update && \
    apt-get install -y apt-utils apt-transport-https software-properties-common python3-software-properties && \
    apt-get -y update --fix-missing && \
    apt-get -y upgrade 

# Install dependencies
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu bionic main multiverse' >> /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get --no-install-recommends -y install \
    build-essential \
    ssh \
    sudo \
    autoconf \
    autotools-dev \
    automake \
    autogen \
    libtool \
    pkg-config \
    csh \
    gcc \
    gfortran \
    wget \
    git \
    libcfitsio-dev \
    pgplot5 \
    swig3.0 \
    python \
    python-dev \
    python-pip \
    libfftw3-3 \
    libfftw3-bin \
    libfftw3-dev \
    libfftw3-single3 \
    libx11-dev \
    libpng16-16\
    libpng-dev \
    libpnglite-dev \
    libhdf5-100 \
    libhdf5-cpp-100 \
    libhdf5-dev \
    libhdf5-serial-dev \
    libxml2 \
    libxml2-dev \
    libltdl-dev \
    gsl-bin \
    libgsl-dev \
    libgsl23 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y clean

# Install python packages
RUN pip install pip -U && \
    pip install setuptools -U && \
    pip install numpy -U && \
    pip install scipy -U && \
    pip install watchdog && \
    pip install matplotlib -U 

# PGPLOT
ENV PGPLOT_DIR /usr/lib/pgplot5
ENV PGPLOT_FONT /usr/lib/pgplot5/grfont.dat
ENV PGPLOT_INCLUDES /usr/include
ENV PGPLOT_BACKGROUND white
ENV PGPLOT_FOREGROUND black
ENV PGPLOT_DEV /xs

USER psr
ENV HOME /home/psr
ENV PSRHOME /home/psr/software/
RUN mkdir -p /home/psr/.ssh
WORKDIR $PSRHOME 

# Pull all repos
COPY scripts/get_repos.sh get_repos.sh
RUN /bin/bash get_repos.sh
# Psrcat
ENV PSRCAT_FILE $PSRHOME/psrcat_tar/psrcat.db
ENV PATH $PATH:$PSRHOME/psrcat_tar
WORKDIR $PSRHOME/psrcat_tar
RUN /bin/bash makeit && \
    rm -f ../psrcat_pkg.tar.gz

# PSRXML
ENV PSRXML $PSRHOME/psrxml
ENV PATH $PATH:$PSRXML/install/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRXML/install/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRXML/install/include
WORKDIR $PSRXML
RUN autoreconf --install --warnings=none
RUN ./configure --prefix=$PSRXML/install && \
    make -j && \
    make install && \
    rm -rf .git

# tempo2
ENV TEMPO2 $PSRHOME/tempo2/T2runtime
ENV PATH $PATH:$PSRHOME/tempo2/T2runtime/bin
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRHOME/tempo2/T2runtime/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRHOME/tempo2/T2runtime/lib
WORKDIR $PSRHOME/tempo2
RUN sync && perl -pi -e 's/chmod \+x/#chmod +x/' bootstrap # Get rid of: returned a non-zero code: 126.
RUN ./bootstrap && \
    ./configure --x-libraries=/usr/lib/x86_64-linux-gnu --enable-shared --enable-static --with-pic F77=gfortran && \
    make -j $(nproc) && \
    make install && \
    make plugins-install && \
    rm -rf .git

# PSRCHIVE
ENV PSRCHIVE $PSRHOME/psrchive
ENV PATH $PATH:$PSRCHIVE/install/bin
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRCHIVE/install/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRCHIVE/install/lib
ENV PYTHONPATH $PSRCHIVE/install/lib/python2.7/site-packages
WORKDIR $PSRCHIVE
RUN ./bootstrap && \
    ./configure --prefix=$PSRCHIVE/install --x-libraries=/usr/lib/x86_64-linux-gnu --disable-python --with-psrxml-dir=$PSRXML/install --enable-shared --enable-static F77=gfortran LDFLAGS="-L"$PSRXML"/install/lib" LIBS="-lpsrxml -lxml2" && \
    make -j $(nproc) && \
    make && \
    make install && \
    rm -rf .git
WORKDIR $PSRHOME
RUN echo "Predictor::default = tempo2" >> .psrchive.cfg && \
    echo "Predictor::policy = default" >> .psrchive.cfg

USER root
# Configure sudo.
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu bionic main multiverse' >> /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get --no-install-recommends -y install \
    vim \
    xauth \
    xorg 

RUN ex +"%s/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/g" -scwq! /etc/sudoers
RUN usermod -aG sudo psr
RUN usermod -s /bin/bash psr

ADD bashrc /home/psr/.bashrc
RUN chown psr:psr /home/psr/.bashrc
ADD psrchive_user.pub /home/psr/.ssh/authorized_keys
RUN chown psr:psr /home/psr/.ssh/authorized_keys

USER psr
