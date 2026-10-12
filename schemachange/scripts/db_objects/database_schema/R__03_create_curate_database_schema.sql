{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env,'EXCHANGE_CURATE','EXCHANGE')}}
{{create_database_schema(in_sf_env,'EXCHANGE_CURATE','API_LOGS')}}
{{create_database_schema(in_sf_env,'EXCHANGE_CURATE','PROJECTS')}}
{{create_database_schema(in_sf_env,'EXCHANGE_CURATE','PEXAKEY')}}
{{create_database_schema(in_sf_env,'EXCHANGE_CURATE','API_PUSH_NOTIFICATION')}}
-- {{create_database_schema(in_sf_env,'EXCHANGE_CURATE','EXCHANGE_ARCHIVED')}}

