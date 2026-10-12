{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating exchange and projects  database and  schema for env {{in_sf_env}} 

{{create_database_schema(in_sf_env,'EXCHANGE_STAGE','EXCHANGE')}}
{{create_database_schema(in_sf_env,'EXCHANGE_STAGE','PROJECTS')}}
