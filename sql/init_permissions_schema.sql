-- PostgreSQL 9.6


CREATE SCHEMA permissions
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE permissions.permissions
    (
        permission_id   util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'permissions.permissions',
                            'permission_id'
                        ),
        permission      util.MACHINE_NAME UNIQUE NOT NULL
    )
;


CREATE TABLE permissions.roles
    (
        role_id         util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'permissions.roles',
                            'role_id'
                        ),
        role_name       TEXT UNIQUE NOT NULL
    )
;


CREATE TABLE permissions.role_permissions
    (
        role_id         util.BIGID NOT NULL
                        REFERENCES permissions.roles ( role_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        permission_id   util.BIGID NOT NULL
                        REFERENCES permissions.permissions ( permission_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        UNIQUE ( role_id, permission_id )
    )
;
