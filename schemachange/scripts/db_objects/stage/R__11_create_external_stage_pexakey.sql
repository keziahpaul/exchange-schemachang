
create stage IF NOT EXISTS  {{in_sf_env}}_EXCHANGE_RAW.PEXAKEY.PEXAKEY_S3_INBOUND_STAGE
STORAGE_INTEGRATION = {{in_sf_env}}_exchange_pexakey_s3_integration
URL ='{{in_pexakey_s3_bucket}}/'
file_format = {{in_sf_env}}_EXCHANGE_RAW.PEXAKEY.{{in_sf_env}}_json_format;

ALTER STAGE IF EXISTS {{ in_sf_env }}_EXCHANGE_RAW.PEXAKEY.PEXAKEY_S3_INBOUND_STAGE
SET
STORAGE_INTEGRATION = {{in_sf_env}}_exchange_pexakey_s3_integration
URL = '{{in_pexakey_s3_bucket}}/'
FILE_FORMAT = {{in_sf_env}}_EXCHANGE_RAW.PEXAKEY.{{in_sf_env}}_json_format;