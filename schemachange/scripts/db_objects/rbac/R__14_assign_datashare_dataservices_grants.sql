{% from 'macros/grant_data_share.j2' import grant_data_share-%}
{% from 'data_share_tables/exchange_tables.sql' import exchange_tables_list -%}
{% from 'data_share_views/exchange_views.sql' import exchange_views_list -%}
{% from 'data_share_views/project_views.sql' import projects_views_list -%}
{% from 'data_share_views/api_logs_views.sql' import api_logs_views_list -%}
{% from 'data_share_views/pexakey_views.sql' import pexakey_views_list -%}
{% from 'data_share_views/api_push_notification_views.sql' import api_push_notification_views_list -%}


{% set ds_database = in_sf_env+'_EXCHANGE_DATASERVICES' %}
{% set exchange_schema = 'EXCHANGE' %}
{% set projects_schema = 'PROJECTS' %}
{% set api_logs_schema = 'API_LOGS' %}
{% set pexakey_schema = 'PEXAKEY' %}
{% set api_push_notification_schema = 'API_PUSH_NOTIFICATION' %}


{% if in_sf_env.lower() == 'dev' %}
  {% set share_name = 'DEV_EXCHANGE_SHARE_TO_NONPROD_GROUP' %}
{% elif in_sf_env.lower() == 'tst' %}
  {% set share_name = 'NONPROD_EXCHANGE_DATA_SHARE' %}
{% elif in_sf_env.lower() == 'prd' %}
  {% set share_name = 'PROD_EXCHANGE_SHARE_TO_PROD_GROUP' %}
{% else %}
  {% set share_name = none %}
{% endif %}

--granting access to views in DS layer to share re-run 

{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;
    use role accountadmin;
    --creating share and granting access to dataservices layer 
    create share if not exists {{share_name}};
    grant usage on database  {{ds_database}}  to share {{ share_name }};
    grant usage  on schema  {{ds_database}}.EXCHANGE  to share {{ share_name }};

    grant reference_usage on database {{in_sf_env}}_governance_db to share {{ share_name }};
    grant reference_usage on database {{in_sf_env}}_EXCHANGE_STAGE to share {{ share_name }};
    grant reference_usage on database {{in_sf_env}}_EXCHANGE_CURATE to share {{ share_name }};
    grant reference_usage on database {{in_sf_env}}_EXCHANGE_RAW to share {{ share_name }};
    grant reference_usage on database {{in_sf_env}}_EXCHANGE_DATASERVICES to share {{ share_name }};
    --grants to PII DB roles
    grant usage on database  {{ds_database}}  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant usage on database  {{ds_database}}  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

    grant usage  on schema  {{ds_database}}.EXCHANGE  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant usage  on schema  {{ds_database}}.EXCHANGE  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

    grant usage  on schema  {{ds_database}}.PROJECTS  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant usage  on schema  {{ds_database}}.PROJECTS  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

    grant usage  on schema  {{ds_database}}.API_LOGS  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant usage  on schema  {{ds_database}}.API_LOGS  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

    grant usage  on schema  {{ds_database}}.PEXAKEY  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant usage  on schema  {{ds_database}}.PEXAKEY  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

    grant usage  on schema  {{ds_database}}.API_PUSH_NOTIFICATION  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant usage  on schema  {{ds_database}}.API_PUSH_NOTIFICATION  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

    --granting select on all views in exchange schems in tst and prd only to respective share
    {{ grant_data_share(exchange_views_list, ds_database, exchange_schema, share_name) }}
    {{ grant_data_share(projects_views_list, ds_database, projects_schema, share_name) }}
    {{ grant_data_share(api_logs_views_list, ds_database, api_logs_schema, share_name) }}
    {{ grant_data_share(pexakey_views_list, ds_database, pexakey_schema, share_name) }}
    {{ grant_data_share(api_push_notification_views_list, ds_database, api_push_notification_schema, share_name) }}

    --granting select on all selected tables in exchange schemas in tst and prd only to respective share
    {{ grant_data_share(exchange_tables_list, ds_database, exchange_schema, share_name) }}

    --granting PII db roles to share
    grant database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE to share {{ share_name }};
    grant database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE to share {{ share_name }};

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
{% else %}
select 1 ;
{% endif %}