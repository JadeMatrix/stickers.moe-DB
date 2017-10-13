-- PostgreSQL 9.6


CREATE SCHEMA media
    AUTHORIZATION postgres
;


-- TYPES -----------------------------------------------------------------------


CREATE TYPE media.decency_rating_t AS
    ENUM (
        'safe',
        'questionable',
        'explicit'
    )
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE media.images
    (
        image_hash          util.raw_sha256 PRIMARY KEY,
        uploaded            TIMESTAMP WITH TIME ZONE NOT NULL,
        decency             media.decency_rating_t NOT NULL
    )
;
