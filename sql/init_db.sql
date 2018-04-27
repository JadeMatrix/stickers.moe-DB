-- PostgreSQL 9.6


CREATE DATABASE stickers_moe
    TEMPLATE template0
    OWNER postgres
    ENCODING 'UTF8'
    LC_COLLATE 'C'
;


\c stickers_moe


BEGIN;


CREATE EXTENSION pgcrypto CASCADE;
CREATE EXTENSION first_last_agg CASCADE;


\i init_util_schema.sql
\i init_permissions_schema.sql
\i init_users_schema.sql
\i init_media_schema.sql
\i init_people_schema.sql
\i init_shops_schema.sql
\i init_designs_schema.sql
\i init_products_schema.sql
\i init_lists_schema.sql

\i alter_users_schema.sql


COMMIT;
