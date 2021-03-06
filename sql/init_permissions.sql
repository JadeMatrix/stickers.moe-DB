-- PostgreSQL 9.6


INSERT INTO permissions.permissions ( permission )
VALUES
    ( 'log_in'                ),
    
    ( 'create_user'           ),
    ( 'edit_any_user'         ),
    ( 'edit_own_user'         ),
    ( 'delete_any_user'       ),
    ( 'delete_own_user'       ),
    
    ( 'edit_public_pages'     ),
    ( 'upload_files'          )
;


INSERT INTO permissions.roles ( role_name )
VALUES
    ( 'admin'  ),
    ( 'user'   ),
    ( 'banned' )
;


-- Grant the 'admin' role all permissions by default
WITH
    admin_roles AS (
        SELECT role_id
        FROM permissions.roles
        WHERE role_name = 'admin'
    ),
    admin_permissions AS (
        SELECT permission_id
        FROM permissions.permissions
    )
INSERT INTO permissions.role_permissions
SELECT
    role_id,
    permission_id
FROM
    admin_roles
    CROSS JOIN admin_permissions
;


-- Grant restricted permissions to regular users
WITH
    user_roles AS (
        SELECT role_id
        FROM permissions.roles
        WHERE role_name = 'user'
    ),
    user_permissions AS (
        SELECT permission_id
        FROM permissions.permissions
        WHERE permission IN (
            'log_in',
            'edit_own_user',
            'delete_own_user',
            'edit_public_pages',
            'upload_files'
        )
    )
INSERT INTO permissions.role_permissions
SELECT
    role_id,
    permission_id
FROM
    user_roles
    CROSS JOIN user_permissions
;
