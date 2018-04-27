-- PostgreSQL 9.6


-- User revisions and media have to cross-reference each other
ALTER TABLE users.user_revisions ADD FOREIGN KEY ( avatar_hash )
REFERENCES media.images ( image_hash ) MATCH FULL
    ON DELETE CASCADE
    ON UPDATE CASCADE
;
