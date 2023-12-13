Homework. SQL and Relational DBMS. Introduction to PostgreSQL
=================

- [Homework. SQL and Relational DBMS. Introduction to PostgreSQL](#homework-sql-and-relational-dbms-introduction-to-postgresql)
  - [Описание](#описание)
    - [Цель](#цель)
  - [Задание и выполнение](#задание-и-выполнение)

Описание
--------

Установка и настройка `PostgteSQL` в контейнере `Docker`.

### Цель

- установить `PostgreSQL` в `Docker` контейнере
- настроить контейнер для внешнего подключения

Задание и выполнение
--------------------

> создать ВМ с `Ubuntu 20.04/22.04` или развернуть докер любым удобным способом

> поставить на нем `Docker Engine`

Запустил VM с `Ubuntu 20.04`. Установил `Docker Engine` с помощью команд:

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> сделать каталог `/var/lib/postgres`

Создал каталог `/var/lib/postgresql`:

```bash
mkdir /var/lib/postgresql
```

> развернуть контейнер с `PostgreSQL` 15 смонтировав в него `/var/lib/postgresql`

Развернул контейнер с сервером `PostgreSQL` 15:

```bash
# Создадим сеть для контейнеров PostgreSQL
docker network create postgresql

# Создадим контейнер с PostgreSQL 15 в сети postgresql
docker run -d \
    -p 5432:5432 \
    -v /var/lib/postgresql:/var/lib/postgresql \
    -e "POSTGRES_PASSWORD=postgres" \
    --network postgresql \
    --name postgresql-server \
    postgres:15
```

> развернуть контейнер с клиентом postgres

> подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк

Поднимаем клиент `PostgreSQL`, создаем БД homework и таблицу otus, записываем туда пару строк:

```bash
# Создаем контейнер с клиентом PostgreSQL в интерактивном режиме
docker run -it \
    --rm \
    --network postgresql \
    --name postgresql-client \
    postgres:15 \
    psql -h postgresql-server -U postgres

# Подключились
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# \conninfo
You are connected to database "postgres" as user "postgres" on host "postgresql-server" (address "172.18.0.2") at port "5432".
```

Операции внутри СУБД:

```sql
-- Создадим базу данных homework
postgres=# CREATE DATABASE homework;
CREATE DATABASE

-- Подключимся к созданной базе данных
postgres=# \c homework postgres
You are now connected to database "homework" as user "postgres".

-- Создадим таблицу otus
homework=# CREATE TABLE otus (id integer PRIMARY KEY, data varchar(255));
CREATE TABLE

-- Вставим пару значений в таблицу otus
homework=# INSERT INTO otus VALUES (1, 'foo');
INSERT 0 1
homework=# INSERT INTO otus VALUES (2, 'bar');
INSERT 0 1

-- Проверим что они на месте
homework=# SELECT * FROM otus;
 id | data
----+------
  1 | foo
  2 | bar
(2 rows)
```

> подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера

Подключусь к контейнеру со своего ноутбука:

```bash
# Подключаемся по внутреннему IP к базе данных homework
❯ psql -h 192.168.64.5 -p 5432 -U postgres -d homework

# Подключились
psql (15.5 (Homebrew))
Введите "help", чтобы получить справку.

homework=#
```

Операции внутри СУБД:

```sql
-- Посмотрим список таблиц
homework=# \d
          Список отношений
 Схема  | Имя  |   Тип   | Владелец
--------+------+---------+----------
 public | otus | таблица | postgres
(1 строка)

-- Посмотрим что в таблице есть данные
homework=# SELECT * FROM otus;
 id | data
----+------
  1 | foo
  2 | bar
(2 строки)
```

> удалить контейнер с сервером

> создать его заново

Пересоздаем контейнер с сервером:

```bash
# Смотрим список контейнеров
root@ubuntu:/home/ubuntu# docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS          PORTS                                       NAMES
56828dcf6bb6   postgres:15   "docker-entrypoint.s…"   25 minutes ago   Up 25 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   postgresql-server

# Останавливаем и удаляем контейнер
root@ubuntu:/home/ubuntu# docker stop postgresql-server && docker rm postgresql-server

# Создаем контейнер с сервером заново
docker run -d \
    -p 5432:5432 \
    -v /var/lib/postgresql:/var/lib/postgresql \
    -e "POSTGRES_PASSWORD=postgres" \
    --network postgresql \
    --name postgresql-server \
    postgres:15
```

> подключится снова из контейнера с клиентом к контейнеру с сервером

> проверить, что данные остались на месте

Подключаемся через контейнер с клиентом к серверу и проверяем данные:

```bash
# Подключаемся
docker run -it \
    --rm \
    --network postgresql \
    --name postgresql-client \
    postgres:15 \
    psql -h postgresql-server -U postgres

# Данных нет :)
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# \l
                                                List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    | ICU Locale | Locale Provider |   Access privileges
-----------+----------+----------+------------+------------+------------+-----------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            | =c/postgres          +
           |          |          |            |            |            |                 | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            | =c/postgres          +
           |          |          |            |            |            |                 | postgres=CTc/postgres
(3 rows)
```

Как видно из листинга выше, данные мы потеряли. Так получилось, потому что мы указали неверный путь до монтирования (`/var/lib/postgresql`), нужно указать путь (`/var/lib/postgresql/data`).

Повторим создание сервера, запись данных и пересоздание сервера:

```bash
# Создаем контейнер с сервером PostgreSQL
docker run -d \
    -p 5432:5432 \
    -v /var/lib/postgresql/data:/var/lib/postgresql/data \
    -e "POSTGRES_PASSWORD=postgres" \
    --network postgresql \
    --name postgresql-server \
    postgres:15

# Подключимся к серверу через контейнер с клиентом
docker run -it \
    --rm \
    --network postgresql \
    --name postgresql-client \
    postgres:15 \
    psql -h postgresql-server -U postgres
```

Операции внутри СУБД:

```sql
-- Создадим базу данных homework
postgres=# CREATE DATABASE homework;
CREATE DATABASE

-- Подключимся к созданной базе данных
postgres=# \c homework postgres
You are now connected to database "homework" as user "postgres".

-- Создадим таблицу otus
homework=# CREATE TABLE otus (id integer PRIMARY KEY, data varchar(255));
CREATE TABLE

-- Вставим пару значений в таблицу otus
homework=# INSERT INTO otus VALUES (1, 'foo');
INSERT 0 1
homework=# INSERT INTO otus VALUES (2, 'bar');
INSERT 0 1

-- Проверим что они на месте
homework=# SELECT * FROM otus;
 id | data
----+------
  1 | foo
  2 | bar
(2 rows)
```

Теперь пересоздадим контейнер с сервером и проверим наличие данных:

```bash
# Удалим старый сервер
root@ubuntu:/home/ubuntu# docker stop postgresql-server && docker rm postgresql-server

# Подымаем новый
docker run -d \
    -p 5432:5432 \
    -v /var/lib/postgresql/data:/var/lib/postgresql/data \
    -e "POSTGRES_PASSWORD=postgres" \
    --network postgresql \
    --name postgresql-server \
    postgres:15

# Подключимся к серверу через контейнер с клиентом
docker run -it \
    --rm \
    --network postgresql \
    --name postgresql-client \
    postgres:15 \
    psql -h postgresql-server -U postgres -d homework

# Подключились
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

homework=#
```

Операции внутри СУБД:

```sql
-- Получим список таблиц
homework=# \d
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | otus | table | postgres
(1 row)

-- Посмотрим что данные на месте
homework=# SELECT * FROM otus;
 id | data
----+------
  1 | foo
  2 | bar
(2 rows)
```

**Мораль сей басни такова - проверяйте ваши маунты.**
