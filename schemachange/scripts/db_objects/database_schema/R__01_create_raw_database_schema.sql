{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}}
{{create_database_schema(in_sf_env,'EXCHANGE_RAW', 'EXCHANGE','all','TRN_XS_WH')}}
{{create_database_schema(in_sf_env,'EXCHANGE_RAW', 'API_LOGS','all','TRN_XS_WH')}}
{{create_database_schema(in_sf_env,'EXCHANGE_RAW', 'PEXAKEY','all','TRN_XS_WH')}}
{{create_database_schema(in_sf_env,'EXCHANGE_RAW', "PROJECTS",'all','TRN_XS_WH')}}
{{create_database_schema(in_sf_env,'EXCHANGE_RAW', 'API_PUSH_NOTIFICATION','all','TRN_XS_WH')}}
-- {{create_database_schema(in_sf_env,'EXCHANGE_RAW', 'EXCHANGE_ARCHIVED','all','TRN_XS_WH')}}

