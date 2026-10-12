USE ROLE SYSADMIN; 

CREATE OR REPLACE PROCEDURE {{in_sf_env}}_EXCHANGE_RAW.PEXAKEY.LOAD_RDS_TO_RAW("TABLE_NAME" VARCHAR, "LOAD_TYPE" VARCHAR, "SOURCE_SCHEMA" VARCHAR, "TARGET_DB" VARCHAR, "TARGET_SCHEMA" VARCHAR, "INCREMENTAL_KEY" VARCHAR, "BATCH_SIZE" NUMBER(38,0) DEFAULT 100000)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'psycopg2')
HANDLER = 'model'
EXTERNAL_ACCESS_INTEGRATIONS = ({{in_sf_env}}_PEXAKEY_RDS_DIGITAL_EXTERNAL_ACCESS_INTEGRATION, {{in_sf_env}}_PUSH_NOT_RDS_DIGITAL_EXTERNAL_ACCESS_INTEGRATION )
SECRETS = ('cred'={{in_sf_env}}_EXCHANGE_RAW.PEXAKEY.PEXAKEY_RDS_DIGITAL_CREDENTIAL, 'host'={{in_sf_env}}_EXCHANGE_RAW.PEXAKEY.PEXAKEY_RDS_DIGITAL_HOST, 'cred_push_not'={{in_sf_env}}_EXCHANGE_RAW.API_PUSH_NOTIFICATION.PUSH_NOT_RDS_DIGITAL_CREDENTIAL)
EXECUTE AS OWNER
AS 
$$
import _snowflake
import snowflake.snowpark as snowpark

import snowflake.snowpark.functions as fn # import col, lit, current_timestamp, parse_json
import snowflake.snowpark.types as snowtype

import psycopg2
from psycopg2.sql import SQL, Identifier, Literal
from psycopg2.extras import NamedTupleCursor

import json

from datetime import datetime
import pytz

from typing import List, Dict, Any

def pickval(p: int, min: int, max: int, default: int) -> str:
    if p is None:
        return str(default) if default is not None else ""
    if p < min:
        return str(min)
    if p > max:
        return str(max)
    return str(p)


