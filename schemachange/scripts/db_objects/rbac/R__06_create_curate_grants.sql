{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}

{{create_access_roles_privileges(in_sf_env,'EXCHANGE_CURATE','EXCHANGE','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_CURATE','API_LOGS','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_CURATE','PROJECTS','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_CURATE','PEXAKEY','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'EXCHANGE_CURATE','API_PUSH_NOTIFICATION','all','TRN_XS_WH')}}
-- {{create_access_roles_privileges(in_sf_env,'EXCHANGE_CURATE','EXCHANGE_ARCHIVED','all','TRN_XS_WH')}}
