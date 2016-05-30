#Build directory: notebook/
#tag: notebook
FROM phusion/baseimage


#Commands for base
RUN apt-get update


#Commands for base_install
RUN apt-get -y install \
    build-essential \
    libcr-dev \
    mpich2 \
    mpich2-doc \
    cmake \
    git \
    subversion \
    mercurial \
    libfftw3-dev \
    libbz2-dev \
    libopenmpi-dev \
    libtool \
    swig \
    wget \
    liblapack-dev \
    libblas-dev \
    gfortran \
    csh \
    tcsh \
    cmake-curses-gui \
    libhdf5-dev \
    libatlas-dev \
    liblapack-dev \
    patch \
    autoconf \
    automake \
    libnetcdf-dev \
    doxygen \
    curl \
    file \
    tmux \
    unzip \
    gettext \
    libreadline-dev \
    libncurses-dev \
    libpcre3-dev \
    libgnutls28 \
    libssl-dev \
    m4 \
    patch \
    perl


#Commands for python_install
RUN apt-get install -y \
  python \
  python-dev \
  python-pip \
  # python-numpy \
  # python-scipy \
  # python-pandas \
  # python-scikits-learn \
  python-h5py \
  python-mpi4py \
  python-sympy \
  python-yaml \
  python-zmq \
  python-tornado \
  Cython \
  gfortran \
  zlib1g-dev \
  libzmq-dev \
  pkg-config \
  libfreetype6-dev \
  netpbm \
  libpng12-dev
ENV PYTHONPATH=/opt

#Commands for notebook
RUN apt-get install -y python-matplotlib
RUN pip install \
    ipython==4.1.2 \
    jupyter \
    ipywidgets==4.1.1
# ENTRYPOINT /run_notebook.sh
# Julia

RUN mkdir -p /opt/ && \
    cd /opt && \
    git clone git://github.com/JuliaLang/julia.git && \
    cd /opt/julia && \
    make && \
    cd /

# RUN ln -fs /opt/julia_0.5.0 /opt/julia

RUN echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/julia/usr/bin\"" > /etc/environment && \
    echo "export PATH" >> /etc/environment && \
    echo "source /etc/environment" >> /root/.bashrc

RUN /opt/julia/usr/bin/julia -e 'Pkg.add("IJulia")'

ENV TERM=xterm
ENTRYPOINT /bin/bash
EXPOSE 8888
RUN mkdir /notebooks
WORKDIR /notebooks
COPY run_notebook.sh /run_notebook.sh
