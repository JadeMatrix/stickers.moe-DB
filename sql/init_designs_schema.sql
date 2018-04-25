-- PostgreSQL 9.6


CREATE SCHEMA designs
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE designs.designs_core
    (
        design_id       util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'designs.designs_core',
                            'design_id'
                        ),
        _a_revision     TIMESTAMP WITH TIME ZONE NOT NULL
    )
;


CREATE TABLE designs.design_revisions
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised         TIMESTAMP WITH TIME ZONE NOT NULL,
        revised_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised_from    INET NOT NULL,
        
        description     TEXT NOT NULL,
        
        UNIQUE ( design_id, revised )
    )
;


-- Back-reference from designs core to revisions
ALTER TABLE designs.designs_core ADD FOREIGN KEY (
    design_id,
    _a_revision
)
REFERENCES designs.design_revisions (
    design_id,
    revised
)
    MATCH FULL
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
;


CREATE TABLE designs.design_deletions
    (
        design_id       util.BIGID PRIMARY KEY
                        REFERENCES designs.designs_core ( design_id ) MATCH FULL
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


CREATE TABLE designs.design_contributors
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        added           TIMESTAMP WITH TIME ZONE NOT NULL,
        added_by        util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        added_from      INET NOT NULL,
        
        removed         TIMESTAMP WITH TIME ZONE NULL,
        removed_by      util.BIGID NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        removed_from    INET NULL,
        removal_reason  TEXT NULL,
        
        person_id       util.BIGID NOT NULL
                        REFERENCES people.people_core ( person_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                ( removed IS NULL ) = ( removed_by IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
                AND ( removed IS NULL ) = ( removal_reason IS NULL )
            )
    )
;


CREATE UNIQUE INDEX ON designs.design_contributors (
    design_id,
    person_id
)
    WHERE removed IS NULL
;


CREATE TABLE designs.design_images
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        added           TIMESTAMP WITH TIME ZONE NOT NULL,
        added_by        util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        added_from      INET NOT NULL,
        
        removed         TIMESTAMP WITH TIME ZONE NULL,
        removed_by      util.BIGID NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        removed_from    INET NULL,
        removal_reason  TEXT NULL,
        
        image_hash      util.raw_sha256 NOT NULL
                        REFERENCES media.images ( image_hash )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        weight          INT NOT NULL DEFAULT 0,
        
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                ( removed IS NULL ) = ( removed_by IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
                AND ( removed IS NULL ) = ( removal_reason IS NULL )
            )
    )
;


CREATE UNIQUE INDEX ON designs.design_images (
    design_id,
    image_hash
)
    WHERE removed IS NULL
;


-- VIEWS -----------------------------------------------------------------------


CREATE VIEW designs.designs AS
    SELECT
        dr.design_id,
        MIN( dr.revised ) AS created,
        MAX( dr.revised ) AS revised,
        FIRST( dr.description ORDER BY dr.revised DESC ) AS description,
        FIRST( dd.design_id   ORDER BY dr.revised DESC ) IS NOT NULL AS deleted
    FROM
        designs.design_revisions AS dr
        LEFT JOIN designs.design_deletions AS dd
            ON dd.design_id = dr.design_id
    GROUP BY dr.design_id
;


