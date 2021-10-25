#PBS -S /bin/bash
#PBS -l walltime=96:00:00
#PBS -l nodes=1:ppn=8
#PBS -l mem=40gb
#PBS -o /scratch/akoppayi/output/Output1.out
#PBS -e /scratch/akoppayi/output/LogErr.err
#PBS -d /scratch/akoppayi 


module load java-jdk/1.8.0_92
module load picard/2.8.1
logfile="/scratch/akoppayi/output/log_file_test.txt"
echo "WES Analysis" > $logfile
echo "Step 1  of Analysis Started" >> $logfile
for input in `ls *R1_001.fastq.gz`;
do
echo "Step 1:Sample $input Started" >> $logfile;
platform_unit=("`zless $input |head -n1 | awk -F ':' '{print $3 "." $4}'`");
java -Djava.io.tmpdir=${input%_R1_001.fastq.gz}"_001_tmp" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar FastqToSam FASTQ=$input FASTQ2=${input%_R1_001.fastq.gz}"_R2_001.fastq.gz" OUTPUT=${input%_R1_001.fastq.gz}"_ubam.bam" READ_GROUP_NAME=*** SAMPLE_NAME=*** LIBRARY_NAME=L1 PLATFORM_UNIT=$platform_unit PLATFORM=illumina;

echo "Step 1:Sample $input Ended" >> $logfile;

done
echo "Step 1 of Analysis Completed" >> $logfile

echo "Loading Modules for Next Step"


module load java-jdk/1.8.0_92
module load picard/2.8.1

echo "Step 2 of Analysis Started" >> $logfile 

for input in `ls *_ubam.bam`; 
do
echo "Step 2 Mark Adapters in Unmapped $input file Started" >> $logfile ;
java -Djava.io.tmpdir=${input%_ubam.bam}"_tmp_step2" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar MarkIlluminaAdapters I=$input O=${input%_ubam.bam}"_step2.bam" M=${input%_ubam.bam}"_step2_metrics.txt" ;
echo "Step 2 Mark Adapters in Unmapped $input file:Completed";
done

echo "Step 2 of Analysis Completed" >> $logfile 

echo "Loading Modules for Next Step"

module load java-jdk/1.8.0_92
module load picard/2.8.1

echo "Step 3a of Analysis Started" >> $logfile


for input in `ls *_step2.bam`; 
do
echo "Step 3a: $input to Fastq Started" >> $logfile;
 java -Djava.io.tmpdir=${input%_step2.bam}"_tmp_step3a_BWA" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar SamToFastq I=$input FASTQ=${input%_step2.bam}"_3a_forBWA.fastq" CLIPPING_ATTRIBUTE=XT CLIPPING_ACTION=2 INTERLEAVE=true NON_PF=true;
echo "Step 3a: $input to Fastq Completed" >> $logfile;
done

echo "Step 3a of Analysis Completed" >> $logfile
 
echo "Loading Modules for Next Step"

module load gcc/6.2.0
module load java-jdk/1.8.0_92
module load picard/2.8.1
module load bwa/0.7.15


echo "Step 3b of Analysis Started" >> $logfile

for input in `ls *_3a_forBWA.fastq`; do 
echo "Step 3a: Align Reads using BWA-MEM for $input Started" >> $logfile;
/apps/software/gcc-6.2.0/bwa/0.7.15/bwa mem -M -t 7 -p /gpfs/data/godley-lab/WES_analysis/reference_human_38/Homo_sapiens.GRCh38.dna.toplevel.fa.gz $input > ${input%_3a_forBWA.fastq}"_3b_bwa_mem.sam" ;
echo "Step 3b: Align Reads using BWA-MEM for $input Completed" >> $logfile ;
done 

echo "Step 3b of Analysis Completed" >> $logfile












 






