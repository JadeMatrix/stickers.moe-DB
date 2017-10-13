-- PostgreSQL 9.6


CREATE SCHEMA lists
    AUTHORIZATION postgres
;


-- TABLES ----------------------------------------------------------------------


CREATE TABLE lists.user_product_history
    (
        user_id         util.BIGID NOT NULL
                        REFERENCES users.user_core ( user_id ) MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        product_id      util.BIGID NOT NULL
                        REFERENCES products.products_core ( product_id )
                            MATCH FULL
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,
        revised         TIMESTAMP WITH TIME ZONE NOT NULL,
        quantity        INTEGER NOT NULL CHECK ( quantity >= 0 ),
        
        UNIQUE ( user_id, product_id, revised )
    )
;


-- VIEWS -----------------------------------------------------------------------


CREATE VIEW lists.user_product_lists AS
    WITH _ AS (
        SELECT DISTINCT ON ( user_id, product_id )
            user_id,
            product_id,
            revised,
            quantity
        FROM lists.user_product_history
        ORDER BY
            user_id,
            product_id,
            revised DESC
    )
    SELECT *
    FROM _
    WHERE quantity > 0
;
