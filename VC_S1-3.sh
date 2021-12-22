#PBS -S /bin/bash
#PBS -l walltime=96:00:00
#PBS -l nodes=1:ppn=8
#PBS -l mem=40gb
#PBS -o /scratch/akoppayi/process/16_Batch/Batch_16log.out
#PBS -e /scratch/akoppayi/process/16_Batch/Batch_16log.err
#PBS -d /scratch/akoppayi/process/16_Batch 


module load java-jdk/1.8.0_92
module load picard/2.8.1


logfile="/scratch/akoppayi/process/16_Batch/Batch16LogFile.txt"
echo "WES Analysis" > $logfile
echo "Step 1  of Analysis Started" >> $logfile
COUNT=0
for input in `ls *R1_001.fastq.gz`;
do

echo "Step 1:Sample $input Started" >> $logfile;
platform_unit=("`zless $input |head -n1 | awk -F ':' '{print $3 "." $4}'`");
java -Djava.io.tmpdir=${input%_R1_001.fastq.gz}"_001_tmp" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar FastqToSam FASTQ=$input FASTQ2=${input%_R1_001.fastq.gz}"_R2_001.fastq.gz" OUTPUT=${input%_R1_001.fastq.gz}"_ubam.bam" READ_GROUP_NAME=*** SAMPLE_NAME=*** LIBRARY_NAME=L1 PLATFORM_UNIT=$platform_unit PLATFORM=illumina;
FILE=${input%_R1_001.fastq.gz}"_ubam.bam"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo Error for $input in Step 1>> $logfile 
    let COUNT=COUNT+1
fi
done

echo "Step 1 of Analysis Completed with $COUNT Errors" >> $logfile

echo "Loading Modules for Next Step"


module load java-jdk/1.8.0_92
module load picard/2.8.1

echo "Step 2 of Analysis Started" >> $logfile 
COUNT=0

for input in `ls *_ubam.bam`; 
do
echo "Step 2 Mark Adapters in Unmapped $input file Started" >> $logfile ;
java -Djava.io.tmpdir=${input%_ubam.bam}"_tmp_step2" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar MarkIlluminaAdapters I=$input O=${input%_ubam.bam}"_step2.bam" M=${input%_ubam.bam}"_step2_metrics.txt" ;

FILE=${input%_ubam.bam}"_step2.bam"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo Error for $input in Step 2>> $logfile
     let COUNT=COUNT+1
fi
done

echo "Step 2 of Analysis Completed with $COUNT Errors" >> $logfile 

echo "Loading Modules for Next Step"

module load java-jdk/1.8.0_92
module load picard/2.8.1

echo "Step 3a of Analysis Started" >> $logfile

COUNT=0
for input in `ls *_step2.bam`; 
do
echo "Step 3a: $input to Fastq Started" >> $logfile;
 java -Djava.io.tmpdir=${input%_step2.bam}"_tmp_step3a_BWA" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar SamToFastq I=$input FASTQ=${input%_step2.bam}"_3a_forBWA.fastq" CLIPPING_ATTRIBUTE=XT CLIPPING_ACTION=2 INTERLEAVE=true NON_PF=true;

FILE=${input%_step2.bam}"_3a_forBWA.fastq"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo Error for $input in Step 3a>> $logfile
    let COUNT=COUNT+1
fi
done

echo "Step 3a of Analysis Completed with $COUNT Errors" >> $logfile
 
echo "Loading Modules for Next Step"

module load gcc/6.2.0
module load java-jdk/1.8.0_92
module load picard/2.8.1
module load bwa/0.7.15


echo "Step 3b of Analysis Started" >> $logfile
COUNT=0
for input in `ls *_3a_forBWA.fastq`; do 
echo "Step 3b: Align Reads using BWA-MEM for $input Started" >> $logfile;
/apps/software/gcc-6.2.0/bwa/0.7.15/bwa mem -M -t 7 -p /gpfs/data/godley-lab/WES_analysis/reference_human_38/Homo_sapiens.GRCh38.dna.toplevel.fa.gz $input > ${input%_3a_forBWA.fastq}"_3b_bwa_mem.sam" ;
FILE=${input%_3a_forBWA.fastq}"_3b_bwa_mem.sam"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo Error for $input in Step 3b>> $logfile
    let COUNT=COUNT+1
fi
done 

echo "Step 3b of Analysis Completed with $COUNT Errors" >> $logfile

echo "Loading Modules for Step 3c"

module load java-jdk/1.8.0_92
module load picard/2.8.1

echo "Step 3c of Analysis Started" >> $logfile

COUNT=0;

for input in `ls *_3b_bwa_mem.sam`;
do
echo "Step 3c: Align Reads using BWA-MEM for $input Started" >> $logfile;
java -Djava.io.tmpdir=${input%_3b_bwa_mem.sam}"_tmp_step3c_BWA" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar MergeBamAlignment R=/gpfs/data/godley-lab/WES_analysis/reference_human_38/Homo_sapiens.GRCh38.dna.toplevel.fa.gz ALIGNED_BAM=$input UNMAPPED_BAM=${input%_3b_bwa_mem.sam}"_ubam.bam" OUTPUT=${input%_3b_bwa_mem.sam}"_mapped.bam" CREATE_INDEX=true ADD_MATE_CIGAR=true CLIP_ADAPTERS=false CLIP_OVERLAPPING_READS=true INCLUDE_SECONDARY_ALIGNMENTS=true MAX_INSERTIONS_OR_DELETIONS=-1 PRIMARY_ALIGNMENT_STRATEGY=MostDistant ATTRIBUTES_TO_RETAIN=XS;

FILE=${input%_3b_bwa_mem.sam}"_mapped.bam";
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo Error for $input in Step 3c>> $logfile
    let COUNT=COUNT+1
fi
done 

echo "Step 3c of Analysis Ended" >> $logfile

echo "WES Analysis Completed till Step 3c" >> $logfile
