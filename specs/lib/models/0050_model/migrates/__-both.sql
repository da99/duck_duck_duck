
-- BOTH
CREATE TABLE IF NOT EXISTS "0050_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);


INSERT INTO "0050_model" (title)
VALUES ('__ both 1');


-- UP
INSERT INTO "0050_model" (title)
VALUES ('__ up 1');


-- DOWN
INSERT INTO "0050_model" (title)
VALUES ('__ down 1');

-- BOTH
INSERT INTO "0050_model" (title)
VALUES ('__ both 2');
