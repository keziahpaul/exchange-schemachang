# pexa-one-data-snowflake-au-exchange

  

This project uses github actions to deploy database objects in snowflake via schema change. 

This project includes schemachange

 1. Config - environment specific configurations
 2. Modules - jinja macros for any repeatable scripts
 3. Scripts -  for creation of data base, account objects and RBAC
  

## Usage

### Repo structure


```

|── Schemachange/ 

	|── config/ 
		|── dev
		|── tst
		|── prd
		|── pst

	|── modules/

	|── scripts/
		|── account_objects
			|── rbac
			|── security
			|── shares
			|── storage_integration
			|── warehouses
		|── db_objects
			|── database_schema
			|── file_formats
			|── rbac
			|── stages
		|── masking_policies
		|── tags



```
## Scripts versioning in OneData:

Schemachange supports three types of versioning as below:

-   Versioned Script Naming
    
-   Repeatable Script Naming
    
-   Always Script Naming
    

In our project, we will use **Repeatable Script Naming** for all the scripts

-   _Naming Convention_ : **R__<number><description>.sql**
    
    -   **<number>: This number is extremely important as it decides the order of execution of the scripts.**
        
    -   In order to add any new script,
        
        -   check last executed script number in the change_history table using below query
            
            ```
            select max(distinct script) from DEV_METADATA.SCHEMACHANGE.CHANGE_HISTORY order by script desc
            ```
            
        -   Increment the number by 1 in the new script name.
            
    -   **<description>**: description of the file
        
    -   example : R__02_create_raw_database_schema.sql
        
-   All repeatable change scripts are applied each time the utility is run, if there is a change in the file. Repeatable scripts are applied in alphabetical order of their description.
    
-   If there is any change in the macros, all the files referring to the macro will be executed.