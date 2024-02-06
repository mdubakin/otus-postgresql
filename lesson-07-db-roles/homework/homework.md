Homework. Creating databases and roles
=================

- [Homework. Creating databases and roles](#homework-creating-databases-and-roles)
  - [Описание](#описание)
    - [Цель](#цель)
  - [Задание и выполнение](#задание-и-выполнение)

Описание
--------

Работа с базами данных, пользователями и правами.

### Цель

- создание новой базы данных, схемы и таблицы
- создание роли для чтения данных из созданной схемы созданной базы данных
- создание роли для чтения и записи из созданной схемы созданной базы данных

Задание и выполнение
--------------------

> создайте новый кластер `PostgresSQL 14`

Установил PostgreSQL 14 на той же VM:

```bash
# Устанавливаем PostgreSQL 14
student@fhmkmqdhho3hm5m81l5g:~$ sudo apt install postgresql-14

# Подключаемся как пользователь postgres
student@fhmkmqdhho3hm5m81l5g:~$ sudo su postgres

# Смотрим список кластеров 
postgres@fhmkmqdhho3hm5m81l5g:/home/student$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory               Log file
14  main    5433 online postgres /var/lib/postgresql/14/main  /var/log/postgresql/postgresql-14-main.log
15  main    5432 online postgres /mnt/postgresql_data/15/main /var/log/postgresql/postgresql-15-main.log
```

> зайдите в созданный кластер под пользователем `postgres`

```bash
postgres@fhmkmqdhho3hm5m81l5g:/home/student$ psql -p 5433
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1), server 14.10 (Ubuntu 14.10-1.pgdg22.04+1))
Type "help" for help.

postgres=#
```

> создайте новую базу данных `testdb`

> зайдите в созданную базу данных под пользователем `postgres`

```sql
-- Создаем базу данных testdb
postgres=# CREATE DATABASE testdb;
CREATE DATABASE

-- Подключаемся к ней
postgres=# \c testdb postgres
You are now connected to database "testdb" as user "postgres".
testdb=#
```

> создайте новую схему `testnm`

```sql
-- Создаем схему
testdb=# CREATE SCHEMA testnm;
CREATE SCHEMA

-- Проверяем
testdb=# \dn
  List of schemas
  Name  |  Owner
--------+----------
 public | postgres
 testnm | postgres
(2 rows)
```

> создайте новую таблицу `t1` с одной колонкой `c1` типа `integer`

```sql
-- Создаем таблицу
testdb=# CREATE TABLE testnm.t1 (c1 integer);
CREATE TABLE

-- Проверяем
testdb=# \dt testnm.*
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 testnm | t1   | table | postgres
(1 row)
```

> вставьте строку со значением `c1=1`

```sql
-- Всталяем данные
testdb=# INSERT INTO testnm.t1 VALUES (1);
INSERT 0 1

-- Проверяем
testdb=# SELECT * FROM testnm.t1;
 c1
----
  1
(1 row)
```

> создайте новую роль `readonly`

```sql
-- Создаем роль
testdb=# CREATE ROLE readonly;
CREATE ROLE

-- Проверяем
testdb=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 readonly  | Cannot login                                               | {}
```

> дайте новой роли право на подключение к базе данных `testdb`

```sql
testdb=# GRANT CONNECT ON DATABASE testdb TO readonly;
GRANT
```

> дайте новой роли право на использование схемы `testnm`

```sql
testdb=# GRANT USAGE ON SCHEMA testnm TO readonly;
GRANT
```

> дайте новой роли право на `select` для всех таблиц схемы `testnm`

```sql
testdb=# GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;
GRANT
```

> создайте пользователя `testread` с паролем `test123`

```sql
testdb=# CREATE USER testread PASSWORD 'test123';
CREATE ROLE
```

> дайте роль `readonly` пользователю `testread`

```sql
-- Выдаем роль пользователю
testdb=# GRANT readonly TO testread;
GRANT ROLE

-- Проверяем
testdb=# \du
                                    List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 readonly  | Cannot login                                               | {}
 testread  |                                                            | {readonly}
```

> зайдите под пользователем `testread` в базу данных `testdb`

```bash
postgres@fhmkmqdhho3hm5m81l5g:~$ psql -h 127.0.0.1 -p 5433 -U testread -d testdb
```

> сделайте select * from t1;

> получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)

> напишите что именно произошло в тексте домашнего задания

> у вас есть идеи почему? ведь права то дали?

Нет, не получилось:

```sql
testdb=> SELECT * FROM t1;
ERROR:  relation "t1" does not exist
LINE 1: SELECT * FROM t1;
```

Потому что мы не указали схему в которой создали таблицу.

> посмотрите на список таблиц

> подсказка в шпаргалке под пунктом 20

```sql
testdb=> \dt testnm.*
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 testnm | t1   | table | postgres
(1 row)
```

> а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)

> вернитесь в базу данных `testdb` под пользователем `postgres`

> удалите таблицу `t1`

> создайте ее заново но уже с явным указанием имени схемы `testnm`

> вставьте строку со значением `c1=1`

> зайдите под пользователем testread в базу данных testdb

**Я сразу создал таблицу в схеме testnm, поэтому этот этап пропустил.**

> сделайте select *from testnm.t1;

> получилось?

Да, получилось:

```sql
testdb=> SELECT * FROM testnm.t1;
 c1
----
  1
(1 row)
```

> есть идеи почему? если нет - смотрите шпаргалку

Так получилось, потому что мы явно указываем схему.

> как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку

Чтобы такое больше не повторялось, можно добавить схему `testnm` в `search_path`:

```sql
-- Добавляем новую схему в параметр search_path
testdb=> SET search_path = testnm, public;
SET

-- Проверяем
testdb=> SELECT * FROM t1;
 c1
----
  1
(1 row)
```

> теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);

```sql
-- Создаем таблицу
testdb=> CREATE TABLE t2 (c1 integer);
ERROR:  permission denied for schema testnm
-- Ошибка, так как нет прав на схему testnm

-- Создаем таблицу в схеме public
testdb=> CREATE TABLE public.t2 (c1 integer);
CREATE TABLE

-- Вставляем данные
testdb=> INSERT INTO t2 VALUES (2);
INSERT 0 1
```

> а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?

Под ролью `readonly` да, но мы действует от лица пользователя `testread`.

> есть идеи как убрать эти права? если нет - смотрите шпаргалку

> если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды

> теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);

Для того, чтобы активировать права роли `readonly`, нужно явно на нее переключиться:

```sql
-- Активируем роль readonly
testdb=> SET ROLE readonly;
SET

-- Попробуем создать новую таблицу в схеме public
testdb=> CREATE TABLE public.t3 (c1 integer);
CREATE TABLE

-- Попробуем вставить данные в новую таблицу
testdb=> INSERT INTO t3 VALUES (3);
INSERT 0 1

/*
Получилось потому, что вы создали таблицу в схеме public.
На это права есть.
*/

-- Попробуем создать таблицу в схеме testnm.
testdb=> CREATE TABLE t3 (c1 integer);
ERROR:  permission denied for schema testnm

-- Попробуем вставить данные
testdb=> INSERT INTO t2 VALUES (3);
ERROR:  permission denied for table t2
-- Ошибка, как мы и ожидали
```
