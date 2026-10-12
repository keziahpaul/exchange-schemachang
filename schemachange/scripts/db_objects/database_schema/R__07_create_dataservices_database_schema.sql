{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env,'EXCHANGE_DATASERVICES','EXCHANGE')}}
{{create_database_schema(in_sf_env,'EXCHANGE_DATASERVICES','API_LOGS')}}
{{create_database_schema(in_sf_env,'EXCHANGE_DATASERVICES','PROJECTS')}}
{{create_database_schema(in_sf_env,'EXCHANGE_DATASERVICES','PEXAKEY')}}
{{create_database_schema(in_sf_env,'EXCHANGE_DATASERVICES','API_PUSH_NOTIFICATION')}}


