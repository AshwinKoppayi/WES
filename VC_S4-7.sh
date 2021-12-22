#PBS -N  Script_Name
#PBS -S /bin/bash
#PBS -l walltime=96:00:00
#PBS -l nodes=1:ppn=8
#PBS -l mem=40gb
#PBS -d /path/to/current/directory
#PBS -o /path/to/logfiles/log.out
#PBS -e /path/to/logfiles/log.err

module load gcc/6.2.0
module load samtools/1.9

logfile="/path/to/logfiles/log.txt"
echo "WES Analysis" > $logfile
echo "Step 4 of Analysis Started" >> $logfile
COUNT=0 

for input in `ls *L001_mapped.bam`;
do 
echo "Step 4: Sample $input started" >> $logfile;
java -Djava.io/.tmpdir=${input%_mapped.bam}"_tmp_step4" -jar /apps/software/java-jdk-1.8.0_92/picard/2.8.1/picard.jar MarkDuplicates INPUT=$input INPUT=${input%_L001_mapped.bam}"_L002_mapped.bam" INPUT=${input%_L001_mapped.bam}"_L003_mapped.bam" INPUT=${input%_L001_mapped.bam}"_L004_mapped.bam" OUTPUT=${input%_L001_mapped.bam}"_step4.bam" METRICS_FILE=${input%_L001_mapped.bam}"_step4_metrics.txt" OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 CREATE_INDEX=true; 

FILE=${input%_L001_mapped.bam}"_step4.bam"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo "Error for $input in Step 4">> $logfile
    let COUNT=COUNT+1
fi
done

echo "Step 4 of Analysis completed with $COUNT Errors" >> $logfile

echo " Loading Modules for Next Step"


module load java-jdk/1.8.0_92
module load picard/2.8.1

echo "Step 5a of Analysis started" >> $logfile
COUNT=0
for input in `ls *step4.bam`;
do
echo "Step 5a: Analyze pattern of covariation in the sequence dataset" >> $logfile
java -jar /apps/software/java-jdk-1.8.0_92/gatk/3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /gpfs/data/godley-lab/WES_analysis/reference_human_38/Homo_sapiens.GRCh38.dna.toplevel.fa -I $input -knownSites /gpfs/data/godley-lab/WES_analysis/dbsnp/All_20170710_sort.vcf -o ${input%_step4.bam}"_step5a_BaseRecalibrator.table" -U ALLOW_SEQ_DICT_INCOMPATIBILITY; 

FILE=${input%_step4.bam}"_step5a_BaseRecalibrator.table"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo "Error for $input in Step 4">> $logfile
    let COUNT=COUNT+1
fi
done 
echo "Step 5a of Analysis Completed with $COUNT Errors" >> $logfile

echo "Loading modules for Next Step"

module load java-jdk/1.8.0_92
module load gatk/3.7

echo "Step 2 of Analysis Started" >> $logfile
COUNT=0


for input in `ls *step4.bam`;
do
echo "Step 5b : Recalibrating the sequencing data for $input" >> $logfile;
java -jar /apps/software/java-jdk-1.8.0_92/gatk/3.7/GenomeAnalysisTK.jar -T PrintReads -R /gpfs/data/godley-lab/WES_analysis/reference_human_38/Homo_sapiens.GRCh38.dna.toplevel.fa -I $input -BQSR ${input%_step4.bam}"_step5a_BaseRecalibrator.table" -o ${input%_step4.bam}"_step5b.bam" ;


FILE=${input%_step4.bam}"_step5b.bam"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo "Error for $input in Step 4">> $logfile
    let COUNT=COUNT+1
fi
done 
echo "Step 5b of Analysis Completed with $COUNT Errors" >> $logfile

echo "Loading files for Step 6"

module load java-jdk/1.8.0_92
module load gatk/3.7

echo "Step 6 of Analysis Started" >>$logfile
COUNT=0

for input in `ls *step5b.bam`;
do
echo "Step 6: Variant Discovery for $input" >> $logfile

java -jar /apps/software/java-jdk-1.8.0_92/gatk/3.7/GenomeAnalysisTK.jar -T HaplotypeCaller -R /gpfs/data/godley-lab/WES_analysis/reference_human_38/Homo_sapiens.GRCh38.dna.toplevel.fa -I $input --genotyping_mode DISCOVERY -o ${input%_step5b.bam}".vcf"; 

FILE=${input%_step5b.bam}".vcf"
if test -f "$FILE"; then
    echo "$FILE exists" >> $logfile
else
    echo "Error for $input in Step 4">> $logfile
    let COUNT=COUNT+1
fi
done 
echo "Step 6 of Analysis Completed with $COUNT Errors" >> $logfile
echo "Loading modules for Step 7"

module load gcc/4.9.4
module load perl/5.18.4


for input in `ls *.vcf`;
do
echo "Step 7: Variant Discovery for $input" >> $logfile
/gpfs/data/godley-lab/WES_analysis/annovar/table_annovar.pl $input /gpfs/data/godley-lab/WES_analysis/annovar/humandb/ -buildver hg38 -out ${input%.vcf} -arg '-splicing 15',,,,,,,, -remove -protocol refGene,cytoBand,exac03,gnomad_exome,gnomad_genome,kaviar_20150923,clinvar_20170905,avsnp147,dbnsfp30a -operation g,r,f,f,f,f,f,f,f -nastring . -vcfinput ; 
done

echo "WES Analysis completed" >> $logfile

