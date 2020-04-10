# nCoV_Finder

## Introduction
nCoV Finder is a pipeline for HCoV-19 genome analyzing. The pipeline could  efficiently classify CoV like reads from Massively Parallel Sequencing (MPS) data with Kraken, and get the virus genome with SPAdes and Pilon.

![Image](https://github.com/BGI-IORI/nCoV/blob/master/Image.png)

## Requirements:
perl: v5.22.0
python: v2.7.16
java: v1.8.0 

For HCoV-19 like reads classification:
* Kraken v1.1 (https://github.com/DerrickWood/kraken)
For data quality control:
* Fastp v0.19.5 (https://github.com/OpenGene/fastp)
* SOAPnuke v1.5.6 (https://github.com/BGI-flexlab/SOAPnuke)
For low complexity reads removing:
* PRINSEQ v0.20.4 (http://prinseq.sourceforge.net/)
For virus genome De novo assembly:
* SPAdes v3.14.0 (http://cab.spbu.ru/software/spades/)
For reference based consensus construction
* Pilon v1.23 (https://github.com/broadinstitute/pilon)
Other required tools:
* Picard v2.10.10 (https://broadinstitute.github.io/picard/)
* Samtools v1.9 (http://samtools.sourceforge.net/)
* bedtools v2.23.0 (https://bedtools.readthedocs.io/en/latest/)

# Installation
```
git clone https://github.com/BGI-IORI/nCoV.git
```

## Usage
1.Build Kraken database index:
```
kraken-build --build --threads 8 --db ./YourDBpath/ 
#Notes: 
#Put CoV.fa file in the fold named "library" in "./YourDBpath/". 
#Download taxonomy file from NCBI and put in "./YourDBpath/“. 
#Detailed description about Kraken index can be found in the 
#website http://ccb.jhu.edu/software/kraken/MANUAL.html#custom-databases.
```
2.Build BWA index:
```
bwa -index HCoV-19.fa
```
3.samtools index:
```
samtools faidx HCoV-19.fa
```

4.Edit the input.config file, and change each software and database path to your own path.
```
perl nCoV_Finder.pl -i data.txt -c input.config -o ./outpath/
cd ./outpath/shellall/
sh allDependent.sh
#Notes: 
#data.txt includes three columns:  sample_name seq.1.fq.gz seq2.fq.gz
```
## Output
1.*De novo* assembly from SPAdes
```
#original fasta file from SPAdes
./outpath/05.ASS/sample/scaffolds.fasta   
#longest contig
./outpath/05.ASS/sample/scaffolds_longest.fasta 
```
2.Consensus sequence from Pilon
```
#original fasta file from pilon
./outpath/06.CNS/sample/sample.pilon.fasta 
#consensus after masked position with depth lower 10X
./outpath/06.CNS/sample/sample.masked.fasta
```
## Additional Information
For *De novo* assembly, if too much data was left after “Remove low complexity reads”, to reduce the burden of computing, the data can be downsized to a certain amount (Such as data amount equivalent to about 100X of HCoV-19 genome).

For consensus from pilon, the default depth cutofff was set to 10X, and the position with depth lower than 10X would be masked to N.
