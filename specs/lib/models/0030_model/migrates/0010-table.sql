-- DOWN

INSERT INTO "0030_model" (title)
VALUES ('DROP 0030_model');

-- UP:
CREATE TABLE "0030_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);




