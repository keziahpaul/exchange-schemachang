-- Create share for Trust Center data
-- This share is intended for non-production environments only
-- It includes masked and public data for compliance purposes
-- this script is not run by workflow, it is run manually as needed and recorded for future reference and documentation for creating shares

create share PRD_EXCHANGE_TRUSTCENTER_SHARE; 

grant usage on database  PRD_LOGGING  to share PRD_EXCHANGE_TRUSTCENTER_SHARE;
grant usage  on schema  PRD_LOGGING.TRUSTCENTER to share PRD_EXCHANGE_TRUSTCENTER_SHARE;


grant usage on database  PRD_LOGGING to database role PRD_LOGGING.PI_MASKED_DATASHARE_DBROLE;
grant usage on database  PRD_LOGGING  to database role PRD_LOGGING.PI_PUBLIC_DATASHARE_DBROLE;

grant usage  on schema  PRD_LOGGING.TRUSTCENTER  to database role PRD_LOGGING.PI_MASKED_DATASHARE_DBROLE;
grant usage  on schema  PRD_LOGGING.TRUSTCENTER  to database role PRD_LOGGING.PI_PUBLIC_DATASHARE_DBROLE;


grant select on  PRD_LOGGING.TRUSTCENTER.FINDINGS to database role PRD_LOGGING.PI_MASKED_DATASHARE_DBROLE;
grant select on  PRD_LOGGING.TRUSTCENTER.FINDINGS to database role PRD_LOGGING.PI_PUBLIC_DATASHARE_DBROLE;
grant select on  PRD_LOGGING.TRUSTCENTER.FINDINGS to share PRD_EXCHANGE_TRUSTCENTER_SHARE;

grant database role PRD_LOGGING.PI_MASKED_DATASHARE_DBROLE to share PRD_EXCHANGE_TRUSTCENTER_SHARE;
grant database role PRD_LOGGING.PI_PUBLIC_DATASHARE_DBROLE to share PRD_EXCHANGE_TRUSTCENTER_SHARE;

ALTER SHARE PRD_EXCHANGE_TRUSTCENTER_SHARE ADD ACCOUNTS = JV60414; -- this is account locator id for prod group 