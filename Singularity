Bootstrap: docker
From: ubuntu:latest

%post
    apt-get clean && apt-get update
    apt-get install -y locales
    localedef -i en_US -f UTF-8 en_US.UTF-8
    apt-get install -y build-essential
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y cmake
    apt-get install -y cmake-curses-gui
    apt-get install -y git
    apt-get install -y vim
    apt install -y software-properties-common
    add-apt-repository -y  ppa:deadsnakes/ppa
    apt install -y python3.8
    apt install -y python
    apt-get install -y bc
    apt-get install -y unzip
    apt-get install -y wget
    apt-get install -y libpcre3-dev
    apt-get install -y  python3-pip
    pip3 install --user wheel
    wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
    apt-get install -y gnupg
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
    rm GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
    echo "deb https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list
    apt-get update
    apt-get install -y intel-hpckit
    git clone https://github.com/RRZE-HPC/likwid.git
    cd likwid
    cp config.mk config_old.mk
    sed -e "s@ACCESSMODE = accessdaemon@ACCESSMODE = perf_event@g" config_old.mk > config.mk
    make  && make install
    cd -
    echo "export PATH=\"${PATH}\"" >> $SINGULARITY_ENVIRONMENT

%help
    This is a singularity container that reproduces result from CGO2021 paper
    "YaskSite – Stencil Optimization Techniques Appliedto Explicit ODE Methods
    on Modern Architectures". 
    There are different apps available to find help of each app use the following:
    'singularity run-help --app <app_name> <container_name>'.
    Following are the available apps:
    * build (This is the first app to run before anything else)
    * YaskSite (advanced, not needed to reproduce results)
    * Offsite (advanced, not needed to reproduce results)
    * Fig3
    * Fig4
    * Fig5
    * Fig6-prediction
    * Fig6-measurement

%environment
   export SINGULARITY_BASE_PATH=${PWD}
   #export SINGULARITY_RUN_PATH=${PATH}
   export PYTHONPATH=${SINGULARITY_BASE_PATH}/installkit/lib/python3.8/site-packages/
   export PATH=$PATH:${SINGULARITY_BASE_PATH}/installkit/bin/

###### Build YaskSite, it has to be done on the running machine therefore as runscript #######
%apphelp build
    App for building YaskSite, kerncraft and Offsite. This is the first app to run before running anything else.
    It installs YaskSite, since it detects the machine when building this build process is made as
    an app and user should run this on the machine where they are running the rest of the benchmarks.
    Currently YaskSite supports the following architecures Intel Sandy Bridge, Ivy Bridge, Haswell, Broadwell, Skylake, Cascade Lake  and AMD Naples, ROME.
    To run it use 'singularity run --app build <container_name>'

%apprun build
    cd ${SINGULARITY_BASE_PATH}    
    rm kerncraft -rf
    rm Offsite -rf
    rm installkit -rf
    rm tmp -rf
    rm tmp_YaskSite -rf
    rm YaskSite -rf

    #wget TODO
    git clone https://github.com/seasite-project/YaskSite.git
    cd YaskSite
    mkdir build && cd build
    bash -c "source /opt/intel/oneapi/setvars.sh && CC=icc CXX=icpc cmake .. -DI_AGREE_ALL_TERMS_AND_CONDITIONS=true -DCMAKE_INSTALL_PREFIX=${SINGULARITY_BASE_PATH}/installkit -DTEMP_DIR=${SINGULARITY_BASE_PATH}/tmp_YaskSite -DLIKWID_LIBRARIES=/usr/local/lib/liblikwid.so -DLIKWID_INCLUDE_DIR=/usr/local/include && make && make install"
    cd ../example
    mkdir build && cd build
    bash -c "source /opt/intel/oneapi/setvars.sh && CC=icc CXX=icpc cmake .. -DyaskSite_DIR=${SINGULARITY_BASE_PATH}/installkit && make"
    cd ${SINGULARITY_BASE_PATH}
    cd run_variant/YaskSite
    mkdir -p  build
    cd build
    bash -c "source /opt/intel/oneapi/setvars.sh && CC=icc CXX=icpc cmake .. -DyaskSite_DIR=${SINGULARITY_BASE_PATH}/installkit && make"
    cd ${SINGULARITY_BASE_PATH}
    echo "Building YaskSite success"

    cd $SINGULARITY_BASE_PATH
    
    git clone https://github.com/RRZE-HPC/kerncraft && cd kerncraft
    git checkout v0.8.5
    export PYTHONPATH=${SINGULARITY_BASE_PATH}/installkit/lib/python3.8/site-packages/
    export PATH=$PATH:${SINGULARITY_BASE_PATH}/installkit/bin/
    python3 setup.py bdist_wheel && pip3 install --prefix=${SINGULARITY_BASE_PATH}/installkit dist/kerncraft*.whl
    iaca_get --I-accept-the-Intel-What-If-Pre-Release-License-Agreement-and-please-take-my-soul
    cd $SINGULARITY_BASE_PATH
    wget https://zenodo.org/record/4282544/files/seasite-project/Offsite-v0.2.0cgoAD.zip?download=1 -O Offsite.zip
    unzip Offsite.zip -d Offsite
    cd Offsite/seasite-project-Offsite-d8455cc
    python3 setup.py bdist_wheel && pip3 install --prefix=${SINGULARITY_BASE_PATH}/installkit dist/offsite*.whl
    cd $SINGULARITY_BASE_PATH
    echo "Building Offsite success"

