CREATE  STAGE IF NOT EXISTS {{ in_sf_env }}_EXCHANGE_RAW.exchange.exchange_rds_dms_extract_s3_stage
STORAGE_INTEGRATION ={{in_sf_env}}_exchange_s3_integration
URL='{{in_exchange_s3_bucket}}/'
DIRECTORY = ( ENABLE = TRUE
              REFRESH_ON_CREATE = TRUE
              AUTO_REFRESH = FALSE )
FILE_FORMAT = {{ in_sf_env }}_EXCHANGE_RAW.EXCHANGE.exchange_raw_csv_fileformat;