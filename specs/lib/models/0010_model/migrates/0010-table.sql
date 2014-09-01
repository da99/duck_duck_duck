

CREATE TABLE "0010_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);


-- DOWN

DROP TABLE IF EXISTS "0010_model" CASCADE;


