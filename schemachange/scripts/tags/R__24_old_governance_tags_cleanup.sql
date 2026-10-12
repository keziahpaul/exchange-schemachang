{% set in_sf_env = in_sf_env | upper -%}
{% set db = in_sf_env + '_GOVERNANCE_DB' -%}
{% set schema = db + '.COMPLIANCE' -%}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;
USE ROLE ACCOUNTADMIN;
-- =============================================================================
-- STEP 1: Unset masking policies from their associated tags
-- Must be done FIRST before dropping policies or tags
-- =============================================================================


EXECUTE IMMEDIATE $$
DECLARE
    tag_name VARCHAR;
    policy_name VARCHAR;
    sql_stmt VARCHAR;
    c1 CURSOR FOR
        SELECT tag_name, policy_name FROM (
            SELECT column1 AS tag_name, column2 AS policy_name FROM VALUES
                ('PI_BUSINESS_NAME',        'PI_BUSINESS_NAME'),
                ('PI_CONTACT_NUMBER',       'PI_CONTACT_NUMBER'),
                ('PI_DOB',                  'PI_DOB'),
                ('PI_DOB',             'PI_DOB_DATE'),
                ('PI_EMAIL',                'PI_EMAIL'),
                ('PI_FAX',                  'PI_FAX'),
                ('PI_FREE_TEXT_FIELD',      'PI_FREE_TEXT_FIELD'),
                ('PI_FULL_ADDRESS',         'PI_FULL_ADDRESS'),
                ('PI_FULL_NAME',            'PI_FULL_NAME'),
                ('PI_MULTI',                'PI_MULTI'),
                ('PI_NAME',                 'PI_NAME'),
                ('PI_PARTIAL_ADDRESS',      'PI_PARTIAL_ADDRESS'),
                ('PI_SENSITIVE',            'PI_SENSITIVE'),
                ('PI_SENSITIVE',            'PI_SENSITIVE_BOOLEAN'),
                ('PI_SENSITIVE_FINANCIAL',            'PI_SENSITIVE_FINANCIAL'),
                ('PI_SENSITIVE_FINANCIAL',  'PI_SENSITIVE_FINANCIAL_NUMBER'),
                ('PI_USERID',               'PI_USERID'),
                ('PI_USERID',               'PI_USERID_NUMBER')
        );
BEGIN
    FOR rec IN c1 DO
        sql_stmt := 'ALTER TAG IF EXISTS {{schema}}.' || rec.tag_name
            || ' UNSET MASKING POLICY {{schema}}.' || rec.policy_name;
        BEGIN
            EXECUTE IMMEDIATE sql_stmt;
        EXCEPTION
            WHEN STATEMENT_ERROR THEN
                IF (SQLERRM LIKE '%Masking policy%does not exist%') THEN NULL; ELSE RAISE; END IF;
        END;
    END FOR;
END;
$$;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
-- =============================================================================
-- STEP 2: Drop all masking policies
-- Run AFTER Step 1 (unset from tags) 
-- =============================================================================
USE ROLE SYSADMIN;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_BUSINESS_NAME;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_CONTACT_NUMBER;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_DOB;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_EMAIL;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_FAX;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_FREE_TEXT_FIELD;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_FULL_ADDRESS;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_FULL_NAME;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_MULTI;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_NAME;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_PARTIAL_ADDRESS;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_SENSITIVE;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_SENSITIVE_BOOLEAN;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_SENSITIVE_FINANCIAL;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_SENSITIVE_FINANCIAL_NUMBER;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_USERID;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_USERID_NUMBER;
DROP MASKING POLICY IF EXISTS {{schema}}.PI_DOB_DATE;
-- =============================================================================
-- STEP 3: Drop all tags
-- Run LAST after all policies are dropped and tags are unset from columns
-- =============================================================================
use role SYSADMIN;
DROP TAG IF EXISTS {{schema}}.PI_BUSINESS_NAME;
DROP TAG IF EXISTS {{schema}}.PI_CONTACT_NUMBER;
DROP TAG IF EXISTS {{schema}}.PI_DOB;
DROP TAG IF EXISTS {{schema}}.PI_EMAIL;
DROP TAG IF EXISTS {{schema}}.PI_FAX;
DROP TAG IF EXISTS {{schema}}.PI_FREE_TEXT_FIELD;
DROP TAG IF EXISTS {{schema}}.PI_FULL_ADDRESS;
DROP TAG IF EXISTS {{schema}}.PI_FULL_NAME;
DROP TAG IF EXISTS {{schema}}.PI_MULTI;
DROP TAG IF EXISTS {{schema}}.PI_NAME;
DROP TAG IF EXISTS {{schema}}.PI_PARTIAL_ADDRESS;
DROP TAG IF EXISTS {{schema}}.PI_SENSITIVE;
DROP TAG IF EXISTS {{schema}}.PI_SENSITIVE_BOOLEAN;
DROP TAG IF EXISTS {{schema}}.PI_SENSITIVE_FINANCIAL;
DROP TAG IF EXISTS {{schema}}.PI_SENSITIVE_FINANCIAL_NUMBER;
DROP TAG IF EXISTS {{schema}}.PI_USERID;
DROP TAG IF EXISTS {{schema}}.PI_USERID_NUMBER;
DROP TAG IF EXISTS {{schema}}.PI_DOB_DATE;