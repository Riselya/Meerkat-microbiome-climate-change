
##### MEERKAT DFG PROJECT

#### QIIIME 2
source activate qiime2-2020.2

##import sequence data from appropriate input path

qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path AllSamples \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path demux-paired-end.qza


##how many sequences were obtained per sample?

qiime demux summarize \
--i-data demux-paired-end.qza \
--o-visualization demux-paired-end.qzv

##view wtih qiime2


## DADA2 quality control, joins sequences, filters out chimeras

#515F (5′-GTGCCAGCMGCCGCGGTAA-3′)
#806R (5′-GGACTACHVGGGTWTCTAAT-3′) (Caporaso et al., 2010, 2011

qiime dada2 denoise-paired \
--i-demultiplexed-seqs demux-paired-end.qza \
--p-trim-left-f 23 \
--p-trim-left-r 20 \
--p-trunc-len-f 244 \
--p-trunc-len-r 235 \
--p-n-threads 8 \
--o-representative-sequences rep-seqs-dada2.qza \
--o-table table-dada2.qza \
--o-denoising-stats stats-dada2.qza

#######################################################
#######################################################



##visualize denoising results per sample

qiime metadata tabulate \
--m-input-file stats-dada2.qza \
--o-visualization stats-dada2.qzv 

#########  summarize count table 

qiime feature-table summarize \
--i-table table-dada2.qza \
--o-visualization table-dada2.qzv \
--m-sample-metadata-file meerkat_metadata_updated.txt


##############################################################


qiime feature-table tabulate-seqs \
--i-data rep-seqs-dada2.qza \
--o-visualization rep-seqs-dada2.qzv



###############assign taxonomy to the unique sequences
###############assign taxonomy to the unique sequences
###############assign taxonomy to the unique sequences
###############assign taxonomy to the unique sequences
###############assign taxonomy to the unique sequences


qiime feature-classifier classify-sklearn \
--i-classifier silva.132.V4_2020.2.classifier.qza \
--i-reads rep-seqs-dada2.qza \
--p-n-jobs 8 \
--o-classification taxonomySilva.qza


#visualize 

qiime metadata tabulate \
--m-input-file taxonomySilva.qza \
--o-visualization taxonomySilva.qzv


########## create barplot


qiime taxa barplot \
--i-table table-dada2.qza \
--i-taxonomy taxonomySilva.qza \
--m-metadata-file meerkat_metadata_updated.txt \
--o-visualization taxa-bar-plots.qzv



################################# build tree using fragment insertion
################################# build tree using fragment insertion
################################# build tree using fragment insertion

#use this instead

#https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5904434/
# https://github.com/qiime2/q2-fragment-insertion

#wget \
#-O "sepp-refs-silva-128.qza" \
#"https://data.qiime2.org/2019.10/common/sepp-refs-silva-128.qza"

qiime fragment-insertion sepp \
--i-representative-sequences  rep-seqs-dada2.qza \
--i-reference-database sepp-refs-silva-128.qza \
--o-tree insertion-tree.qza \
--o-placements insertion-placements.qza




####################################### EXPORT FILES


qiime tools export \
--input-path insertion-tree.qza \
--output-path exported-insertion-tree

qiime tools export \
--input-path table-dada2.qza \
--output-path exported-count-table


qiime tools export \
--input-path taxonomySilva.qza \
--output-path exported-taxonomy

#qiime tools export \
#--input-path rep-seqs-dada2.qza \
#--output-path exported-representative-sequences


##add taxonomy to biom file so that it is in right format for R

##concert it to a text file in linux


biom convert -i exported-count-table/feature-table.biom -o otu_table.txt --to-tsv


#open R

R

##add 'taxonomy' column to count table

table<-read.csv("otu_table.txt",sep='\t',check.names=FALSE,skip=1)

head(table)


###### IMPORTANT! HERE IT ONLY WORKS IF YOU USE read.delim() not read.table

Taxonomy<-read.delim("exported-taxonomy/taxonomy.tsv",sep='\t', header=TRUE)

head(Taxonomy)
names(Taxonomy)

table$taxonomy<-with(Taxonomy,Taxon[match(table$"#OTU ID",Taxonomy$Feature.ID)])

##make sure there is an extra line at the top
# Constructed from biom file


#save
write.table(table,"otu_table_tax.txt",row.names=FALSE,sep="\t")


quit() # quit R

sed -i '1s/^/# Constructed from biom file\n/' otu_table_tax.txt
sed -i -e 's/"//g' otu_table_tax.txt



##convert back to biom file in linux

biom convert -i otu_table_tax.txt -o new_otu_table.biom --to-hdf5 --table-type="OTU table" --process-obs-metadata taxonomy


## Now have all 3 files to export into Phyloseq

# new_otu_table.biom
# tree nwk file
# metadata



#
