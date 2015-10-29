

CREATE TABLE IF NOT EXISTS "0040_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);

INSERT INTO "0040_model" (title)
VALUES ('__ up');

-- DOWN:


INSERT INTO "0040_model" (title)
VALUES ('__ down');

