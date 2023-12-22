# Solution of the DML homework

- [Solution of the DML homework](#solution-of-the-dml-homework)
  - [Solving](#solving)
    - [Sakila ER model](#sakila-er-model)

## Solving

> Restore [sakila](https://github.com/jOOQ/sakila) sample database into your PostgreSQL cluster.

```bash
# 1. Add line into pg_hba.conf 
# host all  all  192.168.64.0/24  md5

# 2. Reload postgresql
pg_ctlcluster 13 main reload

# 3. Create tables
psql -h 192.168.64.2 -p 5432 -U student -f postgres-sakila-schema.sql

# 4. Insert data
psql -h 192.168.64.2 -p 5432 -U student -f postgres-sakila-insert-data.sql
```

Ensure that data exist:

```sql
student=# \dt+
                                   List of relations
 Schema |       Name       | Type  |  Owner   | Persistence |    Size    | Description
--------+------------------+-------+----------+-------------+------------+-------------
 public | actor            | table | postgres | permanent   | 40 kB      |
 public | address          | table | postgres | permanent   | 72 kB      |
 public | category         | table | postgres | permanent   | 8192 bytes |
 public | city             | table | postgres | permanent   | 64 kB      |
 public | country          | table | postgres | permanent   | 8192 bytes |
 public | customer         | table | postgres | permanent   | 96 kB      |
 public | film             | table | postgres | permanent   | 472 kB     |
 public | film_actor       | table | postgres | permanent   | 272 kB     |
 public | film_category    | table | postgres | permanent   | 72 kB      |
 public | inventory        | table | postgres | permanent   | 272 kB     |
 public | language         | table | postgres | permanent   | 8192 bytes |
 public | payment          | table | postgres | permanent   | 984 kB     |
 public | payment_p2007_01 | table | postgres | permanent   | 0 bytes    |
 public | payment_p2007_02 | table | postgres | permanent   | 0 bytes    |
 public | payment_p2007_03 | table | postgres | permanent   | 0 bytes    |
 public | payment_p2007_04 | table | postgres | permanent   | 0 bytes    |
 public | payment_p2007_05 | table | postgres | permanent   | 0 bytes    |
 public | payment_p2007_06 | table | postgres | permanent   | 0 bytes    |
 public | rental           | table | postgres | permanent   | 1232 kB    |
 public | staff            | table | postgres | permanent   | 16 kB      |
 public | store            | table | postgres | permanent   | 8192 bytes |
(21 rows)
```

### Sakila ER model

![Sakila scheme](https://i.ibb.co/YcPs4cB/telegram-cloud-photo-size-2-5190583314724017772-y.jpg)

> Find all info about film with id = 842

```sql
student=# \x
Expanded display is on.

student=# SELECT * FROM film WHERE film_id = 842;
-[ RECORD 1 ]--------+----------------------------------------------------------------------------------------------------------------------------------------
film_id              | 842
title                | STATE WASTELAND
description          | A Beautiful Display of a Cat And a Pastry Chef who must Outrace a Mad Cow in A Jet Boat
release_year         | 2006
language_id          | 1
original_language_id |
rental_duration      | 4
rental_rate          | 2.99
length               | 113
replacement_cost     | 13.99
rating               | NC-17
last_update          | 2006-02-15 05:03:42
special_features     | {Trailers,Commentaries,"Deleted Scenes","Behind the Scenes"}
fulltext             | 'beauti':4 'boat':22 'cat':8 'chef':12 'cow':18 'display':5 'jet':21 'mad':17 'must':14 'outrac':15 'pastri':11 'state':1 'wasteland':2
```

> Find out title, language and category of the film with id = 227

```sql
student=# SELECT 
    f.title,
    l.name,
    c.name
FROM film AS f
    JOIN language AS l using(language_id)
    JOIN film_category as fc using(film_id)
    JOIN category as c on c.category_id = fc.category_id
WHERE f.film_id = 227;
     title      |         name         | name
----------------+----------------------+-------
 DETAILS PACKER | English              | Games
(1 row)
```

> Find ids of films containing FOO in the title

```sql
student=# SELECT film_id from film WHERE title LIKE '%FOO%';
 film_id
---------
      56
     327
     597
(3 rows)
```

> Find ids of films starting with D and ending with R

```sql
student=# SELECT film_id from film WHERE title SIMILAR TO 'D%R';
 film_id
---------
     206
     209
     212
     227
     233
     235
     259
     264
     265
(9 rows)
```
