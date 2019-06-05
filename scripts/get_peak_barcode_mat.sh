#!/bin/bash

### will search bam file under ouptu_dir/mapping_resutl
set -e

input_peaks=$1
output_dir=$2

mat_dir="${output_dir}/raw_matrix"
mkdir -p $mat_dir

input_bam=${output_dir}/mapping_result/${OUTPUT_PREFIX}.${MAPPING_METHOD}.positionsort.MAPQ${MAPQ}.bam

ncore=$(nproc --all)
ncore=$(($ncore - 1))



curr_dir=`dirname $0`
if [[ ! -f ${mat_dir}/fragments.bed ]]; then
   if [[ ! -f ${mat_dir}/tmp.sam ]]; then
     echo "Converting bam to sam"
     ${SAMTOOLS_PATH}/samtools view -h -@ $ncore  $input_bam > ${mat_dir}/tmp.sam
   fi
   echo "Getting bed file for read pair (fragment) information"
   ${PERL_PATH}/perl ${curr_dir}/simply_sam2frags.pl --read_file ${mat_dir}/tmp.sam  --output_file ${mat_dir}/fragments.bed

fi

#echo "Sorting the output by position" -- slow in shell, just do it by R will be much faster
#sort -k1,1 -k2,2n -k3,3n ${mat_dir}/fragments.bed > ${mat_dir}/fragments.bed.sorted



echo "Getting matrix..."
# this R script will output sorted fragments as well
${R_PATH}/R --vanilla --args ${mat_dir}/fragments.bed $input_peaks ${mat_dir}/${OUTPUT_PREFIX}.${MAPPING_METHOD}.peak.barcode.mtx < ${curr_dir}/get_mat.R 

rm ${mat_dir}/tmp.sam

echo "Get Matrix Done!"






