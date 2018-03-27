-- PostgreSQL 9.6


CREATE SCHEMA users
    AUTHORIZATION postgres
;


-- TYPES -----------------------------------------------------------------------


CREATE TYPE users._password_type_t AS
    ENUM(
        'invalid',
        'scrypt'
    )
;


CREATE DOMAIN users.password_type_t AS
    users._password_type_t NOT NULL
;


CREATE DOMAIN users.password_hash_t AS
    BYTEA NOT NULL
;


CREATE DOMAIN users.password_salt_t AS
    BYTEA NOT NULL
;


CREATE DOMAIN users.password_factor_t AS
    INT NOT NULL
    CHECK ( VALUE > 0 )
;


CREATE TYPE users.password AS
    (
        type            users.password_type_t,
        hash            users.password_hash_t,
        salt            users.password_salt_t,
        factor          users.password_factor_t
    )
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE users.user_core
    (
        user_id         util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'users.user_core',
                            'user_id'
                        ),
        _a_revision     TIMESTAMP WITH TIME ZONE NOT NULL,
        -- _an_email       INTEGER NOT NULL,
        _email_current  BOOLEAN NOT NULL,
        password        users.password NOT NULL
    )
;


CREATE TABLE users.user_revisions
    (
        user_id         util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised         TIMESTAMP WITH TIME ZONE NOT NULL,
        revised_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised_from    INET NOT NULL,
        
        display_name    TEXT NOT NULL,
        real_name       TEXT NULL,
        avatar_hash     util.raw_sha256 NULL,
        -- ...
        
        UNIQUE ( user_id, revised )
    )
;


CREATE TABLE users.user_emails
    (
        user_id         util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        email           TEXT NOT NULL,
        current         BOOLEAN NOT NULL
                        CHECK ( current ),
        added           TIMESTAMP WITH TIME ZONE NOT NULL,
        added_by        util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        added_from      INET NOT NULL,
        
        UNIQUE ( user_id, added ),
        -- Bogus UNIQUE for back-reference
        UNIQUE ( user_id, current, added )
    )
;


-- Back-reference from user core to revisions
ALTER TABLE users.user_core ADD FOREIGN KEY (
    user_id,
    _a_revision
)
REFERENCES users.user_revisions (
    user_id,
    revised
)
    MATCH FULL
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
;


CREATE UNIQUE INDEX ON users.user_emails ( email )
    WHERE current
;


CREATE UNIQUE INDEX ON users.user_emails ( user_id )
    WHERE current
;


-- Back-reference from user core to emails
ALTER TABLE users.user_core ADD FOREIGN KEY (
    user_id,
    _a_revision,
    _email_current
)
REFERENCES users.user_emails (
    user_id,
    added,
    current
)
    MATCH FULL
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
;


CREATE TABLE users.user_deletions
    (
        user_id         util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        deleted         TIMESTAMP WITH TIME ZONE NOT NULL,
        deleted_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        deleted_from    INET NOT NULL
    )
;


-- VIEWS -----------------------------------------------------------------------


CREATE VIEW users.users AS
    WITH
        ur AS (
            SELECT
                user_id,
                MIN( revised ) AS created,
                MAX( revised ) AS revised,
                FIRST( display_name ORDER BY revised DESC ) AS display_name,
                FIRST( real_name    ORDER BY revised DESC ) AS real_name,
                FIRST( avatar_hash  ORDER BY revised DESC ) AS avatar_hash
            FROM users.user_revisions
            GROUP BY user_id
        ),
        ue AS (
            SELECT
                user_id,
                email,
                added
            FROM users.user_emails
            WHERE current
        )
    SELECT
        uc.user_id,
        uc.password,
        
        ur.created,
        ur.revised,
        ur.display_name,
        ur.real_name,
        ur.avatar_hash,
        
        ue.email
        
    FROM
        users.user_core AS uc
        JOIN ur
            ON ur.user_id = uc.user_id
        JOIN ue
            ON ue.user_id = uc.user_id
        LEFT JOIN users.user_deletions AS ud
            ON ud.user_id = uc.user_id
    WHERE ud.user_id IS NULL
;
