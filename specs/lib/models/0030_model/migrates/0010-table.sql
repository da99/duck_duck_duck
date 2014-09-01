

CREATE TABLE "0030_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);


-- DOWN

DROP TABLE IF EXISTS "0030_model" CASCADE;


