
CREATE TABLE "0020_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);


-- DOWN

INSERT INTO "0020_model" (title)
VALUES ('DROP 0020_model');