##### App for running yasksite ######
%apphelp YaskSite
    This is the complete YaskSite app. To see help options type 'singularity run --app YaskSite <container_name> "-h"'.
    Remember: Please pass arguments as a string, i.e., for example to run Wave3D, radius 1 with 20 cores and inner-dimensions in range 500:20:800 on Cascade Lake Gold 6248
    use 'singularity run --app YaskSite <container_name> "-k Wave3D:3 -m machines/CascadelakeSP_Gold-6248.yml -R 500:20:800 -c 20 -t 1 -f auto -r 1 -O spatial -o <out folder>"'

%apprun YaskSite
    cd $SINGULARITY_BASE_PATH
    echo "Running YaskSite with arguments $*"
    threads=$(echo "$*" | grep -o -P '(?<=\-c).*?(?=\-)')
    echo "executing export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid $@"
    bash -c "export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid $@"

###### App for reproducing Fig. 3 plots #######
%apphelp Fig3
    Reproduces result in Figure 3 of the paper. Input arguments are machine file, threads, radius, and output folder. 
    For reproducing the results in paper set threads to number of cores on 1 socket (20 on Intel Cascade Lake which we tested). 
    The machine file corresponding to the architecture under consideration is  machines/CascadelakeSP_Gold-6248.yml.
    For example for radius 1 run : 'singularity run --app Fig3 <container_name> "-m <machine_file> -c <ncores> -r 1 -o <out_folder>"'

%apprun Fig3
    cd $SINGULARITY_BASE_PATH
    echo "Running Fig3 with arguments $*"
    threads=$(echo "$*" | grep -o -P '(?<=\-c).*?(?=\-)')
    echo "executing export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid -k Wave3D:3 -t 1 -R 20:20:1000 -f auto -O plain:spatial $@"
    bash -c "export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid -k Wave3D:3 -t 1 -R 20:20:1000 -f auto -O plain:spatial $@"

###### App for reproducing Fig. 4 plots #######
%apphelp Fig4
    Reproduces result in Figure 4 of the paper. Input arguments are machine file, threads, radius, and output folder. 
    For reproducing the results in paper set threads to number of cores on 1 socket.
    The machine file corresponding to our architecture is machines/CascadelakeSP_Gold-6248.yml and machines/Zen_ROME-7452.yml
    For example for radius 1 and spatial blocking (analytical) run : 'singularity run --app Fig4 <container_name> "-m <machine_file> -c <ncores> -r 1 -o <out_folder>"'
    The file in <out_folder> called 'plain', 'spatial' and 'AT' corrspond to 'plain', 'analytical' and 'GD' keywords.
    The plot is produced by taking the statistics over all sizes in the output files.

%apprun Fig4
    cd $SINGULARITY_BASE_PATH
    echo "Running Fig4 with arguments $*"
    threads=$(echo "$*" | grep -o -P '(?<=\-c).*?(?=\-)')
    echo "executing export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid -k Wave3D:3 -t 1 -R 20:20:1000 -f auto -O plain:spatial:AT $@"
    bash -c "export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid -k Wave3D:3 -t 1 -R 20:20:1000 -f auto -O plain:spatial:AT $@"

###### App for reproducing Fig. 5 plots #######
%apphelp Fig5
    Reproduce result in Figure 5 of the paper. Input arguments are machine file, threads, radius, fold and output folder.
    For reproducing the results in paper set threads to number of cores on 1 socket (20 on Intel Cascade Lake which we tested).
    The machine file corresponding to the architecture under consideration is  machines/CascadelakeSP_Gold-6248.yml.
    For example for radius 1, fold 1:8:1 run : 'singularity run --app Fig5 <container_name> "-m <machine_file> -c <ncores> -r 1 -f 1:8:1 -o <out_folder>"'

