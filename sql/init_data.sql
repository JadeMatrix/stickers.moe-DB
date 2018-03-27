-- PostgreSQL 9.6


BEGIN;
-- SET CONSTRAINTS ALL DEFERRED;


\i init_permissions.sql
\i init_users.sql


COMMIT;
