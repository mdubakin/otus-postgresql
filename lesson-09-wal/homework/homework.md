Homework. Write Ahead Log
=================

- [Homework. Write Ahead Log](#homework-write-ahead-log)
  - [Описание](#описание)
    - [Цели](#цели)
  - [Задание и выполнение](#задание-и-выполнение)
  - [Последнее задание](#последнее-задание)

Описание
--------

Работа с журналами.

### Цели

- уметь работать с журналами и контрольными точками
- уметь настраивать параметры журналов

Задание и выполнение
--------------------

> Настройте выполнение контрольной точки раз в 30 секунд.

```sql
-- Посмотрим, что мы должны сделать для приминения настройки checkpoint_timeout
postgres=# select name, setting, context from pg_settings where name = 'checkpoint_timeout';
        
        name        | setting | context
--------------------+---------+---------
 checkpoint_timeout | 300     | sighup
(1 row)
```

`context = sighup`, значит нам достаточно сделать `reload`.

```bash
# Меняем настройку
postgres@fhmodlacmieaul194lf0:~$ sed -i -r "s/^#?checkpoint_timeout.*/checkpoint_timeout = 30/" /etc/postgresql/15/main/postgresql.conf

# Проверяем что мы поменяли настройку в файле
postgres@fhmodlacmieaul194lf0:~$ grep checkpoint_timeout /etc/postgresql/15/main/postgresql.conf
checkpoint_timeout = 30

# Перечитываем конфигурацию
postgres@fhmodlacmieaul194lf0:~$ pg_ctlcluster 15 main reload

# Проверяем что значение обновилось
postgres@fhmodlacmieaul194lf0:~$ psql -c 'show checkpoint_timeout;'
 checkpoint_timeout
--------------------
 30s
(1 row)
```

> 10 минут c помощью утилиты pgbench подавайте нагрузку.

Для начала очистим статистику представления `pg_stat_bgwriter`:

```sql
-- До очистки
postgres=# SELECT * FROM pg_stat_bgwriter \gx
-[ RECORD 1 ]---------+------------------------------
checkpoints_timed     | 375
checkpoints_req       | 3
checkpoint_write_time | 1927250
checkpoint_sync_time  | 762
buffers_checkpoint    | 166257
buffers_clean         | 0
maxwritten_clean      | 0
buffers_backend       | 190677
buffers_backend_fsync | 0
buffers_alloc         | 204635
stats_reset           | 2024-01-14 14:25:25.659309+00

-- Очищаем
postgres=# SELECT pg_stat_reset_shared('bgwriter');
-[ RECORD 1 ]--------+-
pg_stat_reset_shared |

-- После очистки
postgres=# 30
-[ RECORD 1 ]---------+------------------------------
checkpoints_timed     | 0
checkpoints_req       | 0
checkpoint_write_time | 0
checkpoint_sync_time  | 0
buffers_checkpoint    | 0
buffers_clean         | 0
maxwritten_clean      | 0
buffers_backend       | 0
buffers_backend_fsync | 0
buffers_alloc         | 1
stats_reset           | 2024-01-17 06:30:19.511974+00
```

Запускаем нагрузочное тестирование:

```bash
postgres@fhmodlacmieaul194lf0:~$ pgbench -c 8 -P 100 -T 600 -U postgres postgres

pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 100.0 s, 495.3 tps, lat 16.147 ms stddev 12.367, 0 failed
progress: 200.0 s, 490.4 tps, lat 16.302 ms stddev 12.582, 0 failed
progress: 300.0 s, 439.1 tps, lat 18.227 ms stddev 15.112, 0 failed
progress: 400.0 s, 499.6 tps, lat 16.013 ms stddev 12.556, 0 failed
progress: 500.0 s, 531.5 tps, lat 15.052 ms stddev 11.777, 0 failed
progress: 600.0 s, 505.2 tps, lat 15.835 ms stddev 12.946, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 296122
number of failed transactions: 0 (0.000%)
latency average = 16.209 ms
latency stddev = 12.908 ms
initial connection time = 15.422 ms
tps = 493.537971 (without initial connection time)
```

> Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку.

```bash
# Посмотрим количество новых WAL файлов
postgres@fhmodlacmieaul194lf0:~/15/main$ ls -lah pg_wal/
...
-rw-------  1 postgres postgres  16M Jan 17 06:30 000000010000000200000050
-rw-------  1 postgres postgres  16M Jan 17 06:30 000000010000000200000051
-rw-------  1 postgres postgres  16M Jan 17 06:31 000000010000000200000052
-rw-------  1 postgres postgres  16M Jan 17 06:31 000000010000000200000053
-rw-------  1 postgres postgres  16M Jan 17 06:32 000000010000000200000054
-rw-------  1 postgres postgres  16M Jan 17 06:32 000000010000000200000055
-rw-------  1 postgres postgres  16M Jan 17 06:32 000000010000000200000056
-rw-------  1 postgres postgres  16M Jan 17 06:33 000000010000000200000057
-rw-------  1 postgres postgres  16M Jan 17 06:33 000000010000000200000058
-rw-------  1 postgres postgres  16M Jan 17 06:34 000000010000000200000059
-rw-------  1 postgres postgres  16M Jan 17 06:34 00000001000000020000005A
-rw-------  1 postgres postgres  16M Jan 17 06:34 00000001000000020000005B
-rw-------  1 postgres postgres  16M Jan 17 06:35 00000001000000020000005C
-rw-------  1 postgres postgres  16M Jan 17 06:35 00000001000000020000005D
-rw-------  1 postgres postgres  16M Jan 17 06:36 00000001000000020000005E
-rw-------  1 postgres postgres  16M Jan 17 06:36 00000001000000020000005F
-rw-------  1 postgres postgres  16M Jan 17 06:36 000000010000000200000060
-rw-------  1 postgres postgres  16M Jan 17 06:37 000000010000000200000061
-rw-------  1 postgres postgres  16M Jan 17 06:37 000000010000000200000062
-rw-------  1 postgres postgres  16M Jan 17 06:38 000000010000000200000063
-rw-------  1 postgres postgres  16M Jan 17 06:38 000000010000000200000064
-rw-------  1 postgres postgres  16M Jan 17 06:38 000000010000000200000065
-rw-------  1 postgres postgres  16M Jan 17 06:39 000000010000000200000066
-rw-------  1 postgres postgres  16M Jan 17 06:39 000000010000000200000067
-rw-------  1 postgres postgres  16M Jan 17 06:40 000000010000000200000068
-rw-------  1 postgres postgres  16M Jan 17 06:40 000000010000000200000069
```

Объем WAL, за время нагрузки утилитой `pgbench`, увеличился на 26 файлов по 16 Мб = **416 Мб**. Если нагрузка длилась 10 минут, а контрольные точки происходят каждые 30 секунд, тогда средний объем одной контрольной точки равен: 416 / 20 = **20.8 Мб**.

> Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?

```sql
postgres=# SELECT * FROM pg_stat_bgwriter \gx
-[ RECORD 1 ]---------+------------------------------
checkpoints_timed     | 30
checkpoints_req       | 0
checkpoint_write_time | 564302
checkpoint_sync_time  | 498
buffers_checkpoint    | 40483
buffers_clean         | 0
maxwritten_clean      | 0
buffers_backend       | 1953
buffers_backend_fsync | 0
buffers_alloc         | 1947
stats_reset           | 2024-01-17 06:30:19.511974+00
```

Все контрольные точки были выполнены по расписанию: `checkpoints_timed = 30`, а `checkpoints_req = 0`.

> Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.

Если я правильно понял задание, то речь идет о синхронном и асинхронном режиме транзакций. Это настраивается с помощью параметра `synchronous_commit` (при `on` - синхронный режим, при `off` - асинхронный).

Настроим асинхронный режим и запустим нагрузочные тесты:

```bash
# Меняем настройку synchronous_commit на off
postgres@fhmodlacmieaul194lf0:~/15/main$ sed -i -r "s/^#?synchronous_commit.*/synchronous_commit = off/" /etc/postgresql/15/main/postgresql.conf

# Проверяем файл
postgres@fhmodlacmieaul194lf0:~/15/main$ grep synchronous_commit /etc/postgresql/15/main/postgresql.conf
synchronous_commit = off

# Перечитываем конфигурацию
postgres@fhmodlacmieaul194lf0:~/15/main$ pg_ctlcluster 15 main reload

# Проверяем что параметр применился
postgres@fhmodlacmieaul194lf0:~/15/main$ psql -c 'show synchronous_commit;'
 synchronous_commit
--------------------
 off
(1 row)

# Запускаем pgbench в асинхронном режиме на 1 минуту
postgres@fhmodlacmieaul194lf0:~/15/main$ pgbench -c 8 -P 10 -T 60 -U postgres postgres
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 3291.7 tps, lat 2.426 ms stddev 0.687, 0 failed
progress: 20.0 s, 3231.8 tps, lat 2.475 ms stddev 0.723, 0 failed
progress: 30.0 s, 3359.6 tps, lat 2.380 ms stddev 0.779, 0 failed
progress: 40.0 s, 3350.7 tps, lat 2.387 ms stddev 0.668, 0 failed
progress: 50.0 s, 3404.0 tps, lat 2.349 ms stddev 0.675, 0 failed
progress: 60.0 s, 3450.2 tps, lat 2.318 ms stddev 0.655, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 200888
number of failed transactions: 0 (0.000%)
latency average = 2.388 ms
latency stddev = 0.702 ms
initial connection time = 15.570 ms
tps = 3348.243825 (without initial connection time)
```

Вернем синхронный режим и проведем тесты:

```bash
# Возвращаем настройку synchronous_commit на on
postgres@fhmodlacmieaul194lf0:~/15/main$ sed -i -r "s/^#?synchronous_commit.*/synchronous_commit = on/" /etc/postgresql/15/main/postgresql.conf

# Проверяем файл
postgres@fhmodlacmieaul194lf0:~/15/main$ grep synchronous_commit /etc/postgresql/15/main/postgresql.conf
synchronous_commit = on

# Перечитываем конфигурацию
postgres@fhmodlacmieaul194lf0:~/15/main$ pg_ctlcluster 15 main reload

# Проверяем что параметр применился
postgres@fhmodlacmieaul194lf0:~/15/main$ psql -c 'show synchronous_commit;'
 synchronous_commit
--------------------
 on
(1 row)

# Запускаем pgbench в синхронном режиме на 1 минуту
postgres@fhmodlacmieaul194lf0:~/15/main$ pgbench -c 8 -P 10 -T 60 -U postgres postgres
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 448.1 tps, lat 17.802 ms stddev 15.541, 0 failed
progress: 20.0 s, 572.2 tps, lat 13.988 ms stddev 8.338, 0 failed
progress: 30.0 s, 495.6 tps, lat 16.105 ms stddev 11.856, 0 failed
progress: 40.0 s, 434.3 tps, lat 18.461 ms stddev 16.134, 0 failed
progress: 50.0 s, 503.9 tps, lat 15.847 ms stddev 11.394, 0 failed
progress: 60.0 s, 497.7 tps, lat 15.984 ms stddev 11.949, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 29526
number of failed transactions: 0 (0.000%)
latency average = 16.258 ms
latency stddev = 12.779 ms
initial connection time = 14.633 ms
tps = 491.817025 (without initial connection time)
```

Разница в tps между синхронным (**491 tps**) и асинхронным (**3348 tps**) режимами почти в **7 раз**. Так вышло, потому что в асинхронном режиме нам не нужно дожидаться записи WAL на диск, однако в таком случае существует окно (максимальный размер окна равен тройному значению `wal_writer_delay`) когда клиент узнаёт об успешном завершении, до момента, когда транзакция действительно гарантированно защищена от сбоя.

Последнее задание
-------

Это задание я разбил на несколько частей для удобства.

> Создайте новый кластер с включенной контрольной суммой страниц.

```bash
# Создаем кластер с включенной контрольной суммой страниц
postgres@fhmodlacmieaul194lf0:~/15$ /usr/lib/postgresql/15/bin/initdb -k -D /var/lib/postgresql/15/extra
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are enabled.

fixing permissions on existing directory /var/lib/postgresql/15/extra ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/extra -l logfile start

# Меняем порт на 5433
postgres@fhmodlacmieaul194lf0:~/15$ sed -i -r "s/^#?port.*/port = 5433/" /var/lib/postgresql/15/extra/postgresql.conf

# Проверим что порт поменялся
postgres@fhmodlacmieaul194lf0:~/15$ grep port extra/postgresql.conf
port = 5433

# Запустим кластер
postgres@fhmodlacmieaul194lf0:~/15$ /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/extra -l logfile start
waiting for server to start.... done
server started
```

> Создайте таблицу.

```sql
postgres@fhmodlacmieaul194lf0:~/15$ psql -p 5433
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE TABLE t1 (id integer);
CREATE TABLE
```

> Вставьте несколько значений.

```sql
-- Вставляем значения
postgres=# INSERT INTO t1 VALUES (1),(2),(3);
INSERT 0 3

-- Получаем oid таблицы
postgres=# SELECT oid FROM pg_class WHERE relname = 't1';
  oid
-------
 16387
(1 row)

-- Находим файл таблицы
postgres=# SELECT pg_relation_filepath('16387');
 pg_relation_filepath
----------------------
 base/5/16387
(1 row)
```

> Выключите кластер.

```bash
postgres@fhmodlacmieaul194lf0:~/15$ /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/extra stop
waiting for server to shut down.... done
server stopped
```

> Измените пару байт в таблице.

```bash
postgres@fhmodlacmieaul194lf0:~/15$ echo foobar >> /var/lib/postgresql/15/extra/base/5/16387
```

> Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?

```bash
# Включаем проверку хэшсуммы
postgres@fhmodlacmieaul194lf0:~$ /usr/lib/postgresql/15/bin/pg_checksums -e -D /var/lib/postgresql/15/extra
pg_checksums: error: could not read block 1 in file "/var/lib/postgresql/15/extra/base/5/16387": read 21 of 8192

# Запускаем кластер
postgres@fhmodlacmieaul194lf0:~/15$ /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/extra start
waiting for server to start....2024-01-19 05:35:48.394 UTC [12619] LOG:  starting PostgreSQL 15.5 (Ubuntu 15.5-1.pgdg22.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit
2024-01-19 05:35:48.394 UTC [12619] LOG:  listening on IPv6 address "::1", port 5433
2024-01-19 05:35:48.394 UTC [12619] LOG:  listening on IPv4 address "127.0.0.1", port 5433
2024-01-19 05:35:48.399 UTC [12619] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5433"
2024-01-19 05:35:48.415 UTC [12622] LOG:  database system was shut down at 2024-01-19 05:35:02 UTC
2024-01-19 05:35:48.426 UTC [12619] LOG:  database system is ready to accept connections
 done
server started

# Делаем выборку из таблицы
postgres=# SELECT * FROM t1;
 id
----
  1
  2
  3
(3 rows)

postgres=# show data_checksums;
 data_checksums
----------------
 on
(1 row)
```

Никакой ошибки не было.
