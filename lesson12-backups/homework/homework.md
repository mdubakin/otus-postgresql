Homework. Backups
=================

- [Homework. Backups](#homework-backups)
  - [Описание](#описание)
    - [Цели](#цели)
  - [Задание и выполнение](#задание-и-выполнение)
    - [Задание 1. Подготовка инфраструктуры](#задание-1-подготовка-инфраструктуры)
    - [Задание 2. Создаем БД, схему и таблицу](#задание-2-создаем-бд-схему-и-таблицу)
    - [Задание 3. Заполняем таблицу данными](#задание-3-заполняем-таблицу-данными)
    - [Задание 4. Создаем каталог для бэкапов](#задание-4-создаем-каталог-для-бэкапов)
    - [Задание 5. Создаем логический бэкап с помощью COPY](#задание-5-создаем-логический-бэкап-с-помощью-copy)
    - [Задание 6. Восстановлением состояние из бэкапа с помощью COPY](#задание-6-восстановлением-состояние-из-бэкапа-с-помощью-copy)
    - [Задание 7. Создаем логический бэкап с помощью pg\_dump](#задание-7-создаем-логический-бэкап-с-помощью-pg_dump)
    - [Задание 8. Восстановлением состояние из бэкапа с помощью pg\_restore](#задание-8-восстановлением-состояние-из-бэкапа-с-помощью-pg_restore)

Описание
--------

Бэкапы

### Цели

- применить логический бэкап. Восстановиться из бэкапа.

Задание и выполнение
--------------------

### Задание 1. Подготовка инфраструктуры

> Создаем ВМ/докер c ПГ

Сервер остался прежний с предыдущих заданий.

### Задание 2. Создаем БД, схему и таблицу

> Создаем БД, схему и в ней таблицу

```sql
-- Создаем БД backups
postgres=# CREATE DATABASE backups;
CREATE DATABASE

-- Подключаемся к созданной БД
postgres=# \c backups;
You are now connected to database "backups" as user "postgres".

-- Создаем схему backups_schema
backups=# CREATE SCHEMA backups_schema;
CREATE SCHEMA

-- Создаем таблицу backups_table внутри схемы backups_schema
backups=# CREATE TABLE backups_schema.backups_table (id integer PRIMARY KEY, name text);
CREATE TABLE
```

### Задание 3. Заполняем таблицу данными

> Заполним таблицы автосгенерированными 100 записями

```sql
-- Вставляем данные
backups=# INSERT INTO backups_schema.backups_table VALUES (generate_series(1, 100), md5(random()::text));
INSERT 0 100

-- Проверяем
backups=# SELECT * FROM backups_schema.backups_table LIMIT 10;
 id |               name
----+----------------------------------
  1 | 3ec760c9d90374c214e8cd71aef79f50
  2 | 3d519cdb7db2e473af8e4b910d4f09a1
  3 | 4c3d616eb0a2aaae7908d9692a22403a
  4 | 0b73cd612643843804f10bb930ea12dc
  5 | b0302aa8b72bf3e96e32d536f1da7e2e
  6 | aae6c1520cf4024f20a61e0ad360ee43
  7 | 6e9020c903460f0b07b4e405583df35c
  8 | c114b297ac4e8ba2c740a1589ee7779a
  9 | f2c236150ffcb5b211b5d6632d933011
 10 | c801bdfa65c9ef1cece37cec98d2806d
(10 rows)
```

### Задание 4. Создаем каталог для бэкапов

> Под линукс пользователем Postgres создадим каталог для бэкапов

```bash
# Текущая директория
postgres@fhmodlacmieaul194lf0:~/15/main$ pwd
/var/lib/postgresql/15/main

# Создаем в ней папку backups
postgres@fhmodlacmieaul194lf0:~/15/main$ mkdir backups
```

### Задание 5. Создаем логический бэкап с помощью COPY

> Сделаем логический бэкап используя утилиту COPY

**psql**:

```sql
-- Создадим бэкап
backups=# COPY backups_schema.backups_table TO '/var/lib/postgresql/15/main/backups/backups_table.sql' (DELIMITER ',');
COPY 100
```

**bash**:

```bash
# Проверим наличие и содержимое файла
postgres@fhmodlacmieaul194lf0:~/15/main/backups$ ls
backups_table.sql

postgres@fhmodlacmieaul194lf0:~/15/main/backups$ cat backups_table.sql
1,3ec760c9d90374c214e8cd71aef79f50
2,3d519cdb7db2e473af8e4b910d4f09a1
3,4c3d616eb0a2aaae7908d9692a22403a
4,0b73cd612643843804f10bb930ea12dc
5,b0302aa8b72bf3e96e32d536f1da7e2e
6,aae6c1520cf4024f20a61e0ad360ee43
7,6e9020c903460f0b07b4e405583df35c
8,c114b297ac4e8ba2c740a1589ee7779a
9,f2c236150ffcb5b211b5d6632d933011
10,c801bdfa65c9ef1cece37cec98d2806d
...
```

### Задание 6. Восстановлением состояние из бэкапа с помощью COPY

> Восстановим в 2 таблицу данные из бэкапа

```sql
-- Попробуем восстановить данные в таблицу с суффиксом 2
backups=# COPY backups_schema.backups_table2 FROM '/var/lib/postgresql/15/main/backups/backups_table.sql' (DELIMITER ',');
ERROR:  relation "backups_schema.backups_table2" does not exist

-- Создаем таблицу
backups=# CREATE TABLE backups_schema.backups_table2 (id integer PRIMARY KEY, name text);
CREATE TABLE

-- Восстанавливаем данные
backups=# COPY backups_schema.backups_table2 FROM '/var/lib/postgresql/15/main/backups/backups_table.sql' (DELIMITER ',');
COPY 100

-- Проверяем наличие данных
backups=# SELECT * FROM backups_schema.backups_table2 LIMIT 10;
 id |               name
----+----------------------------------
  1 | 3ec760c9d90374c214e8cd71aef79f50
  2 | 3d519cdb7db2e473af8e4b910d4f09a1
  3 | 4c3d616eb0a2aaae7908d9692a22403a
  4 | 0b73cd612643843804f10bb930ea12dc
  5 | b0302aa8b72bf3e96e32d536f1da7e2e
  6 | aae6c1520cf4024f20a61e0ad360ee43
  7 | 6e9020c903460f0b07b4e405583df35c
  8 | c114b297ac4e8ba2c740a1589ee7779a
  9 | f2c236150ffcb5b211b5d6632d933011
 10 | c801bdfa65c9ef1cece37cec98d2806d
(10 rows)
```

### Задание 7. Создаем логический бэкап с помощью pg_dump

> Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц

```bash
postgres@fhmodlacmieaul194lf0:~/15/main/backups$ pg_dump --dbname=backups --schema=backups_schema --table=backups_schema.backups_table* --format=c --compress=6 --file=pgdump_backups.sql
```

### Задание 8. Восстановлением состояние из бэкапа с помощью pg_restore

> Используя утилиту pg_restore восстановим в новую БД только вторую таблицу

**psql**:

```sql
-- Создадим БД backups2
postgres=# CREATE DATABASE backups2;
CREATE DATABASE

-- Создаем схему backups_schema
backups2=# CREATE SCHEMA backups_schema;
CREATE SCHEMA
```

**bash**:

```bash
# Посмотрим список объектов в бэкапе
postgres@fhmodlacmieaul194lf0:~/15/main/backups$ pg_restore -l pgdump_backups.sql
;
; Archive created at 2024-01-31 06:52:29 UTC
;     dbname: backups
;     TOC Entries: 10
;     Compression: 6
;     Dump Version: 1.14-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 15.5 (Ubuntu 15.5-1.pgdg22.04+1)
;     Dumped by pg_dump version: 15.5 (Ubuntu 15.5-1.pgdg22.04+1)
;
;
; Selected TOC Entries:
;
215; 1259 19455 TABLE backups_schema backups_table postgres
216; 1259 19463 TABLE backups_schema backups_table2 postgres
3328; 0 19455 TABLE DATA backups_schema backups_table postgres
3329; 0 19463 TABLE DATA backups_schema backups_table2 postgres
3185; 2606 19469 CONSTRAINT backups_schema backups_table2 backups_table2_pkey postgres
3183; 2606 19461 CONSTRAINT backups_schema backups_table backups_table_pkey postgres

# Восстановим бэкап с помощью pg_restore
postgres@fhmodlacmieaul194lf0:~/15/main/backups$ pg_restore --dbname=backups2 --table=backups_table2 pgdump_backups.sql
```

**psql**:

```sql
-- Проверим наличие таблицы
backups2=# \dt backups_schema.*
                 List of relations
     Schema     |      Name      | Type  |  Owner
----------------+----------------+-------+----------
 backups_schema | backups_table2 | table | postgres
(1 row)

-- Проверим данные
backups2=# SELECT * FROM backups_schema.backups_table2 LIMIT 10;
 id |               name
----+----------------------------------
  1 | 3ec760c9d90374c214e8cd71aef79f50
  2 | 3d519cdb7db2e473af8e4b910d4f09a1
  3 | 4c3d616eb0a2aaae7908d9692a22403a
  4 | 0b73cd612643843804f10bb930ea12dc
  5 | b0302aa8b72bf3e96e32d536f1da7e2e
  6 | aae6c1520cf4024f20a61e0ad360ee43
  7 | 6e9020c903460f0b07b4e405583df35c
  8 | c114b297ac4e8ba2c740a1589ee7779a
  9 | f2c236150ffcb5b211b5d6632d933011
 10 | c801bdfa65c9ef1cece37cec98d2806d
(10 rows)
```

Данные восстановлены в БД `backups2`.
