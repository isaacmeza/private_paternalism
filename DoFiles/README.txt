This is a (short) documentation for the analysis for the paper 

# - The limits of self-commitment and private paternalism
# By Isaac Meza, Joyce Sadka, and Enrique Seira 

The documentation on how the repository is organized can be found on <https://bitbucket.org/IsaacMeza/donde2019/src/master/> (private repository)

Raw Data is located in the folder 'Raw', while auxiliary datasets are stored in '_aux', and final datasets in 'DB'.
Analysis of the data and econometrics is done with STATA. However, the HTE (done with GRF) is runned with R, and 'processing' dofiles need to be runned before Rsripts - The exact order is found in master_processing.do


1) To change the directory, the relevant path has to be modified in 
	global_directory_paper.do
	(Rscripts directory needs to be directly changed within each file)

2) Cleaning of data is run through 
	master_cleaning.do

3) Data processing for further analysis	(to be done in R)
	master_processing.do

4) The main results are run through
	master_main.do

5) Results from the appendix are run through
	master_appendix.do



For any reference or support contact Isaac Meza (isaac.meza@berkeley.edu)


--------------------------------------------------------------------