-- PostgreSQL 9.6


CREATE SCHEMA products
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE products.products_core
    (
        product_id      util.BIGID PRIMARY KEY DEFAULT util.next_nonseq_id(
                            'products.products_core',
                            'product_id'
                        ),
        _a_revision     TIMESTAMP WITH TIME ZONE NOT NULL
    )
;


CREATE TABLE products.product_revisions
    (
        product_id      util.BIGID NOT NULL
                        REFERENCES products.products_core ( product_id )
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
        
        shop_id         util.BIGID NOT NULL
                        REFERENCES shops.shops_core ( shop_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        description     TEXT NOT NULL,
        
        UNIQUE ( product_id, revised )
    )
;


-- Back-reference from products core to revisions
ALTER TABLE products.products_core ADD FOREIGN KEY (
    product_id,
    _a_revision
)
REFERENCES products.product_revisions (
    product_id,
    revised
)
    MATCH FULL
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
;


CREATE TABLE products.product_deletions
    (
        product_id      util.BIGID PRIMARY KEY
                        REFERENCES products.products_core ( product_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        deleted         TIMESTAMP WITH TIME ZONE NOT NULL,
        deleted_by      util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        deleted_from    INET NOT NULL
    )
;


CREATE TABLE products.product_contributors
    (
        product_id      util.BIGID NOT NULL
                        REFERENCES products.products_core ( product_id )
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


CREATE UNIQUE INDEX ON products.product_contributors (
    product_id,
    person_id
)
    WHERE removed IS NULL
;


CREATE TABLE products.product_images
    (
        product_id      util.BIGID NOT NULL
                        REFERENCES products.products_core ( product_id )
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
        weight          util.sorting_key NOT NULL,
        
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                ( removed IS NULL ) = ( removed_by IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
                AND ( removed IS NULL ) = ( removal_reason IS NULL )
            )
    )
;


CREATE UNIQUE INDEX ON products.product_images (
    product_id,
    image_hash
)
    WHERE removed IS NULL
;


CREATE TABLE products.product_prices
    (
        product_id      util.BIGID NOT NULL
                        REFERENCES products.products_core ( product_id )
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
        
        price           util.MONEY NOT NULL
                        CHECK (
                            ( price ).amount >= 0
                            AND ( price ).denomination IN (
                                'USD',
                                'CAD',
                                'GBP'
                            )
                        ),
        -- Use from- and to-timestamps as a product may not always have a price
        -- (e.g. if it is not offered for sale)
        price_from      TIMESTAMP WITH TIME ZONE NOT NULL,
        price_to        TIMESTAMP WITH TIME ZONE NOT NULL,
        
        CONSTRAINT "All or no removal information must be given"
            CHECK (
                ( removed IS NULL ) = ( removed_by IS NULL )
                AND ( removed IS NULL ) = ( removed_from IS NULL )
                AND ( removed IS NULL ) = ( removal_reason IS NULL )
            ),
        CONSTRAINT "price_from must come before price_to"
            CHECK ( price_from < price_to ),
        CONSTRAINT "A product may only have one price at a time"
            EXCLUDE USING GIST (
                TSTZRANGE( price_from, price_to ) WITH &&
            )
    )
;


-- VIEWS -----------------------------------------------------------------------


CREATE VIEW products.products AS
    SELECT
        pr.product_id,
        MIN( pr.revised ) AS created,
        MAX( pr.revised ) AS revised,
        FIRST( pr.shop_id ORDER BY pr.revised DESC ) AS shop_id,
        FIRST( pr.description ORDER BY pr.revised DESC ) AS description,
        FIRST( pd.product_id ORDER BY pr.revised DESC ) IS NOT NULL AS deleted
    FROM
        products.product_revisions AS pr
        LEFT JOIN products.product_deletions AS pd
            ON pd.product_id = pr.product_id
    GROUP BY pr.product_id
;
