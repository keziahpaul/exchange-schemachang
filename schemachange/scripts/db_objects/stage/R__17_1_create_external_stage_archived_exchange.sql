-- CREATE STAGE IF NOT EXISTS {{ in_sf_env }}_EXCHANGE_RAW.EXCHANGE_ARCHIVED.archived_exchange_data_s3_stage
-- STORAGE_INTEGRATION ={{in_sf_env}}_exchange_s3_integration
-- URL='{{in_archived_s3_bucket}}'
-- DIRECTORY = ( ENABLE = TRUE
--               REFRESH_ON_CREATE = TRUE
--               AUTO_REFRESH = FALSE )
-- FILE_FORMAT = {{ in_sf_env }}_EXCHANGE_RAW.EXCHANGE_ARCHIVED.archived_csv_fileformat;

DROP STAGE IF EXISTS {{ in_sf_env }}_EXCHANGE_RAW.EXCHANGE_ARCHIVED.archived_exchange_data_s3_stage;