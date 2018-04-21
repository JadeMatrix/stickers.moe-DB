-- PostgreSQL 9.6


CREATE SCHEMA people
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE people.people_core
    (
        person_id       util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'people.people_core',
                            'person_id'
                        ),
        _a_revision     TIMESTAMP WITH TIME ZONE NOT NULL
    )
;


CREATE TABLE people.person_revisions
    (
        person_id       util.BIGID NOT NULL
                        REFERENCES people.people_core ( person_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised         TIMESTAMP WITH TIME ZONE NOT NULL,
        revised_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised_from    INET NOT NULL,
        
        person_name     TEXT NULL,
        person_user     util.BIGID UNIQUE NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        about           TEXT NOT NULL,
        
        UNIQUE ( person_id, revised ),
        CONSTRAINT "Either a person name or user must be supplied but not both"
            CHECK (
                ( person_name IS NULL )
                != ( person_user IS NULL )
            )
    )
;


-- Back-reference from shops core to revisions
ALTER TABLE people.people_core ADD FOREIGN KEY (
    person_id,
    _a_revision
)
REFERENCES people.person_revisions (
    person_id,
    revised
)
    MATCH FULL
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
;


CREATE TABLE people.person_deletions
    (
        person_id       util.BIGID NOT NULL
                        REFERENCES people.people_core ( person_id ) MATCH FULL
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


CREATE VIEW people.people AS
    SELECT
        pr.person_id,
        MIN( pr.revised ) AS created,
        MAX( pr.revised ) AS revised,
        FIRST( pr.person_name ORDER BY pr.revised DESC ) AS person_name,
        FIRST( pr.person_user ORDER BY pr.revised DESC ) AS person_user,
        FIRST( pr.about ORDER BY pr.revised DESC ) AS about,
        FIRST( pd.person_id ORDER BY pr.revised DESC ) IS NOT NULL AS deleted
    FROM
        people.person_revisions AS pr
        LEFT JOIN people.person_deletions AS pd
            ON pd.person_id = pr.person_id
    GROUP BY pr.person_id
;
