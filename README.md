# Private paternalism and the limits of self commitment

---

# Repository structure

You will see there are subdirectories for Raw Data, and for RScripts and DoFiles used to generate content. RScripts are always run from the RScripts directory, while DoFiles are run from the experiment directory by declaring a global variable.  

File cleaning processes take Raw data as an input and have DB data as an output. The figures & tables found in the paper are created with dofiles/rscripts, which are referenced (commented) in the main.tex file. The individual figures are also refered in the main do files.


# Do-Files and RScripts 

Analysis of the data and econometrics is done with STATA. However, the HTE (done with GRF) is runned with R, and 'processing' dofiles need to be runned before Rsripts - The exact order is found in processing.do


1) To change the directory, the relevant path has to be modified in 
	global_directory_paper.do
	(Rscripts directory needs to be directly changed within each file)

2) Cleaning of data is run through 
	master_cleaning.do

3) Data processing for further analysis	(to be done in R)
	processing.do

4) The main results are run through
	master_main.do

5) Results from the appendix are run through
	master_appendix.do


# Workflow 

We share all our work through github, and update the Overleaf project through Dropbox.