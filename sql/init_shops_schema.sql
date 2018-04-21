-- PostgreSQL 9.6


CREATE SCHEMA shops
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE shops.shops_core
    (
        shop_id         util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'shops.shops_core',
                            'shop_id'
                        ),
        _a_revision     TIMESTAMP WITH TIME ZONE NOT NULL
    )
;


CREATE TABLE shops.shop_revisions
    (
        shop_id         util.BIGID NOT NULL
                        REFERENCES shops.shops_core ( shop_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised         TIMESTAMP WITH TIME ZONE NOT NULL,
        revised_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised_from    INET NOT NULL,
        
        shop_name       TEXT NOT NULL,
        shop_url        TEXT NULL,
        founded         DATE NULL,
        closed          DATE NULL,
        
        owner_id        util.BIGID NOT NULL
                        REFERENCES people.people_core ( person_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        
        UNIQUE ( shop_id, revised )
    )
;


-- Back-reference from shops core to revisions
ALTER TABLE shops.shops_core ADD FOREIGN KEY (
    shop_id,
    _a_revision
)
REFERENCES shops.shop_revisions (
    shop_id,
    revised
)
    MATCH FULL
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
;


CREATE TABLE shops.shop_deletions
    (
        shop_id         util.BIGID NOT NULL
                        REFERENCES shops.shops_core ( shop_id ) MATCH FULL
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


-- CREATE VIEW shops.shops AS
--     SELECT DISTINCT ON ( shop_id ) *
--     FROM shops.shop_revisions
--     ORDER BY shop_id, revised DESC
-- ;
CREATE VIEW shops.shops AS
    SELECT
        sr.shop_id,
        MIN( sr.revised ) AS created,
        MAX( sr.revised ) AS revised,
        FIRST( sr.shop_name ORDER BY sr.revised DESC ) AS shop_name,
        FIRST( sr.shop_url  ORDER BY sr.revised DESC ) AS shop_url,
        FIRST( sr.founded   ORDER BY sr.revised DESC ) AS founded,
        FIRST( sr.closed    ORDER BY sr.revised DESC ) AS closed,
        FIRST( sr.owner_id  ORDER BY sr.revised DESC ) AS owner_id,
        FIRST( sd.shop_id   ORDER BY sr.revised DESC ) IS NOT NULL AS deleted
    FROM
        shops.shop_revisions AS sr
        LEFT JOIN shops.shop_deletions AS sd
            ON sd.shop_id = sr.shop_id
    GROUP BY sr.shop_id
;
