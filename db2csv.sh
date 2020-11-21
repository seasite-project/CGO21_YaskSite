#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
         --db)
            dbFile="$2"
            shift # past argument
            shift # past value
            ;;
        -m|--machine)
            mcFile="$2"
            shift # past argument
            shift # past value
            ;;
        --ivp)
            ivpFile="$2"
            shift # past argument
            shift # past value
            ;;
        -o|--out)
            outFolder="$2"
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

ivp=$(basename ${ivpFile} ".ivp")
impls_rome="1,3,5,7,9,11,13,15,17,18,19,20,21,22,23,24"
impls_clx="1,3,5,7,9,11,13,15,17,19,21,22,23,24,25,26,27,28,29,30"
isClx=$(echo $mcFile | grep "CascadelakeSP_Gold-6248")
isRome=$(echo $mcFile | grep "Zen_ROME-7452.yml")

impl_name_clx="A_il_8_1_1_plain_20_derived.csv, F_il_8_1_1_plain_20_derived.csv, A_il_1_8_1_plain_20_derived.csv,  F_il_1_8_1_plain_20_derived.csv, A_il_1_1_8_plain_20_derived.csv,   F_il_1_1_8_plain_20_derived.csv, A_il_2_2_2_plain_20_derived.csv,   F_il_2_2_2_plain_20_derived.csv, A_il_1_2_4_plain_20_derived.csv,   F_il_1_2_4_plain_20_derived.csv, A_il_8_1_1_spatial_20_derived.csv, F_il_8_1_1_spatial_20_derived.csv, A_il_1_8_1_spatial_20_derived.csv, F_il_1_8_1_spatial_20_derived.csv, A_il_1_1_8_spatial_20_derived.csv, F_il_1_1_8_spatial_20_derived.csv, A_il_2_2_2_spatial_20_derived.csv, F_il_2_2_2_spatial_20_derived.csv, A_il_1_2_4_spatial_20_derived.csv, F_il_1_2_4_spatial_20_derived.csv"

#TODO: Make sure both lists in the proper order (matching predictions and runtimes!)
impl_id_clx="impl_1.csv, impl_21.csv, impl_3.csv, impl_22.csv, impl_5.csv, impl_23.csv, impl_7.csv, impl_24.csv, impl_9.csv, impl_25.csv, impl_11.csv, impl_26.csv, impl_13.csv, impl_27.csv, impl_15.csv, impl_28.csv, impl_17.csv, impl_29.csv, impl_19.csv, impl_30.csv"

impl_name_rome="A_il_4_1_1_plain_32_derived.csv, F_il_4_1_1_plain_32_derived.csv, A_il_1_4_1_plain_32_derived.csv, F_il_1_4_1_plain_32_derived.csv,A_il_1_1_4_plain_32_derived.csv, F_il_1_1_4_plain_32_derived.csv, A_il_1_2_2_plain_32_derived.csv, F_il_1_2_2_plain_32_derived.csv, A_il_4_1_1_spatial_32_derived.csv, F_il_4_1_1_spatial_32_derived.csv, A_il_1_4_1_spatial_32_derived.csv, F_il_1_4_1_spatial_32_derived.csv, A_il_1_1_4_spatial_32_derived.csv, F_il_1_1_4_spatial_32_derived.csv, A_il_1_2_2_spatial_32_derived.csv, F_il_1_2_2_spatial_32_derived.csv"

#TODO: Make sure both lists in the proper order (matching predictions and runtimes!)
impl_id_rome="impl_1.csv, impl_17.csv, impl_3.csv, impl_18.csv, impl_5.csv, impl_19.csv, impl_7.csv, impl_20.csv, impl_9.csv, impl_21.csv, impl_11.csv, impl_22.csv, impl_13.csv, impl_23.csv, impl_15.csv, impl_24.csv"

if [ ! -z "$isClx" ]; then
    impls=${impls_clx}
    impl_name=${impl_name_clx}
    impl_id=${impl_id_clx}
else
    if [ ! -z "$isRome" ]; then
        impls=${impls_rome}
        impl_name=${impl_name_rome}
        impl_id=${impl_id_rome}
    else
        echo "Error: DB to CSV conversion only works for provided machine in the paper"
    fi
fi
freq_wo_scaling=$(cat ${mcFile} | grep "clock:" | cut -d":" -f2 | cut -d"G" -f1)
freq=$(echo "$freq_wo_scaling*1000000000" | bc -l)
cores=$(cat ${mcFile} | grep "cores per socket:" | cut -d":" -f2)
echo "freq = $freq"
echo "cores = $cores"

mkdir -p ${outFolder}
cd ${outFolder}

offsite_impl2csv --db ${dbFile} --machine 1 --compiler 1 --cores ${cores} --frequency ${freq} --method radauIIa7 --ivp ${ivp} --N 20:720:20 --impl "${impls}"

cd -

totCtr=$(echo ${impl_name} | grep -o "," | wc -l)
for (( ctr=1; ctr<=${totCtr}+1; ++ctr )); do
    cur_impl_name_w_space=$(echo ${impl_name} | cut -d"," -f$ctr)
    cur_impl_name=$(echo "${cur_impl_name_w_space}" | xargs)
    cur_impl_id_w_space=$(echo ${impl_id} | cut -d"," -f$ctr)
    cur_impl_id=$(echo "${cur_impl_id_w_space}" | xargs)
    echo "cp ${outFolder}/${cur_impl_id} ${outFolder}/${cur_impl_name}"
    cp "${outFolder}/${cur_impl_id}" "${outFolder}/${cur_impl_name}"
done
