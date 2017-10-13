-- PostgreSQL 9.6


CREATE SCHEMA designs
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE designs.designs
    (
        design_id       util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'designs.designs',
                            'design_id'
                        ),
        
        created         TIMESTAMP WITH TIME ZONE NOT NULL,
        created_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        created_from    INET NOT NULL,
        
        deleted         TIMESTAMP WITH TIME ZONE NULL,
        deleted_by      util.BIGID NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        deleted_from    INET NULL,
        
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                ( deleted IS NULL ) = ( deleted_by IS NULL )
                AND ( deleted IS NULL ) = ( deleted_from IS NULL )
            )
    )
;


CREATE TABLE designs.design_descriptions
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs ( design_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised         TIMESTAMP WITH TIME ZONE NOT NULL,
        revised_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised_from    INET NOT NULL,
        
        description     TEXT NOT NULL,
        
        UNIQUE ( design_id, revised )
    )
;


CREATE TABLE designs.design_contributors
    (
        design_id       util.BIGID NOT NULL
                        REFERENCES designs.designs ( design_id )
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
                        REFERENCES designs.designs ( design_id )
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
