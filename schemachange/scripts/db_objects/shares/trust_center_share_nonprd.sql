
-- Create share for Trust Center data
-- This share is intended for non-production environments only
-- It includes masked and public data for compliance purposes
-- this script is not run by workflow, it is run manually as needed and recorded for future reference and documentation for creating shares
create share NONPRD_EXCHANGE_TRUSTCENTER_SHARE; 

grant usage on database  DEV_LOGGING  to share NONPRD_EXCHANGE_TRUSTCENTER_SHARE;
grant usage  on schema  DEV_LOGGING.TRUSTCENTER to share NONPRD_EXCHANGE_TRUSTCENTER_SHARE;


grant usage on database  DEV_LOGGING to database role DEV_LOGGING.PI_MASKED_DATASHARE_DBROLE;
grant usage on database  DEV_LOGGING  to database role DEV_LOGGING.PI_PUBLIC_DATASHARE_DBROLE;

grant usage  on schema  DEV_LOGGING.TRUSTCENTER  to database role DEV_LOGGING.PI_MASKED_DATASHARE_DBROLE;
grant usage  on schema  DEV_LOGGING.TRUSTCENTER  to database role DEV_LOGGING.PI_PUBLIC_DATASHARE_DBROLE;


grant select on  DEV_LOGGING.TRUSTCENTER.FINDINGS to database role DEV_LOGGING.PI_MASKED_DATASHARE_DBROLE;
grant select on  DEV_LOGGING.TRUSTCENTER.FINDINGS to database role DEV_LOGGING.PI_PUBLIC_DATASHARE_DBROLE;
grant select on  DEV_LOGGING.TRUSTCENTER.FINDINGS to share NONPRD_EXCHANGE_TRUSTCENTER_SHARE;

grant database role DEV_LOGGING.PI_MASKED_DATASHARE_DBROLE to share NONPRD_EXCHANGE_TRUSTCENTER_SHARE;
grant database role DEV_LOGGING.PI_PUBLIC_DATASHARE_DBROLE to share NONPRD_EXCHANGE_TRUSTCENTER_SHARE;

ALTER SHARE NONPRD_EXCHANGE_TRUSTCENTER_SHARE ADD ACCOUNTS = JV60414; -- this is account locator id for prod group 


