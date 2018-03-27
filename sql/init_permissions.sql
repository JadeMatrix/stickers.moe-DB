-- PostgreSQL 9.6


INSERT INTO permissions.roles ( role_name )
VALUES ( 'admin' )
;


WITH admin_roles AS (
        SELECT role_id
        FROM permissions.roles
        WHERE role_name = 'admin'
    )
INSERT INTO permissions.user_roles
SELECT
    1000000000000000000,
    role_id
FROM admin_roles
;
