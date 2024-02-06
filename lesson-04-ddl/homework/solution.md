# Solution of the DDL homework

- [Solution of the DDL homework](#solution-of-the-ddl-homework)
  - [Solving](#solving)

## Solving

> Create a template database `otus_template`

```sql
student=# CREATE DATABASE otus_template IS_TEMPLATE true;
CREATE DATABASE
```

> Connect to `otus_template` database

```sql
student=# \c otus_template postgres
You are now connected to database "otus_template" as user "postgres".
```

> Create a table `otus_table1` with attributes:

   1. `id` integer PRIMARY KEY
   2. `name` text
   4. `email` text, nullable
   5. `sex` bit, nullable
   6. `adult` bool default false, nullable

```sql
CREATE TABLE otus_table1 (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    sex BIT,
    adult BOOL DEFAULT false
);
```

> Describe table `otus_table1`, it's should be such

```sql
otus_template=# \d otus_table1
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

> Create a database `otus1` from template `otus_template`

```sql
otus_template=# CREATE DATABASE otus1 TEMPLATE otus_template;
CREATE DATABASE
```

> Find information about `otus_template` and `otus1` databases in `pg_catalog` scheme

```sql
SELECT *
FROM pg_catalog.pg_database
WHERE datname IN ('otus_template', 'otus1');
```

> Are there any tables in `otus1` database? If so, why?

```sql
-- Connect to otus1 db
otus_template=# \c otus1 postgres
You are now connected to database "otus1" as user "postgres".

-- Describe tables
otus1=# \dt
            List of relations
 Schema |    Name     | Type  |  Owner
--------+-------------+-------+----------
 public | otus_table1 | table | postgres
(2 rows)
```

Yes, database `otus1` has `otus_table1` table, because it was created from template `otus_template`

> Create directory `/tmp/tbls`:

```bash
# Create database
student:~$ sudo mkdir /tmp/tbls

# Change owner
student:~$ sudo chown postgres:postgres /tmp/tbls
```

Create tablespace `tbls1`:

```sql
postgres=# CREATE TABLESPACE tbls1 LOCATION '/tmp/tbls';
CREATE TABLESPACE
```

> Find symlink at `PGDATA` to tablespace `tbls1`:

```bash
student:~$ sudo ls -la /var/lib/postgresql/13/main/pg_tblspc
total 8
drwx------  2 postgres postgres 4096 Dec 16 09:48 .
drwx------ 19 postgres postgres 4096 Dec 15 19:34 ..
lrwxrwxrwx  1 postgres postgres    9 Dec 16 09:48 49168 -> /tmp/tbls
```

> Alter database `otus1` to using tablespace `tbls1`

```sql
postgres=# ALTER DATABASE otus1 SET TABLESPACE tbls1;
ALTER DATABASE
```

> Find which tablespace database `otus1` uses using `pg_catalog` scheme

```sql
otus1=# select datname, dattablespace from pg_catalog.pg_database;
    datname    | dattablespace
---------------+---------------
 postgres      |          1663
 student       |          1663
 template1     |          1663
 template0     |          1663
 otus_template |          1663
 otus1         |         49168
(6 rows)
```

> Create a table `otus_table2` (any columns) in `otus1` database

```sql
otus1=# CREATE TABLE otus_table2 (id integer PRIMARY KEY);
CREATE TABLE
```

> Insert 1 row into the tables `otus_table1` and `otus_table2`

```sql
-- Insert into otus_table1
otus1=# INSERT INTO otus_table1 VALUES (1, 'maxim', 'foobar@example.com', '1', true);
INSERT 0 1

-- Insert into otus_table2
otus1=# INSERT INTO otus_table2 VALUES (1);
INSERT 0 1
```

> Find files with data in directories (`PGDATA/base`, `PGDATA/pg_tblspc`)

```bash
# listing of tbls1 tablespace
student:~$ sudo ls -la /var/lib/postgresql/13/main/pg_tblspc/49168/
total 12
drwx------  3 postgres postgres 4096 Dec 16 09:48 .
drwxrwxrwt 17 root     root     4096 Dec 16 09:43 ..
drwx------  3 postgres postgres 4096 Dec 16 09:52 PG_13_202007201

# listing of pg_default tablespace
student:~$ sudo ls -la /var/lib/postgresql/13/main/base
total 28
drwx------  7 postgres postgres 4096 Dec 16 09:52 .
drwx------ 19 postgres postgres 4096 Dec 15 19:34 ..
drwx------  2 postgres postgres 4096 Dec 15 19:34 1
drwx------  2 postgres postgres 4096 Dec  8 13:11 13446
drwx------  2 postgres postgres 4096 Dec 16 09:45 13447
drwx------  2 postgres postgres 4096 Dec 16 07:26 16385
drwx------  2 postgres postgres 4096 Dec 16 07:39 49154
```

> Create a role `dba` with `SUPERUSER` attribute

```sql
postgres=# CREATE ROLE dba SUPERUSER;
CREATE ROLE
```

> Create a user `admin`

```sql
postgres=# CREATE USER admin;
CREATE ROLE
```

> Grant role `dba` to user `admin`

```sql
postgres=# GRANT dba TO admin;
GRANT ROLE
```

> List all roles

```sql
postgres=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 admin     |                                                            | {dba}
 dba       | Superuser, Cannot login                                    | {}
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 student   | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
```

> Login into `otus1` as a user `admin`

```sql
postgres=# \c otus1 admin
You are now connected to database "otus1" as user "admin".
```

> Try to create user `user1`. Does user `admin` have rights to do this? If not, why and how to fix it?

```sql
otus1=> CREATE USER user1;
ERROR:  permission denied to create role
```

No, we've got `permission denied` error. To use superuser rights from dba role we need to enable it:

```sql
-- Set dba role
otus1=> SET ROLE dba;
SET

-- Create user
otus1=# CREATE USER user1;
CREATE ROLE

-- List all users
otus1=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 admin     |                                                            | {dba}
 dba       | Superuser, Cannot login                                    | {}
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 student   | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 user1     |                                                            | {}
```

> Delete tablespace `tbls1`

```sql
-- We can't delete tablespace until we delete all the objects inside
otus1=# DROP TABLESPACE tbls1;
ERROR:  tablespace "tbls1" is not empty

-- Delete otus1 db
postgres=# DROP DATABASE otus1;
DROP DATABASE

-- Delete tablespace
postgres=# DROP TABLESPACE tbls1;
DROP TABLESPACE
```

> Delete `otus_template` database

```sql
-- Can't delete template database
postgres=# DROP DATABASE otus_template;
ERROR:  cannot drop a template database

-- Change is_template setting
postgres=# ALTER DATABASE otus_template IS_TEMPLATE false;
ALTER DATABASE

-- Delete otus_template database
postgres=# DROP DATABASE otus_template;
DROP DATABASE
```

> Delete roles: `admin`, `dba`, `user1`

```sql
postgres=# DROP ROLE admin;
DROP ROLE
postgres=# DROP ROLE dba;
DROP ROLE
postgres=# DROP ROLE user1;
DROP ROLE
```
