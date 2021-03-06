-- PostgreSQL 9.6


CREATE SCHEMA media
    AUTHORIZATION postgres
;


-- TYPES -----------------------------------------------------------------------


CREATE TYPE media.DECENCY_RATING AS
    ENUM (
        'safe',
        'questionable',
        'explicit'
    )
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE media.images
    (
        image_hash          util.RAW_SHA256 PRIMARY KEY,
        mime_type           TEXT NOT NULL,
        decency             media.DECENCY_RATING NOT NULL,
        original_filename   TEXT NULL,
        
        uploaded        TIMESTAMP WITH TIME ZONE NOT NULL,
        uploaded_by     util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        uploaded_from   INET NOT NULL
    )
;
