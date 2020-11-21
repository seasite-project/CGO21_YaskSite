#!/bin/bash


POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -c|--cores)
            CORES="$2"
            shift # past argument
            shift # past value
            ;;
        -m|--machine)
            MACHINEFILE="$2"
            shift # past argument
            shift # past value
            ;;
        -k)
            KERNEL="$2"
            shift # past argument
            shift # past value
            ;;
        -r)
            RADIUS="$2"
            shift # past argument
            shift # past value
            ;;
        -o)
            OUTFOLDER="$2"
            shift # past argument
            shift # past value
            ;;
        -p)
            RUN_PATH="$2"
            shift # past argument
            shift # past value
            ;;
        --config)
            CONFIG_FILE="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


opts_w_space=$(cat ${CONFIG_FILE} | grep "blocking =.*" | cut -d"=" -f2 | sed -e "s@;@@g")
opts=$(echo ${opts})

#folds="8:1:1 1:8:1"
folds_w_space=$(cat ${CONFIG_FILE} | grep "folding =.*" | cut -d"=" -f2 | sed -e "s@;@@g")
folds=$(echo ${folds_w_space})

runFolder="${RUN_PATH}"

machine=${MACHINEFILE}
cores=${CORES}
kernel=${KERNEL}
radius=${RADIUS}
resultFolder=${OUTFOLDER}
vars="ys_F_il ys_A_il"
#ys_C_il"
start_size=40
end_size=750
fold_factor=1
inner_pad=32

resultFolder="${resultFolder}/${kernel}_r${radius}"

mkdir -p ${resultFolder}

inc=20

for var in ${vars}; do
    for fold in ${folds}; do
        for opt in ${opts}; do
            for core in ${cores}; do
                fold_str=$(echo $fold | sed -e "s@:@_@g")
                finalFolder="${resultFolder}/${var}/${fold_str}/${opt}/${core}"
                mkdir -p ${finalFolder}
                exec_file="${runFolder}/${var}"

                derived_file="${finalFolder}/derived.txt"
                raw_file="${finalFolder}/raw.txt"
                printf "%10s, %10s, %10s, %10s, %10s, %10s, %10s, %10s\n" "size" "middle_size" "impl_time" "impl_perf" "sat" "bx" "by" "bz" > ${derived_file}
                echo "$var $fold $opt $core" > ${raw_file}
                for((size_wo=${start_size};size_wo<=${end_size};size_wo=${size_wo}+inc)); do
                    size_float=$(echo "${size_wo}/${fold_factor}" | bc -l)
                    size=${size_float%.*}
                    size_float=$(echo "${size}*${fold_factor}" | bc -l)
                    size=${size_float%.*}
                    #inner_size_float=$(echo "(${size}-1)/${inner_pad}" | bc -l)
                    #inner_size=${inner_size_float%.*}
                    #inner_size_float=$(echo "(${inner_size}+1)*${inner_pad}" | bc -l)
                    #inner_size=${inner_size_float%.*}
                    echo ${size} >> ${raw_file}
                    OMP_NUM_THREADS=${core} OMP_PLACES=cores OMP_PROC_BIND=close
                    likwid-pin -c S0:0-$((core-1)) $exec_file -c ${core} -s ${size}:${size}:${size} -C 6 -S 4 -f ${fold} -o ${opt} -k ${kernel} -r ${radius} -m ${machine} > tmp.txt
                    cat tmp.txt >>${raw_file}
                    impl_time=$(grep "Total time per iter" tmp.txt | cut -d"=" -f2 | cut -d"s" -f 1)
                    impl_perf=$(grep "Total performance" tmp.txt | cut -d"=" -f2 | cut -d"M" -f 1)
                    #inc_float=$(echo "${size}*0.04" | bc -l)
                    #inc=${inc_float%.*}
                    sat=$(grep "saturating at =" tmp.txt | cut -d"=" -f2)
                    block_x=$(grep "block_x =" tmp.txt | cut -d"=" -f2)
                    block_y=$(grep "block_y =" tmp.txt | cut -d"=" -f2)
                    block_z=$(grep "block_z =" tmp.txt | cut -d"=" -f2)
                    printf "%10d, %10d, %10.6f, %10.4f, %10.4f, %10d, %10d, %10d\n" ${size} ${size} ${impl_time} ${impl_perf} ${sat} ${block_x} ${block_y} ${block_z}>> ${derived_file}
                done
            done
        done
    done
done
