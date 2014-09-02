
CREATE TABLE "0010_model" (
  id serial NOT NULL PRIMARY KEY,
  title varchar(100)
);


-- DOWN

INSERT INTO "0010_model" (title)
VALUES ('DROP 0010_model');


