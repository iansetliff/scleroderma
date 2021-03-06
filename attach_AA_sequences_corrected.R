args = commandArgs(trailingOnly=TRUE)
wdir = args[1]
file = args[2]

package_path = '/path/to/packages/'
library('ggplot2'); library('plyr'); library('reshape2'); library('scales')
library('lazyeval',lib.loc=package_path)
library('igraph',lib.loc=package_path)
library('alakazam',lib.loc=package_path)
library('data.table',lib.loc=package_path)

data = readChangeoDb(file)
								
## Read IMGT output:
patient = strsplit(file,"_")[[1]][1]
IMGTdata = data.frame()
	IMGTfolders = list.files(wdir,patient)
	IMGTfolders = IMGTfolders[grepl("_minCONSCOUNT2",IMGTfolders) & 
								!grepl("txz",IMGTfolders) & 
								!grepl("tab",IMGTfolders) & 
								!grepl("fasta",IMGTfolders) &
								!grepl("extracted",IMGTfolders)]
	for (IMGTfolder in IMGTfolders) {
		week = strsplit(IMGTfolder,"_")[[1]][2]
		IMGTfile = paste(wdir,"/",IMGTfolder,"/5_AA-sequences.txt",sep="")
		newIMGTdata = read.delim(IMGTfile,stringsAsFactors=F)
		newIMGTdata$SEQUENCE_ID = sapply(newIMGTdata$Sequence.ID, function(s) strsplit(s,"_")[[1]][1])
		newIMGTdata$SEQUENCE_VISIT_ID = paste(newIMGTdata$SEQUENCE_ID,week,sep=";")
		IMGTdata = rbind(IMGTdata,newIMGTdata)
	}

## Get desired fields:
IMGTdata = IMGTdata[,c("SEQUENCE_VISIT_ID","V.D.J.REGION","CDR3.IMGT","JUNCTION")]
setnames(IMGTdata,old=c("V.D.J.REGION","CDR3.IMGT","JUNCTION"),
				new=c("AA_SEQUENCE_VDJ","AA_CDR3","AA_JUNCTION"))

## Bind fields to the changeo database:
data$SEQUENCE_VISIT_ID = paste(data$SEQUENCE_ID,data$WEEK,sep=";")
data = merge(data,IMGTdata,by="SEQUENCE_VISIT_ID")

## Write result file:
outfile = gsub(".tab","_attach-AA-sequences-pass-corrected.tab",file)
writeChangeoDb(data,outfile)