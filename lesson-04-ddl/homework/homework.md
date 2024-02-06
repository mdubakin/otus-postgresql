# SQL. DDL

- [SQL. DDL](#sql-ddl)
  - [Topics](#topics)
  - [Tasks](#tasks)

## Topics

- Creating / altering / deleting objects (databases, roles, schemas, tables)
- Using tablespaces

## Tasks

1. Create a template database `otus_template`
2. Connect to `otus_template` database
3. Create a table `otus_table1` with attributes:
   1. `id` integer PRIMARY KEY
   2. `name` text
   3. `email` text, nullable
   4. `sex` bit, nullable
   5. `adult` bool default false, nullable
4. Describe table `otus_table1`, it's should be such:

```sql
                    Table "public.otus_table1"
 Column |          Type          | Collation | Nullable | Default
--------+------------------------+-----------+----------+---------
 id     | integer                |           | not null |
 name   | character varying(50)  |           | not null |
 email  | character varying(255) |           |          |
 sex    | bit(1)                 |           |          |
 adult  | boolean                |           |          | false
Indexes:
    "otus_table1_pkey" PRIMARY KEY, btree (id)
```

5. Create a database `otus1` from template `otus_template`
6. Find information about `otus_template` and `otus1` databases in `pg_catalog` scheme
7. Are there any tables in `otus1` database? If so, why?
8. Create directory `/tmp/tbls` and create a tablespace `tbls1`
9. Find symlink at `PGDATA` to tablespace `tbls1`
10. Alter database `otus1` to using new tablespace
11. Find which tablespace database `otus1` uses using `pg_catalog` scheme
12. Create a table `otus_table2` (any columns) in `otus1` database
13. Insert 1 row into the tables `otus_table1` and `otus_table2`
14. Find files with data in directories (`PGDATA/base`, `PGDATA/pg_tblspc`)
15. Create a role `dba` with `SUPERUSER` attribute
16. Create a user `admin`
17. Grant role `dba` to user `admin`
18. List all roles
19. Login into `otus1` as a user `admin`
20. Try to create user `user1`. Does user `admin` have rights to do this? If not, why and how to fix it?
21. Delete tablespace `tbls1`
22. Delete `otus_template` database
23. Delete roles: `admin`, `dba`, `user1`
