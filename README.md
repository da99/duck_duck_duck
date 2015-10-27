
duck\_duck\_duck
==============
You won't find this useful.

However, if you are still curious:

* If you like to break up apps into smaller apps,
  and you want them to use the same db, but
  different tables, duck\_duck\_duck
  lets you migrate those mini-apps
  to the same db.

Previously...
=============

Originally, this was a node module.
The node module is no longer maintained. It is now
a Ruby gem.

Commands
=========

```bash
  cd /my/model/dir
  duck_duck_duck   up       MODEL_NAME
  duck_duck_duck   down     MODEL_NAME
  duck_duck_duck   create   MODEL_NAME  postfix
```

Sample .sql file:

```sql
  SELECT 1;
  -- DOWN
  SELECT 2

  -- UP:
  -- colons ":' are optional
  SELECT 3;

  -- DOWN:
  SELECT 4;
```
