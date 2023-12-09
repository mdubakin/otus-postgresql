Homework. SQL and Relational DBMS. Introduction to PostgreSQL
=================

- [Homework. SQL and Relational DBMS. Introduction to PostgreSQL](#homework-sql-and-relational-dbms-introduction-to-postgresql)
  - [Описание](#описание)
    - [Цель](#цель)
  - [Задание и выполнение](#задание-и-выполнение)

Описание
--------

Работа с уровнями изоляции транзакции в PostgreSQL

### Цель

- научиться работать с Google Cloud Platform на уровне Google Compute Engine (IaaS)
- научиться управлять уровнем изолции транзации в PostgreSQL и понимать особенность работы уровней read commited и repeatable read

Задание и выполнение
--------------------

> создать новый проект в Google Cloud Platform, Яндекс облако или на любых ВМ, докере

> далее создать инстанс виртуальной машины с дефолтными параметрами

> добавить свой ssh ключ в metadata ВМ

> зайти удаленным ssh (первая сессия), не забывайте про ssh-add

Создал виртуальную машину локально с ОС `Ubuntu 20.04`. Добавил свой `pubkey` пользователю `ubuntu`.

> поставить PostgreSQL

Воспользуемся официальной [документацией](https://www.postgresql.org/download/linux/ubuntu/).

Ввел команды:

```bash
# Create the file repository configuration
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists
sudo apt-get update

# Install PostgreSQL 15
sudo apt-get -y install postgresql-15
```

PostgreSQL установлен и запущен:

```bash
$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

> зайти вторым ssh (вторая сессия)

> запустить везде psql из под пользователя postgres

Зашел в обоих терминальных сессиях в `psql` под пользователем `postgres`:

```bash
sudo -u postgres psql

psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=#
```

> выключить `autocommit`

Выключил `autocommit`:

```bash
postgres=# \set AUTOCOMMIT off
postgres=# select txid_current();
 txid_current
--------------
          737
(1 row)

postgres=*# select txid_current();
 txid_current
--------------
          737
(1 row)
```

> в первой сессии новую таблицу и наполнить ее данными

Выполнил команду:

```sql
postgres=# create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;

CREATE TABLE
INSERT 0 1
INSERT 0 1
COMMIT
```

> посмотреть текущий уровень изоляции

Текущий уровень изоляции:

```sql
postgres=# show transaction isolation level;
 transaction_isolation
-----------------------
 read committed
(1 row)
```

> начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции

> в первой сессии добавить новую запись `insert into persons(first_name, second_name) values('sergey', 'sergeev')`;

> сделать `select * from persons` во второй сессии

Начинаем транзакции в обоих сессиях, добавляем запись в первой сессии и смотрим есть ли запись во второй:

```sql
1 | postgres=# begin;
BEGIN

2 | postgres=# begin;
BEGIN

1 | postgres=*# insert into persons(first_name, second_name) values('sergey', 'sergeev');
INSERT 0 1

2 | postgres=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```

> видите ли вы новую запись и если да то почему?

Нет, не вижу, так как у нас установлен уровень изоляции `read committed`, который не позволяет попасть *грязному чтению* (незакомиченые данные) в другие транзакции.

> завершить первую транзакцию - `commit`;

> сделать `select * from persons` во второй сессии

Завершаю транзакцию в первой сессии и смотрю содержимое таблицы `persons` из второй сессии:

```sql
1 | postgres=*# commit;
COMMIT

2 | postgres=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```

> видите ли вы новую запись и если да то почему?

Да, вижу, потому что данные были закомичены в первой сессии, значит станут видны для транзакций с уровнем изоляции `read committed`.

> завершите транзакцию во второй сессии

Завершаем транзакцию во второй сессии:

```sql
2 | postgres=*# commit;
COMMIT
```

> начать новые но уже `repeatable read` транзации - `set transaction isolation level repeatable read;`

> в первой сессии добавить новую запись `insert into persons(first_name, second_name) values('sveta', 'svetova');`

> сделать `select * from persons` во второй сессии

Начинаем `repeatable read` транзакции в обоих сессиях. Добавляем запись в первой сессии. Смотрим результат во второй:

```sql
-- Запускаем транзакции
1 | postgres=# set transaction isolation level repeatable read;
SET
1| postgres=*# show transaction isolation level;
 transaction_isolation
-----------------------
 repeatable read
(1 row)

2 | postgres=# set transaction isolation level repeatable read;
SET
2 | postgres=*# show transaction isolation level;
 transaction_isolation
-----------------------
 repeatable read
(1 row)

-- Записываем данные в таблицу в первой сессии
1 | postgres=*# insert into persons(first_name, second_name) values('sveta', 'svetova');
INSERT 0 1

-- Читаем данные из таблицы во второй сессии
2 | postgres=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```

> видите ли вы новую запись и если да то почему?

Нет, у нас установлен уровень изоляции `repeatable read`, который имеет больше блокировок, включая блокировки `read committed`.

> завершить первую транзакцию - `commit`;

> сделать `select * from persons` во второй сессии

Завершаем первую транзакцию и смотрим результат во второй сессии:

```sql
1 | postgres=*# commit;
COMMIT

2 | postgres=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```

> видите ли вы новую запись и если да то почему?

Нет, не вижу, потому что у нас стоит уровень изоляции `repeatable read`, который гарантирует повторное чтение без изменений.

> завершить вторую транзакцию

> сделать `select * from persons` во второй сессии

Завершаем транзакцию во второй сессии и там же смотрим таблицу `persons`:

```sql
2 | postgres=*# commit;
COMMIT

2 | postgres=# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
  4 | sveta      | svetova
(4 rows)
```

> видите ли вы новую запись и если да то почему?

Да, вижу, потому что мы завершили транзакцию и теперь уровень изоляции `repeatable read` позволит нам увидеть данные, которые были изменены во время работы нашей транзакции.
