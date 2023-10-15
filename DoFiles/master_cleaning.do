********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	master_cleaning
* Author: Isaac M 

* Purpose: This is the master dofile that cleans dataset for replication
*******************************************************************************/
*/


* Cleaning of admin data
do "./DoFiles/cleaning/cleaning_admin.do"

* Cleaning of survey + admin data
do "./DoFiles/cleaning/cleaning_master.do"

* Process dataset for CATE random forest in R
do "./DoFiles/cleaning/prepare_data_te.do"
do "./DoFiles/cleaning/prepare_data_inst_forest.do"

