-- PostgreSQL 9.6


CREATE SCHEMA util
    AUTHORIZATION postgres
;


-- BIGID -----------------------------------------------------------------------


CREATE DOMAIN util.BIGID AS BIGINT
    CHECK (
        VALUE >= 1000000000000000000
        AND VALUE <= 9223372036854775807
    )
;


CREATE OR REPLACE FUNCTION util.next_nonseq_id( tbl REGCLASS, col TEXT )
    RETURNS util.BIGID AS
    $$
    DECLARE
        new_id BIGINT;
        sagasu BOOL;
        query  TEXT;
    BEGIN
        SELECT FORMAT(
            'SELECT EXISTS(
                SELECT 1
                FROM %s
                WHERE %s = $1
            )',
            tbl,
            QUOTE_IDENT( col )
        ) INTO query;
        sagasu := TRUE;
        WHILE ( sagasu ) LOOP
            SELECT (
                -- Max BIGINT is 9223372036854775807
                RANDOM()
                * 8223372036854775807
                + 1000000000000000000
            )::BIGINT INTO new_id;
            EXECUTE query INTO sagasu USING new_id;
        END LOOP;
        RETURN new_id;
    END
    $$
    LANGUAGE PLPGSQL VOLATILE
;


-- RAW HASH FIELDS -------------------------------------------------------------


CREATE DOMAIN util.raw_md5 AS BYTEA
    CHECK ( OCTET_LENGTH( VALUE ) = 16 )
;


CREATE DOMAIN util.raw_sha1 AS BYTEA
    CHECK ( OCTET_LENGTH( VALUE ) = 20 )
;


CREATE DOMAIN util.raw_sha256 AS BYTEA
    CHECK ( OCTET_LENGTH( VALUE ) = 32 )
;


CREATE DOMAIN util.raw_sha512 AS BYTEA
    CHECK ( OCTET_LENGTH( VALUE ) = 64 )
;


-- MONEY -----------------------------------------------------------------------


CREATE TYPE util.MONEY AS
    (
        amount              NUMERIC,
        denomination        TEXT
    )
;


-- MACHINE-READABLE STRINGS ----------------------------------------------------


CREATE DOMAIN util.machine_name AS TEXT
    CONSTRAINT "Machine names must be lowercase alphanumeric and underscores"
        CHECK ( VALUE ~ '^[a-z0-9_]+$' )
;


-- SORTING ---------------------------------------------------------------------


CREATE DOMAIN util.sorting_key AS BYTEA
    CHECK ( OCTET_LENGTH( VALUE ) > 0 )
;
