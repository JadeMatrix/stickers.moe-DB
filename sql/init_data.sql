-- PostgreSQL 9.6


BEGIN;
-- SET CONSTRAINTS ALL DEFERRED;


\i init_users.sql
\i init_permissions.sql


COMMIT;
