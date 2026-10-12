--imports
{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_DATASERVICES','EXCHANGE','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_DATASERVICES','API_LOGS','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_DATASERVICES','PROJECTS','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_DATASERVICES','PEXAKEY','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_DATASERVICES','API_PUSH_NOTIFICATION','all','TRN_XS_WH')}}