class SnowLogger:
    def __init__(self, session: snowpark.Session, load_type: str, database: str, schema: str, table: str) -> None:
        self.session = session
        self.load_type = load_type
        self.table_name = f"{database}.{schema}.LOAD_TRACKING"
        self.schema = schema
        self.table = table
        self._setup_logger()

    def _setup_logger(self) -> None:
        """Create table for tracking data loads"""
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS IDENTIFIER(?) (
            LOAD_ID NUMBER IDENTITY(1,1),
            SESSION_ID VARCHAR NOT NULL DEFAULT CURRENT_SESSION(),
            LOG_TIME TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
            LOAD_TYPE VARCHAR NOT NULL,
            SCHEMA_NAME VARCHAR NOT NULL,
            TABLE_NAME VARCHAR NOT NULL,
            STATUS VARCHAR NOT NULL,
            MESSAGE VARIANT,
            PRIMARY KEY (LOAD_ID)
        );
        """
        self.session.sql(create_table_sql, params=[self.table_name]).collect()
        self.log_sql_template = f"""
            INSERT INTO IDENTIFIER(?) (LOAD_TYPE, SCHEMA_NAME, TABLE_NAME, STATUS, MESSAGE)
            SELECT ?, ?, ?, ?, parse_json(?)
        """

    def _log_load_event(self, status: str, message: Any):
        """Log load event details"""
        self.session.sql(self.log_sql_template,
                         params=[self.table_name, self.load_type, self.schema, self.table, status, json.dumps(message)]
        ).collect()

    def error(self, message: Any, raise_error: bool) -> None:
        """Log error message"""
        self._log_load_event("ERROR", {"error_message": message})
        if raise_error:
            raise Exception(message)

    def log(self, message: Any) -> None:
        """Log informational message"""
        self._log_load_event("INFO", {"message": message})

    def info(self, message: Any) -> None:
        """Log informational message"""
        self._log_load_event("INFO", {"message": message})

    def debug(self, message: Any) -> None:
        """Log informational message"""
        self._log_load_event("DEBUG", {"message": message})


class RDSSnowflakeLoader:
    # max len supported by Snowflake was 16,777,216
    # new max len for VARCHAR is 134,217,728
    max_varchar_length = 134217728

    data_type_mapping = {
        # string types
        "character": {
            "dml": lambda length, precision, scale: f"VARCHAR({pickval(length, 1, RDSSnowflakeLoader.max_varchar_length, None)})",
            "type": lambda length, precision, scale: snowtype.StringType(pickval(length, 1, RDSSnowflakeLoader.max_varchar_length, None))},
        "character varying": {
            "dml": lambda length, precision, scale: f"VARCHAR({pickval(length, 1, RDSSnowflakeLoader.max_varchar_length, None)})",
            "type": lambda length, precision, scale: snowtype.StringType(pickval(length, 1, RDSSnowflakeLoader.max_varchar_length, None))},
        "text": {
            "dml": lambda length, precision, scale: "VARCHAR",
            "type": lambda length, precision, scale: snowtype.StringType()},

        # integer types
        "bigint": {
            "dml": lambda length, precision, scale: "NUMBER",
            "type": lambda length, precision, scale: snowtype.LongType()},
        "bigserial": {
            "dml": lambda length, precision, scale: "NUMBER",
            "type": lambda length, precision, scale: snowtype.LongType()},
        "integer": {
            "dml": lambda length, precision, scale: "NUMBER",
            "type": lambda length, precision, scale: snowtype.LongType()},
        "smallint": {
            "dml": lambda length, precision, scale: "NUMBER",
            "type": lambda length, precision, scale: snowtype.LongType()},
        "smallserial": {
            "dml": lambda length, precision, scale: "NUMBER",
            "type": lambda length, precision, scale: snowtype.LongType()},
        "serial": {
            "dml": lambda length, precision, scale: "NUMBER",
            "type": lambda length, precision, scale: snowtype.LongType()},

        # fixed point types
        "numeric": {
            "dml": lambda length, precision, scale: f"NUMBER({pickval(precision, 1, 38, 38)}, {pickval(scale, 0, pickval(precision, 1, 38, 38) - 1, 0)})",
            "type": lambda length, precision, scale: snowtype.DecimalType(pickval(precision, 1, 38, 38), pickval(scale, 0, pickval(precision, 1, 38, 38) - 1, 0))},

        # floating point types
        "double precision": {
            "dml": lambda length, precision, scale: "FLOAT",
            "type": lambda length, precision, scale: snowtype.DoubleType()},
        "float": {
            "dml": lambda length, precision, scale: "FLOAT",
            "type": lambda length, precision, scale: snowtype.DoubleType()},
        "real": {
            "dml": lambda length, precision, scale: "FLOAT",
            "type": lambda length, precision, scale: snowtype.DoubleType()},

        # boolean type
        "boolean": {
            "dml": lambda length, precision, scale: "BOOLEAN",
            "type": lambda length, precision, scale: snowtype.BooleanType()},

        # variant types
        "json": {
            "dml": lambda length, precision, scale: "VARIANT",
            "type": lambda length, precision, scale: snowtype.VariantType()},
        "jsonb": {
            "dml": lambda length, precision, scale: "VARIANT",
            "type": lambda length, precision, scale: snowtype.VariantType()},

        # date/time types
        "date": {
            "dml": lambda length, precision, scale: "DATE",
            "type": lambda length, precision, scale: snowtype.DateType()},
        "time": {
            "dml": lambda length, precision, scale: f"TIME({pickval(precision, 0, 9, 9)})",
            "type": lambda length, precision, scale: snowtype.TimeType()},  # doesn't seem to support precision
        "time with time zone": {  # there is no time with time zone in Snowflake
            "dml": lambda length, precision, scale: f"TIME({pickval(precision, 0, 9, 9)})",
            "type": lambda length, precision, scale: snowtype.TimeType()},  # doesn't seem to support precision
        "time without time zone": {
            "dml": lambda length, precision, scale: f"TIME({pickval(precision, 0, 9, 9)})",
            "type": lambda length, precision, scale: snowtype.TimeType()},  # doesn't seem to support precision
        "timestamp": {
            "dml": lambda length, precision, scale: f"TIMESTAMP_NTZ({pickval(precision, 0, 9, 9)})",
            "type": lambda length, precision, scale: snowtype.TimestampType(snowtype.TimestampTimeZone.NTZ)},  # doesn't seem to support precision
        "timestamp with time zone": {
            "dml": lambda length, precision, scale: f"TIMESTAMP_TZ({pickval(precision, 0, 9, 9)})",
            "type": lambda length, precision, scale: snowtype.TimestampType(snowtype.TimestampTimeZone.TZ)},  # doesn't seem to support precision
        "timestamp without time zone": {
            "dml": lambda length, precision, scale: f"TIMESTAMP_NTZ({pickval(precision, 0, 9, 9)})",
            "type": lambda length, precision, scale: snowtype.TimestampType(snowtype.TimestampTimeZone.NTZ)},  # doesn't seem to support precision
    }
    data_type_mapping_for_unknown = data_type_mapping["text"]

    def __init__(self, session: snowpark.Session, load_type: str, database: str, schema: str, table: str) -> None:
        self.load_type = load_type.upper()
        self.session = session
        self.database = database
        self.schema = schema
        self.table = table
        self.rds_conn = None

        self.logger = SnowLogger(session, self.load_type, database, schema, table)
        if self.load_type not in ["FULL", "PARTIAL", "INCREMENTAL"]:
            self.logger.error(ValueError(f"Invalid load type: {load_type}"), True)

    def _connect_rds(self, rds_secret: Dict) -> None:
        """Connect to RDS using credentials"""
        try:
            self.rds_conn = psycopg2.connect(
                host=rds_secret["host"],
                port=rds_secret["port"],
                database=rds_secret["database"],
                user=rds_secret["user"],
                password=rds_secret["password"],
                cursor_factory=NamedTupleCursor
            )
        except Exception as e:
            self.logger.error(f"RDS Connection Error: {str(e)}", True)

    def _get_rds_table_metadata(self, schema: str, table: str) -> Dict:
        """Get table metadata from RDS"""
        try:
            table_meta = {}
            with self.rds_conn.cursor() as cursor:
                # find the true name
                cursor.execute(SQL("""
                    SELECT table_schema, table_name
                    FROM information_schema.tables
                    WHERE lower(table_schema) = lower({schema})
                    AND lower(table_name) = lower({table})
                """).format(schema=Literal(schema), table=Literal(table)))
                rows = cursor.fetchall()[0]
                schema=rows.table_schema
                table=rows.table_name

                # Get primary key columns
                cursor.execute(SQL("""
                    SELECT a.attname
                    FROM pg_index i
                    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
                    WHERE i.indrelid = '{source_rel}'::regclass
                    AND i.indisprimary
                """).format(source_rel=Identifier(schema, table)))

                table_meta["primary_keys"] = [row.attname for row in cursor.fetchall()]

                # Get column metadata
                cursor.execute(SQL("""
                    SELECT 
                        column_name,
                        data_type,
                        character_maximum_length,
                        numeric_precision,
                        numeric_scale,
                        is_nullable
                    FROM information_schema.columns
                    WHERE table_schema = {schema}
                    AND table_name = {table}
                    ORDER BY ordinal_position
                """).format(schema=Literal(schema), table=Literal(table)))
                table_meta["columns"] = cursor.fetchall()

            table_meta["rds_query"] = SQL("SELECT {fields} FROM {table} ORDER BY {pk}").format(
                fields=SQL(",").join([SQL("{}" + ("::text" if column.data_type.startswith("json") else "")).format(Identifier(column.column_name))
                                      for column in table_meta["columns"]]),
                table=Identifier(schema, table),
                pk=SQL(",").join([Identifier(pk) for pk in table_meta["primary_keys"]] or [Literal(1)])
            )

            field_list = []
            cols = []
            dml_col_and_types = []
            for column in table_meta["columns"]:
                col_name = column.column_name.upper()
                data_type = column.data_type.lower()
                is_nullable = "NOT NULL" if column.is_nullable=="NO" else ""
                col_mapper = RDSSnowflakeLoader.data_type_mapping.get(data_type, RDSSnowflakeLoader.data_type_mapping_for_unknown)
                field_list.append(snowtype.StructField(
                    col_name,
                    col_mapper["type"](column.character_maximum_length, column.numeric_precision, column.numeric_scale),
                    column.is_nullable=="YES"
                ))

                if data_type.startswith("json"):
                    cols.append(fn.parse_json(fn.col(col_name)).alias(col_name))
                else:
                    cols.append(fn.col(col_name))

                dml_col_and_types.append([col_name, col_mapper["dml"](column.character_maximum_length, column.numeric_precision, column.numeric_scale), is_nullable])

            table_meta["snow_schema"] = snowtype.StructType(field_list) 
            table_meta["snow_cols"] = cols
            table_meta["dml_col_and_types"] = dml_col_and_types

            return table_meta
        except Exception as e:
            self.logger.error(f"Error fetching table metadata: {str(e)}", True)

    def _sync_target_schema(self, rds_metadata: Dict, target_db: str, target_table: str) -> List[str]:
        """Synchronize table schema with RDS"""
        new_columns = []
        try:
            # Create target table if not exists
            create_target_sql=f"""
                CREATE TABLE IF NOT EXISTS IDENTIFIER(?) (
                    {",".join([f"{col[0]} {col[1]} {col[2]}" for col in rds_metadata["dml_col_and_types"]])},
                    INSERTED_AT TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
                    LOAD_TYPE VARCHAR(20)
                )
            """
            result = self.session.sql(create_target_sql, params=[target_table]).collect()
            if result is None:
                raise ValueError(f"Failed to create or access target table: {target_table}")
            # If preexisting table, need to sync schema
            if "already exists" in result[0]["status"]:
                # Get existing Snowflake columns
                # Use the DataFrame schema attribute (StructType) for a direct
                # comparison against the metadata from RDS
                dataframe = self.session.table(target_table).limit(0)
                sf_columns = {field.name: [field.datatype, field.nullable] for field in dataframe.schema.fields}

                alter_sql = "ALTER TABLE IDENTIFIER(?) ADD COLUMN IF NOT EXISTS {} {} {}"
                col_number = 0
                data_type_changes = False
                for field in rds_metadata["snow_schema"].fields:
                    if field.name not in (sf_columns):
                        # print(f"missing col {field.name}")
                        # Add new column
                        self.session.sql(alter_sql.format(*rds_metadata["dml_col_and_types"][col_number]), params=[target_table]).collect()
                        new_columns.append(field.name)
                    #elif repr(field.datatype) != repr(sf_columns[field.name][0]) or field.nullable != sf_columns[field.name][1]:
                    #    data_type_changes = True
                    #    self.logger.error(f"Data type change detected for column {field.name} to '{[field.datatype, field.nullable]}' from '{sf_columns[field.name]}'.", False)
                    col_number += 1
                #if data_type_changes:
                #    raise Exception("Data type changes detected. Manual intervention required.")

            return new_columns
        except Exception as e:
            self.logger.error(f"Schema sync error: {str(e)}", True)

    def load_data(self,
                  source_schema: str,
                  rds_secret: Dict,
                  incremental_key: str = None,
                  batch_size: int = 100000) -> Dict:
        """
        Main data loading method
        
        Args:
            source_schema (str): RDS source schema
            rds_secret (Dict): RDS connection parameters
            incremental_key (str): Column for incremental loads
            batch_size (int): Batch size for loading
            
        Returns:
            Dict: Load results
        """
        start_time = datetime.now()
        staging_table = f"{self.database}.{self.schema}.stg_{self.table}".lower()
        target_table = f"{self.database}.{self.schema}.{self.table}".lower()
        load_params = {
            "table_name": self.table,
            "load_type": self.load_type,
            "source_schema": source_schema,
            "target_db": self.database,
            "target_schema": self.schema,
            "incremental_key": incremental_key,
            "batch_size": batch_size
        }

        try:
            # Connect to RDS
            self._connect_rds(rds_secret)

            # Get table metadata
            metadata = self._get_rds_table_metadata(source_schema, self.table)
            if not metadata["primary_keys"]:
                raise ValueError(f"No primary key found for {self.table}")

            # Create staging table
            self.session.sql(f"""
                CREATE TABLE IF NOT EXISTS IDENTIFIER(?) (
                    {",".join([f"{col[0]} {col[1]} {col[2]}" for col in metadata["dml_col_and_types"]])}
                )
            """, params=[staging_table]).collect()

            # Check for schema changes
            new_columns = self._sync_target_schema(metadata, self.database, target_table)

            # Build incremental query
            if self.load_type == "INCREMENTAL" and incremental_key:
                last_value=self.session.sql("""
                    SELECT NVL(TO_CHAR(MAX(inserted_at), 'YYYY-MM-DD HH24:MI:SS.FF3'), '1900-01-01 00:00:00.000') as last_load_date
                    FROM IDENTIFIER(?)
                """, params=[target_table]).collect()
                metadata["rds_query"] = SQL("WITH cte AS (") + metadata["rds_query"] + SQL(") SELECT * FROM cte WHERE {} AT TIME ZONE 'Australia/Melbourne' > TO_TIMESTAMP({}, 'YYYY-MM-DD HH24:MI:SS.FF3')").format(Identifier(incremental_key), Literal(last_value[-1]["LAST_LOAD_DATE"]))
            metadata["rds_query"] = metadata["rds_query"] + SQL(" LIMIT %s OFFSET %s")
            
            # Load data in batches
            total_records = 0
            offset = 0
            aest_timezone = pytz.timezone("Australia/Sydney")
            load_ts = datetime.now(aest_timezone).strftime("%Y-%m-%d %H:%M:%S%f %z")
            with self.rds_conn.cursor() as cursor:
                while True:
                    cursor.execute(metadata["rds_query"], [batch_size, offset])
                    batch = cursor.fetchall()
                    if not batch:
                        break

                    # Convert to DataFrame and write to staging
                    snow_df = self.session.create_dataframe(batch, metadata["snow_schema"]).select(metadata["snow_cols"])
                    snow_df.write.mode("append").save_as_table(staging_table)

                    total_records += len(batch)
                    offset += batch_size

            if self.load_type == "FULL":
                self.session.sql(f"TRUNCATE TABLE IDENTIFIER(?)", params=[target_table]).collect()

            # Perform merge
            merge_sql = f"""
                INSERT INTO IDENTIFIER(?) ({",".join([col[0] for col in metadata["dml_col_and_types"]])}, INSERTED_AT, LOAD_TYPE)
                    SELECT {",".join([col[0] for col in metadata["dml_col_and_types"]])},
                        TO_TIMESTAMP_TZ(?, 'YYYY-MM-DD HH24:MI:SSFF9 TZHTZM')::TIMESTAMP_TZ(3), ?
                    FROM IDENTIFIER(?)
            """
            self.session.sql(merge_sql, params=[target_table, load_ts, self.load_type, staging_table]).collect()

            # Log success
            self.logger.log({
                "records_processed": total_records,
                "new_columns": new_columns,
                "load_params": load_params
            })

            return {
                "status": "SUCCESS",
                "records_processed": total_records,
                "new_columns": new_columns,
                "execution_time": (datetime.now() - start_time).total_seconds()
            }

        except Exception as e:
            error_msg = str(e)
            self.logger.error({
                "error_message": error_msg,
                "load_params": load_params
            },True)

            return {
                "status": "FAILURE",
                "err_msg": error_msg,
                "execution_time": (datetime.now() - start_time).total_seconds()
            }

        finally:
            # Clean up
            self.session.sql(f"DROP TABLE IF EXISTS IDENTIFIER(?)", params=[staging_table]).collect()
            if self.rds_conn:
                self.rds_conn.close()

def model(
        session: snowpark.Session,
        table_name: str,
        load_type: str,
        source_schema: str,
        target_db: str,
        target_schema: str,
        incremental_key: str = None,
        batch_size: int = 100000):

    lv_cred=''
    lv_host=''
    lv_port=''
    if target_schema.upper() == 'PEXAKEY':
        lv_cred='cred'
        lv_host='host'
        lv_port='5432'
    elif target_schema.upper() == 'API_PUSH_NOTIFICATION':
        lv_cred='cred_push_not'
        lv_host='host'
        lv_port='5433'

    """Create Snowpark procedure"""
    loader = RDSSnowflakeLoader(session, load_type, target_db, target_schema, table_name)
    username_password_object = _snowflake.get_username_password(lv_cred)
    host_name = _snowflake.get_generic_secret_string(lv_host)
    port=lv_port
    
    rds_secret = {
        "host": host_name,
        "port": port,
        "database": "postgres",
        "user": username_password_object.username,
        "password": username_password_object.password
    }
    
    return loader.load_data(
        source_schema=source_schema,
        rds_secret=rds_secret,
        incremental_key=incremental_key,
        batch_size=batch_size
    )
$$;