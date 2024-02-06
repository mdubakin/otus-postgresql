Homework. Replication
=================

- [Homework. Replication](#homework-replication)
  - [Описание](#описание)
    - [Цели](#цели)
  - [Задание и выполнение](#задание-и-выполнение)
    - [Подготовка](#подготовка)
    - [Задание 1. Настройка логической репликации между 3 серверами](#задание-1-настройка-логической-репликации-между-3-серверами)
    - [Задание со \*. Добавление физичеческой потоковой репликации](#задание-со--добавление-физичеческой-потоковой-репликации)
      - [Настроим мастер](#настроим-мастер)
      - [Настроим реплику](#настроим-реплику)

Описание
--------

Репликация

### Цели

- реализовать свой миникластер на 3 ВМ

Задание и выполнение
--------------------

### Подготовка

Поднял 4 VM в Yandex Cloud и установил на них 15 PostgreSQL. Hostnames: `repl-0`, `repl-1`, `repl-2`, `repl-3`.

### Задание 1. Настройка логической репликации между 3 серверами

> Создаем таблицы на чтения и запись на 3 VM (repl-0, repl-1, repl-2).

```sql
-- Выполним команды на 3 серверах.
postgres=# CREATE TABLE test (name text PRIMARY KEY);
CREATE TABLE
postgres=# CREATE TABLE test2 (name text PRIMARY KEY);
CREATE TABLE

-- Заполним таблицу test на VM repl-0 данными
repl-0 | postgres=# INSERT INTO test VALUES ('vasiliy'), ('petr'), ('sergey');
INSERT 0 3

-- Заполним таблицу test2 на VM repl-1 данными
repl-1 | postgres=# INSERT INTO test2 VALUES ('maxim'), ('artem'), ('alexandr');
INSERT 0 3
```

> Создаем публикации для таблиц test (repl-0) и test2 (repl-1)

Настраиваем wal_level:

```sql
-- Для начала настроим wal_level на уровень logical на 3 VM
postgres=# ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM

-- Перезапустим сервис PostgreSQL на каждом из серверов
root@repl-0:/home/student# systemctl restart postgresql@15-main
root@repl-1:/home/student# systemctl restart postgresql@15-main
root@repl-2:/home/student# systemctl restart postgresql@15-main

-- Проверим значение параметра wal_level
postgres=# SHOW wal_level;
 wal_level
-----------
 logical
(1 row)
```

Создаем публикации:

```sql
repl-0 | postgres=# CREATE PUBLICATION test_pub_repl_0 FOR TABLE test;
CREATE PUBLICATION

repl-1 | postgres=# CREATE PUBLICATION test2_pub_repl_1 FOR TABLE test2;
CREATE PUBLICATION
```

> Создаем подписки
>
> 1. repl-0 -> repl-1 (test2);
> 2. repl-1 -> repl-0 (test);
> 3. repl-0 (test) <- repl-2 -> repl-1 (test2)

**Подготовка**.

1. Меняем `listen_addresses` на `*`, чтобы прослушивать все адреса

```sql
-- Меняем значение параметра
postgres=# ALTER SYSTEM SET listen_addresses = '*';
ALTER SYSTEM

-- Перезапускаем сервер
root@repl-0:/home/student# systemctl restart postgresql@15-main

-- Проверяем, что сокет 0.0.0.0:5432 прослушивается
root@repl-0:/home/student# netstat -ntulp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:5432            0.0.0.0:*               LISTEN      5630/postgres
```

2. Устанавливаем пароль пользователя `postgres` на 3 VM:

```sql
postgres=# \password
Enter new password for user "postgres":
Enter it again:
```

3. Добавляем в `pg_hba.conf` запись на разрешение подключение из интернета:

VM `repl-0`:

```ini
# Редактируем файл
postgres@repl-0:/home/student$ vi /etc/postgresql/15/main/pg_hba.conf

# Добавляем строчки
# repl-1
host    postgres        postgres        158.160.113.241/32      trust
# repl-2
host    postgres        postgres        158.160.105.206/32      trust

# Далее перечитаем конфигурацию
postgres@repl-0:/home/student$ psql -c 'SELECT pg_reload_conf();'
pg_reload_conf
----------------
 t
(1 row)
```

VM `repl-1`:

```ini
# Редактируем файл
postgres@repl-1:/home/student$ vi /etc/postgresql/15/main/pg_hba.conf

# Добавляем строчки
# repl-0
host    postgres        postgres        158.160.127.187/32      trust
# repl-2
host    postgres        postgres        158.160.105.206/32      trust

# Далее перечитаем конфигурацию
postgres@repl-1:/home/student$ psql -c 'SELECT pg_reload_conf();'
 pg_reload_conf
----------------
 t
(1 row)
```

VM `repl-2`:

```ini
# Редактируем файл
postgres@repl-2:/home/student$ vi /etc/postgresql/15/main/pg_hba.conf

# Добавляем строчки
# repl-0
host    postgres        postgres        158.160.127.187/32      trust
# repl-1
host    postgres        postgres        158.160.113.241/32      trust

# Далее перечитаем конфигурацию
postgres@repl-2:/home/student$ psql -c 'SELECT pg_reload_conf();'
 pg_reload_conf
----------------
 t
(1 row)
```

**Создаем подписки**.

1. **repl-0 -> repl-1 (test2)**:

```sql
-- Проверим что таблица test2 пустая на VM repl-0
repl-0 | postgres=# SELECT * FROM test2;
 name
------
(0 rows)

-- Создаем подписку
repl-0 | postgres=# CREATE SUBSCRIPTION test2_sub_repl_1 CONNECTION 'host=158.160.113.241 user=postgres dbname=postgres' PUBLICATION test2_pub_repl_1 WITH (copy_data = TRUE);
CREATE SUBSCRIPTION

-- Проверияем данные
repl-0 | postgres=# SELECT * FROM test2;
   name
----------
 maxim
 artem
 alexandr
(3 rows)

-- Смотрим статус репликации
repl-0 | postgres=# SELECT * FROM pg_stat_subscription\gx
-[ RECORD 1 ]---------+------------------------------
subid                 | 16413
subname               | test2_sub_repl_1
pid                   | 8062
relid                 |
received_lsn          | 0/156D690
last_msg_send_time    | 2024-02-06 08:27:45.59271+00
last_msg_receipt_time | 2024-02-06 08:27:45.593082+00
latest_end_lsn        | 0/156D690
latest_end_time       | 2024-02-06 08:27:45.59271+00
```

2. **repl-1 -> repl-0 (test)**:

```sql
-- Проверим что таблица test пустая на VM repl-1
repl-1 | postgres=# SELECT * FROM test;
 name
------
(0 rows)

-- Создаем подписку
repl-1 | postgres=# CREATE SUBSCRIPTION test_sub_repl_0 CONNECTION 'host=158.160.127.187 user=postgres dbname=postgres' PUBLICATION test_pub_repl_0 WITH (copy_data = TRUE);
CREATE SUBSCRIPTION

-- Проверяем данные
repl-1 | postgres=# SELECT * FROM test;
  name
---------
 vasiliy
 petr
 sergey
(3 rows)

-- Смотрим на статус репликации
repl-1 | postgres=# SELECT * FROM pg_stat_subscription\gx
-[ RECORD 1 ]---------+------------------------------
subid                 | 16404
subname               | test_sub_repl_0
pid                   | 9590
relid                 |
received_lsn          | 0/157F3B0
last_msg_send_time    | 2024-02-06 08:32:15.209907+00
last_msg_receipt_time | 2024-02-06 08:32:15.209981+00
latest_end_lsn        | 0/157F3B0
latest_end_time       | 2024-02-06 08:32:15.209907+00
```

3. **repl-0 (test) <- repl-2 -> repl-1 (test2)**:

```sql
-- Проверяем что обе таблицы пустые
repl-2 | postgres=# SELECT * FROM test;
 name
------
(0 rows)

repl-2 | postgres=# SELECT * FROM test2;
 name
------
(0 rows)

-- Создаем подписки на таблицы test (repl-0) и test2 (repl-1)
repl-2 | postgres=# CREATE SUBSCRIPTION test_sub_repl_01 CONNECTION 'host=158.160.127.187 user=postgres dbname=postgres' PUBLICATION test_pub_repl_0 WITH (copy_data = TRUE);
CREATE SUBSCRIPTION

repl-2 | postgres=# CREATE SUBSCRIPTION test2_sub_repl_11 CONNECTION 'host=158.160.113.241 user=postgres dbname=postgres' PUBLICATION test2_pub_repl_1 WITH (copy_data = TRUE);
CREATE SUBSCRIPTION

-- Проверяем данные в таблицах test и test2
repl-2 | postgres=# SELECT * FROM test;
  name
---------
 vasiliy
 petr
 sergey
(3 rows)

repl-2 | postgres=# SELECT * FROM test2;
   name
----------
 maxim
 artem
 alexandr
(3 rows)

-- Проверяем статус репликации
repl-2 | postgres=# SELECT * FROM pg_stat_subscription\gx
-[ RECORD 1 ]---------+------------------------------
subid                 | 16403
subname               | test_sub_repl_01
pid                   | 10071
relid                 |
received_lsn          | 0/157F420
last_msg_send_time    | 2024-02-06 08:37:18.311463+00
last_msg_receipt_time | 2024-02-06 08:37:18.311419+00
latest_end_lsn        | 0/157F420
latest_end_time       | 2024-02-06 08:37:18.311463+00
-[ RECORD 2 ]---------+------------------------------
subid                 | 16404
subname               | test2_sub_repl_11
pid                   | 10136
relid                 |
received_lsn          | 0/156E8D0
last_msg_send_time    | 2024-02-06 08:37:12.06938+00
last_msg_receipt_time | 2024-02-06 08:37:12.069466+00
latest_end_lsn        | 0/156E8D0
latest_end_time       | 2024-02-06 08:37:12.06938+00
```

### Задание со *. Добавление физичеческой потоковой репликации

#### Настроим мастер

```sql
-- Открываем файл pg_hba.conf
postgres@repl-2:/home/student$ vi /etc/postgresql/15/main/pg_hba.conf

-- Вставляем строку
# repl-1
host    replication        postgres        158.160.49.64/32      trust

-- Меняем параметры
repl-2 | postgres=# ALTER SYSTEM SET wal_level = 'hot_standby';
ALTER SYSTEM

repl-2 | postgres=# ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM

repl-2 | postgres=# ALTER SYSTEM SET archive_command = 'cd .';
ALTER SYSTEM

repl-2 | postgres=# ALTER SYSTEM SET max_wal_senders = 8;
ALTER SYSTEM

repl-2 | postgres=# ALTER SYSTEM SET listen_addresses = '*';
ALTER SYSTEM

-- Перезапускаем кластер
root@repl-2:/home/student# systemctl restart postgresql@15-main

-- Проверим что после запуска работает репликация
repl-2 | postgres=# select * from test;
  name
---------
 vasiliy
 petr
 sergey
(3 rows)

repl-0 | postgres=# INSERT INTO test VALUES ('kirill');
INSERT 0 1

repl-2 | postgres=# SELECT * FROM test;
  name
---------
 vasiliy
 petr
 sergey
 kirill
(4 rows)
```

#### Настроим реплику

```sql
-- Настроим pg_hba.conf
postgres@repl-3:/home/student$ vi /etc/postgresql/15/main/pg_hba.conf

-- Вставим строчку
# repl-2
host    replication        postgres        158.160.105.206/32      trust

-- Изменим параметры
repl-3 | postgres=# ALTER SYSTEM SET wal_level = 'hot_standby';
ALTER SYSTEM

repl-3 | postgres=# ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM

repl-3 | postgres=# ALTER SYSTEM SET archive_command = 'cd .';
ALTER SYSTEM

repl-3 | postgres=# ALTER SYSTEM SET max_wal_senders = 8;
ALTER SYSTEM

repl-3 | postgres=# ALTER SYSTEM SET listen_addresses = '*';
ALTER SYSTEM

-- Останавливаем кластер
root@repl-3:/home/student# systemctl stop postgresql@15-main

-- Удалим каталог с данными
postgres@repl-3:~/15$ rm -rf main; mkdir main; chmod go-rwx main

-- Восстановим данные с мастера
postgres@repl-3:~/15$ pg_basebackup -P -R -X stream -c fast -h 158.160.105.206 -U postgres -D ./main
23127/23127 kB (100%), 1/1 tablespace

-- Запустим postgresql
root@repl-3:/home/student# systemctl start postgresql@15-main

-- Проверим наличие данных
repl-3 | postgres=# SELECT * from test;
  name
---------
 vasiliy
 petr
 sergey
 kirill
(4 rows)

repl-3 | postgres=# SELECT * from test2;
   name
----------
 maxim
 artem
 alexandr
(3 rows)

-- Проверим статус репликации
repl-3 | postgres=# SELECT * FROM pg_stat_wal_receiver\gx
-[ RECORD 1 ]---------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pid                   | 7804
status                | streaming
receive_start_lsn     | 0/3000000
receive_start_tli     | 1
written_lsn           | 0/3000060
flushed_lsn           | 0/3000060
received_tli          | 1
last_msg_send_time    | 2024-02-06 13:01:28.878007+00
last_msg_receipt_time | 2024-02-06 13:01:28.87775+00
latest_end_lsn        | 0/3000060
latest_end_time       | 2024-02-06 12:58:58.61865+00
slot_name             |
sender_host           | 158.160.105.206
sender_port           | 5432
conninfo              | user=postgres passfile=/var/lib/postgresql/.pgpass channel_binding=prefer dbname=replication host=158.160.105.206 port=5432 fallback_application_name=15/main sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable
```

Готово, хост `repl-3` является репликой хоста `repl-2`.
