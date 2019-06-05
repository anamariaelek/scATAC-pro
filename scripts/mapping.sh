#!/bin/bash

set -e

fastqs=$1
## align

mapRes_dir="${2}/mapping_result"
mkdir -p $mapRes_dir
curr_dir=`dirname $0`

if [ $MAPPING_METHOD == "bwa" ];then
     ${curr_dir}/mapping_bwa.sh $fastqs $mapRes_dir
elif [ $MAPPING_METHOD == "bowtie" ];then
     ${curr_dir}/mapping_bowtie.sh $fastqs $mapRes_dir
else
     ${curr_dir}/mapping_bowtie2.sh $fastqs $mapRes_dir
fi




## sort
echo "Sorting bam file"

ncore=$(nproc --all)
ncore=$(($ncore - 1))
mkdir -p ${mapRes_dir}/tmp
${SAMTOOLS_PATH}/samtools sort -T ${mapRes_dir}/tmp/ -@ $ncore -n -o ${mapRes_dir}/${OUTPUT_PREFIX}.sorted.bam ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.bam
rm ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.bam


## to mark duplicates
${SAMTOOLS_PATH}/samtools fixmate -@ $ncore -m ${mapRes_dir}/${OUTPUT_PREFIX}.sorted.bam ${mapRes_dir}/${OUTPUT_PREFIX}.fixmate.bam
rm ${mapRes_dir}/${OUTPUT_PREFIX}.sorted.bam

# Markdup needs position order
${SAMTOOLS_PATH}/samtools sort -@ $ncore -T ${mapRes_dir}/tmp/ -o ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort0.bam ${mapRes_dir}/${OUTPUT_PREFIX}.fixmate.bam
rm ${mapRes_dir}/${OUTPUT_PREFIX}.fixmate.bam

## mark duplicates
${SAMTOOLS_PATH}/samtools markdup -@ $ncore ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsorto.bam ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.bam
rm ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort0.bam


${SAMTOOLS_PATH}/samtools index -@ $ncore ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.bam 



## filtering low quality and/or deplicates for downstreame analysis
${SAMTOOLS_PATH}/samtools view -f 0x2 -b -h -q 30 -@ $ncore ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.bam -o ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.MAPQ30.bam 
#${SAMTOOLS_PATH}/samtools markdup -r -@ $ncore ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.MAPQ30.bam ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.dedup.positionsort.MAPQ30.bam 



## mapping stats
echo "Summarizing mapping stats ..."

curr_dir=`dirname $0`
qc_dir=${2}/qc_result
mkdir -p $qc_dir
bash ${curr_dir}/mapping_qc.sh ${mapRes_dir}  $2


if [ $MAPQ ne 30 ]; then
     ${SAMTOOLS_PATH}/samtools view -f 0x2 -b -h -q $MAPQ -@ $ncore ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.bam -o ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.MAPQ${MAPQ}.bam 
 #    ${SAMTOOLS_PATH}/samtools markdup -r -@ $ncore ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.MAPQ${MAPQ}.bam ${mapRes_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.dedup.MAPQ${MAPQ}.bam 
fi



echo "Simple mapping stats summary Done!"



