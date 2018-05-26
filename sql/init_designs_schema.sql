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
) MATCH FULL
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


CREATE TABLE designs.design_contributor_revisions
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        added           TIMESTAMP WITH TIME ZONE NOT NULL,
        added_by        util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        added_from      INET NOT NULL,
        
        removed         TIMESTAMP WITH TIME ZONE NULL,
        removed_by      util.BIGID NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        removed_from    INET NULL,
        
        person_id       util.BIGID NOT NULL
                        REFERENCES people.people_core ( person_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        UNIQUE ( design_id, person_id, added ),
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                    ( removed IS NULL ) = ( removed_by   IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
            )
    )
;


CREATE UNIQUE INDEX ON designs.design_contributor_revisions (
    design_id,
    person_id
)
    WHERE removed IS NULL
;


CREATE TABLE designs.design_image_revisions
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        added           TIMESTAMP WITH TIME ZONE NOT NULL,
        added_by        util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        added_from      INET NOT NULL,
        
        removed         TIMESTAMP WITH TIME ZONE NULL,
        removed_by      util.BIGID NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        removed_from    INET NULL,
        
        image_hash      util.RAW_SHA256 NOT NULL
                        REFERENCES media.images ( image_hash ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        weight          util.SORTING_KEY NOT NULL,
        
        UNIQUE ( design_id, image_hash, added ),
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                    ( removed IS NULL ) = ( removed_by   IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
            )
    )
;


CREATE UNIQUE INDEX ON designs.design_image_revisions (
    design_id,
    image_hash
)
    WHERE removed IS NULL
;


CREATE TABLE designs.related_design_revisions
    (
        design_id_left  util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        design_id_right util.BIGID NOT NULL
                        REFERENCES designs.designs_core ( design_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        added           TIMESTAMP WITH TIME ZONE NOT NULL,
        added_by        util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        added_from      INET NOT NULL,
        
        removed         TIMESTAMP WITH TIME ZONE NULL,
        removed_by      util.BIGID NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        removed_from    INET NULL,
        
        CONSTRAINT "Designs cannot be related to themselves"
            CHECK ( design_id_left != design_id_right ),
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                ( removed IS NULL ) = ( removed_by IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
            )
    )
;


CREATE UNIQUE INDEX ON designs.related_design_revisions (
    LEAST   ( design_id_left, design_id_right ),
    GREATEST( design_id_left, design_id_right ),
    added
)
;


CREATE UNIQUE INDEX ON designs.related_design_revisions (
    LEAST   ( design_id_left, design_id_right ),
    GREATEST( design_id_left, design_id_right )
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


CREATE VIEW designs.design_contributors AS
    SELECT
        dcr.design_id,
        dcr.person_id,
        FIRST(
            /*
            Only at most one `removed` can be NULL, which is the one we want;
            otherwise chose the most recently added
            */
            dcr.added
            ORDER BY
                dcr.removed NULLS FIRST,
                dcr.added DESC
        ) AS added,
        (
            BOOL_OR(
                   dd.design_id IS NOT NULL -- Any design deleted
                OR pd.person_id IS NOT NULL -- Any person deleted
            )
            OR BOOL_AND( dcr.removed IS NOT NULL ) -- All relations removed
        ) AS deleted
    FROM
        designs.design_contributor_revisions AS dcr
        LEFT JOIN designs.design_deletions AS dd
            ON dd.design_id = dcr.design_id
        LEFT JOIN people.person_deletions AS pd
            ON pd.person_id = dcr.person_id
    GROUP BY ( dcr.design_id, dcr.person_id )
;


CREATE VIEW designs.design_images AS
    SELECT
        dir.design_id,
        dir.image_hash,
        FIRST(
            /*
            Only at most one `removed` can be NULL, which is the one we want;
            otherwise chose the most recently added
            */
            dir.added
            ORDER BY
                dir.removed NULLS FIRST,
                dir.added DESC
        ) AS added,
        FIRST(
            /*
            Only at most one `removed` can be NULL, which is the one we want;
            otherwise chose the most recently added weight
            */
            dir.weight
            ORDER BY
                dir.removed NULLS FIRST,
                dir.added DESC
        ) AS weight,
        (
               BOOL_OR ( dd.design_id IS NOT NULL ) -- Any design is deleted
            OR BOOL_AND( dir.removed  IS NOT NULL ) -- All relations removed
        ) AS deleted
    FROM
        designs.design_image_revisions AS dir
        LEFT JOIN designs.design_deletions AS dd
            ON dd.design_id = dir.design_id
    GROUP BY ( dir.design_id, dir.image_hash )
;


CREATE VIEW designs.related_designs AS
    WITH latest AS (
        SELECT
            design_id_left,
            design_id_right,
            (
                BOOL_OR (
                       dd_left.design_id  IS NOT NULL -- Any design deleted
                    OR dd_right.design_id IS NOT NULL -- Any design deleted
                )
                OR BOOL_AND( rdr.removed IS NOT NULL ) -- All relations removed
            ) AS deleted
        FROM
            designs.related_design_revisions AS rdr
            LEFT JOIN designs.design_deletions AS dd_left
                ON dd_left.design_id = rdr.design_id_left
            LEFT JOIN designs.design_deletions AS dd_right
                ON dd_right.design_id = rdr.design_id_right
        GROUP BY ( design_id_left, design_id_right )
    )
    SELECT
        design_id_left  AS design_id,
        design_id_right AS related_design_id,
        deleted
    FROM latest
    UNION ALL
        SELECT
            design_id_right AS design_id,
            design_id_left  AS related_design_id,
            deleted
        FROM latest
;
