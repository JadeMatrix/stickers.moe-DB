-- PostgreSQL 9.6


INSERT INTO users.user_core
VALUES
    (
        1000000000000000000,
        '2017-10-21 03:29:45.375989-04',
        TRUE,
        ROW( 'invalid', '', '', 1 )
    )
;

INSERT INTO users.user_revisions
VALUES
    (
        1000000000000000000,
        '2017-10-21 03:29:45.375989-04',
        1000000000000000000,
        '0.0.0.0',
        'JadeMatrix',
        NULL,
        NULL
    )
;

INSERT INTO users.user_emails
VALUES
    (
        1000000000000000000,
        'jadematrix.art@gmail.com',
        TRUE,
        '2017-10-21 03:29:45.375989-04',
        1000000000000000000,
        '0.0.0.0'
    )
;