%apprun Fig5
    cd $SINGULARITY_BASE_PATH
    echo "Running Fig5 with arguments $*"
    threads=$(echo "$*" | grep -o -P '(?<=\-c).*?(?=\-)')
    echo "executing export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid -k Wave3D:3 -t 1 -R 20:20:400 -O plain $@"
    bash -c "export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && likwid-pin -c S0:0-$((threads-1)) perf_wo_likwid -k Wave3D:3 -t 1 -R 20:20:400 -O plain $@"

##### App for running Offsite ########
%apphelp Offsite
    App for running Offsite. Please refer to Offsite help to get more information on input arguments.
    Offsite help can be found by using 'singularity run --app Offsite <container_name> "-h"'.
    Run Offsite using 'singularity run --app Offsite <container_name> "<input_arguments>"'.


%apprun Offsite
    cd $SINGULARITY_BASE_PATH
    echo "Running Offsite with arguments $*"
    bash -c "PYTHONPATH=${SINGULARITY_BASE_PATH}/installkit/lib/python3.8/site-packages/ && PATH=$PATH:YaskSite/example/build:${SINGULARITY_BASE_PATH}/installkit/bin/ && source /opt/intel/oneapi/setvars.sh && offsite_tune $@"

#### App for running Fig6 and Table 3 prediction #######
%apphelp Fig6-prediction
    Reproduce prediction results in Figure 6 and Table 3 of the paper with the use of Offsite.
    Input arguments are machine file, config file, benchmark results, ivp and
    output database file name. For example for Intel Cascade Lake on which we
    tested and Wave3d IVP with radius 2 use 
    'singularity run --app Fig6-prediction <container_name> "--machine machines/CascadelakeSP_Gold-6248.yml --config config/config_clx.tune --bench bench/OMP_BARRIER_CascadelakeSP_Gold-6248_icc19.0.2.187.bench --ivp ivps/Wave3D_radius2.ivp --db out.db"'
    The output will be in 'out.db'
    Expect 8-10 hours to run this, since it generates different YASK kernels and tests them.
    Also it needs diskspace (10 GB) as the generated kernels will be cached for later execution in Fig6-measurements app.

%apprun Fig6-prediction
    export PYTHONPATH=${SINGULARITY_BASE_PATH}/installkit/lib/python3.8/site-packages/
    export PATH=$PATH:${SINGULARITY_BASE_PATH}/installkit/bin/
    cd $SINGULARITY_BASE_PATH
    echo "Running Fig6-prediction with arguments $*"
    echo "excuting export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && offsite_tune --tool yasksite --compiler icc --impl impls/pirk/ --kernel kernels/pirk/ --method methods/implicit/radauIIA7. ode --mode MODEL --verbose --filter-yasksite-opt $@"
    bash -c "export PATH=$PATH:YaskSite/example/build && source /opt/intel/oneapi/setvars.sh && offsite_tune --tool yasksite --compiler icc --impl impls/pirk/ --kernel kernels/pirk/ --method methods/implicit/radauIIA7. ode --mode MODEL --verbose --filter-yasksite-opt $@"

#### App for running Fig6 and Table 3 measurement #####
%apphelp Fig6-measurement
    Reproduce measurement results in Figure 6 and Table 3 of the paper.
    This can be run only after running 'Fig6-prediction' app, since the cached kernels produced by 'Fig6-prediction' is required here.
    The input arguments are number of threads, machine file, kernel, radius, output folder and config file.
    For example for running Wave3D, radius 2, on Intel Cascade Lake 6248 use:
    'singularity run --app Fig6-measurement <container_name> "-m machines/CascadelakeSP_Gold-6248.yml -k Wave3D -r 2 --config config/config_clx.tune -o measurements"'
    This will write results to a folder called 'measurements'.

%apprun Fig6-measurement
    cd $SINGULARITY_BASE_PATH
    cd run_variants/YaskSite/build
    echo "Running Fig6-measurement with arguments $*"
    echo "executing source /opt/intel/oneapi/setvars.sh && run_variant/YaskSite/run_script.sh -p run_variant/YaskSite/build $@"
    bash -c "source /opt/intel/oneapi/setvars.sh && run_variant/YaskSite/run_script.sh -p run_variant/YaskSite/build $@"
