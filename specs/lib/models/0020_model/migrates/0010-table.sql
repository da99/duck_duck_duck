

CREATE TABLE "0020_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);


-- DOWN

DROP TABLE IF EXISTS "0020_model" CASCADE;


