use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
--- storage integration for Projects files in S3
CREATE STORAGE INTEGRATION IF NOT EXISTS {{in_sf_env}}_projects_s3_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER ='S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='{{in_projects_role_arn}}'
STORAGE_ALLOWED_LOCATIONS = ('{{in_projects_s3_bucket}}')
STORAGE_AWS_EXTERNAL_ID='{{in_sf_external_id}}{{in_sf_env}}_projects_s3_integration'; 

ALTER STORAGE INTEGRATION IF EXISTS {{in_sf_env}}_projects_s3_integration
SET STORAGE_ALLOWED_LOCATIONS = ('{{in_projects_s3_bucket}}')
STORAGE_AWS_ROLE_ARN ='{{in_projects_role_arn}}'
STORAGE_AWS_EXTERNAL_ID='{{in_sf_external_id}}{{in_sf_env}}_projects_s3_integration'; 

grant usage on integration {{in_sf_env}}_projects_s3_integration to role sysadmin;
grant usage on integration {{in_sf_env}}_projects_s3_integration to role {{ in_sf_env }}_dbt_integration_role_s;


use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;