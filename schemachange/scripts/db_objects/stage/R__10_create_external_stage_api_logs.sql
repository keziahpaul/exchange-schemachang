

create or replace stage {{in_sf_env}}_EXCHANGE_RAW.API_LOGS.API_LOGS_S3_INBOUND_REPORT_STAGE
STORAGE_INTEGRATION = {{in_sf_env}}_exchange_apilogs_s3_integration
URL ='{{in_s3_bucket}}/report/v1/'
file_format = {{in_sf_env}}_EXCHANGE_RAW.API_LOGS.{{in_sf_env}}_json_format;

create or replace stage {{in_sf_env}}_EXCHANGE_RAW.API_LOGS.API_LOGS_S3_INBOUND_AUDIT_STAGE
STORAGE_INTEGRATION = {{in_sf_env}}_exchange_apilogs_s3_integration
URL ='{{in_s3_bucket}}/audit/v1/'
file_format = {{in_sf_env}}_EXCHANGE_RAW.API_LOGS.{{in_sf_env}}_json_format;

