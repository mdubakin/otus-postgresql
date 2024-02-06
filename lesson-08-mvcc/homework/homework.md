Homework. MVCC and Vacuum
=================

- [Homework. MVCC and Vacuum](#homework-mvcc-and-vacuum)
  - [Описание](#описание)
    - [Цели](#цели)
  - [Задание и выполнение](#задание-и-выполнение)
  - [Задание со \*](#задание-со-)

Описание
--------

Настройка `autovacuum` с учетом особеностей производительности.

### Цели

- запустить нагрузочный тест `pgbench`
- настроить параметры `autovacuum`
- проверить работу `autovacuum`

Задание и выполнение
--------------------

> Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB

> Установить на него `PostgreSQL 15` с дефолтными настройками

Такая VM осталась с предыдущих ДЗ.

> Создать БД для тестов: выполнить `pgbench -i postgres`

Запускаем тесты:

```bash
postgres@fhmodlacmieaul194lf0:~$ pgbench -i postgres

pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.78 s (drop tables 0.01 s, create tables 0.23 s, client-side generate 0.16 s, vacuum 0.09 s, primary keys 0.28 s).
```

> Запустить `pgbench -c8 -P 6 -T 60 -U postgres postgres`

```bash
postgres@fhmodlacmieaul194lf0:~$ pgbench -c8 -P 6 -T 60 -U postgres postgres

pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 274.0 tps, lat 28.944 ms stddev 37.338, 0 failed
progress: 12.0 s, 319.5 tps, lat 25.169 ms stddev 22.718, 0 failed
progress: 18.0 s, 468.2 tps, lat 17.055 ms stddev 12.545, 0 failed
progress: 24.0 s, 528.3 tps, lat 15.159 ms stddev 11.758, 0 failed
progress: 30.0 s, 588.3 tps, lat 13.602 ms stddev 7.886, 0 failed
progress: 36.0 s, 462.3 tps, lat 17.230 ms stddev 19.142, 0 failed
progress: 42.0 s, 385.7 tps, lat 20.836 ms stddev 15.557, 0 failed
progress: 48.0 s, 536.8 tps, lat 14.885 ms stddev 8.359, 0 failed
progress: 54.0 s, 484.2 tps, lat 16.529 ms stddev 14.460, 0 failed
progress: 60.0 s, 564.8 tps, lat 14.163 ms stddev 8.397, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 27681
number of failed transactions: 0 (0.000%)
latency average = 17.337 ms
latency stddev = 16.479 ms
initial connection time = 15.330 ms
tps = 461.349070 (without initial connection time)
```

> Применить параметры настройки `PostgreSQL` из прикрепленного к материалам занятия файла

```bash
#!/bin/bash

postgresqlconf=$(psql -qAt -c 'show config_file;')

declare -A settings=(
    ["max_connections"]=40
    ["shared_buffers"]=1GB
    ["effective_cache_size"]=3GB
    ["maintenance_work_mem"]=512MB
    ["checkpoint_completion_target"]=0.9
    ["wal_buffers"]=16MB
    ["default_statistics_target"]=500
    ["random_page_cost"]=4
    ["effective_io_concurrency"]=2
    ["work_mem"]=6553kB
    ["min_wal_size"]=4GB
    ["max_wal_size"]=16GB
)

for key in "${!settings[@]}"; do
    sed -i -r "s/^#?${key}.*/${key} = ${settings[${key}]}/" $postgresqlconf
done
```

> Протестировать заново

```bash
postgres@fhmodlacmieaul194lf0:~$ pgbench -c8 -P 6 -T 60 -U postgres postgres

pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 556.7 tps, lat 14.302 ms stddev 9.095, 0 failed
progress: 12.0 s, 410.7 tps, lat 19.501 ms stddev 19.922, 0 failed
progress: 18.0 s, 531.8 tps, lat 15.040 ms stddev 10.907, 0 failed
progress: 24.0 s, 516.3 tps, lat 15.466 ms stddev 10.536, 0 failed
progress: 30.0 s, 641.5 tps, lat 12.485 ms stddev 8.199, 0 failed
progress: 36.0 s, 623.3 tps, lat 12.834 ms stddev 7.945, 0 failed
progress: 42.0 s, 426.2 tps, lat 18.777 ms stddev 17.318, 0 failed
progress: 48.0 s, 537.8 tps, lat 14.848 ms stddev 10.346, 0 failed
progress: 54.0 s, 563.0 tps, lat 13.807 ms stddev 9.665, 0 failed
progress: 60.0 s, 600.0 tps, lat 13.727 ms stddev 13.107, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 32452
number of failed transactions: 0 (0.000%)
latency average = 14.789 ms
latency stddev = 11.983 ms
initial connection time = 16.230 ms
tps = 540.837750 (without initial connection time)
```

> Что изменилось и почему?

Увеличился показатель `tps` после применения настроек. Думаю это связано с увеличением значений `shared_buffers` и `work_mem`.

> Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк

```sql
-- Создаем таблицу
postgres=# CREATE TABLE random_strings(s text);

-- Включаем расширение pgcrypto
postgres=# CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Заполняем таблицу 1.000.000 рандомных строк
postgres=# INSERT INTO random_strings (s)
SELECT md5(gen_random_uuid()::text)
FROM generate_series(1, 1000000);
INSERT 0 1000000
```

> Посмотреть размер файла с таблицей

```sql
-- Находим oid таблицы
postgres=# SELECT oid FROM pg_class WHERE relname = 'random_strings';
  oid
-------
 16465
(1 row)

-- Находим в каком файле в системе хранится таблица
postgres=# SELECT pg_relation_filepath('16465');
 pg_relation_filepath
----------------------
 base/5/16465
(1 row)
```

```bash
# Смотрим сколько весит файл
postgres@fhmodlacmieaul194lf0:~$ ls -lah /var/lib/postgresql/15/main/base/5/16465
-rw------- 1 postgres postgres 66M Jan 14 14:46 /var/lib/postgresql/15/main/base/5/16465
```

Файл весит 66 мегабайт.

> 5 раз обновить все строчки и добавить к каждой строчке любой символ

```sql
-- Обновляем все строки 5 раз
postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

-- Добавляем рандомный символ к каждой строчке
postgres=# UPDATE random_strings
SET s = s || substr(md5(random()::text), 1, 1);
UPDATE 1000000
```

> Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум

> Подождать некоторое время, проверяя, пришел ли автовакуум

```sql
-- Смотрим мертвые строки
SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum 
FROM pg_stat_user_TABLEs 
WHERE relname = 'random_strings';

    relname     | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
----------------+------------+------------+--------+-------------------------------
 random_strings |    1000000 |          0 |      0 | 2024-01-14 14:50:55.399716+00
(1 row)
```

В моем случае автовакуум отработал сразу же, поэтому мертвых строк нет.

> 5 раз обновить все строчки и добавить к каждой строчке любой символ

```sql
-- Обновляем строки
postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

postgres=# UPDATE random_strings
SET s = md5(random()::text);
UPDATE 1000000

-- Добавляем символ
postgres=# UPDATE random_strings
SET s = s || substr(md5(random()::text), 1, 1);
UPDATE 1000000

-- Смотрим количество мертвых строк
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum 
FROM pg_stat_user_TABLEs 
WHERE relname = 'random_strings';

    relname     | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
----------------+------------+------------+--------+-------------------------------
 random_strings |    1000000 |    5999094 |    599 | 2024-01-14 14:50:55.399716+00
(1 row)
```

В этот раз автовакуум не отработал и у нас есть 6млн мертвых строк.

> Посмотреть размер файла с таблицей

```bash
postgres@fhmodlacmieaul194lf0:~$ ls -lah /var/lib/postgresql/15/main/base/5/16465
-rw------- 1 postgres postgres 456M Jan 14 14:57 /var/lib/postgresql/15/main/base/5/16465
```

Файл весит 456 мегабайт.

> Отключить Автовакуум на конкретной таблице

```sql
-- Отключаем автовакуум для таблицы random_strings
ALTER TABLE random_strings SET (autovacuum_enabled = false);
```

> 10 раз обновить все строчки и добавить к каждой строчке любой символ

В этот раз воспользуемся циклом:

```sql
-- Обновляем все строчки
postgres=# DO $$
BEGIN
  FOR i IN 1..10 LOOP
    UPDATE random_strings
    SET s = md5(random()::text);
  END LOOP;
END $$;

DO

-- Добавим рандомный символ к строкам


-- Посмотрим количество мертвых строк
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum
FROM pg_stat_user_TABLEs
WHERE relname = 'random_strings';

    relname     | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
----------------+------------+------------+--------+-------------------------------
 random_strings |    1000000 |   10999189 |   1099 | 2024-01-14 14:57:56.559456+00
(1 row)
```

Итого у нас 11млн мертвых строк.

> Посмотреть размер файла с таблицей

```bash
postgres@fhmodlacmieaul194lf0:~$ ls -lah /var/lib/postgresql/15/main/base/5/16465
-rw------- 1 postgres postgres 782M Jan 14 15:05 /var/lib/postgresql/15/main/base/5/16465
```

Файл весит 782 мегабайта.

> Объясните полученный результат

Файл будет занимать 782 мегабайта даже после активации автовакуума. Вакуум удалит мертвые строки, но занимаемое место не изменится, так как postgresql заполняет данные постранично по 8кб. Чтобы исправить это, нам нужно выполнить команду `VACUUM FULL`:

```sql
-- Выполняем VACUUM FULL
postgres=# VACUUM FULL;
VACUUM

-- Смотрим новый путь до файла таблицы random_strings с oid 16465
postgres=# SELECT pg_relation_filepath('16465');
 pg_relation_filepath
----------------------
 base/5/16503
(1 row)
```

Смотрим занимаемое место нового файла:

```bash
postgres@fhmodlacmieaul194lf0:~$ ls -lah /var/lib/postgresql/15/main/base/5/16503
-rw------- 1 postgres postgres 66M Jan 14 15:10 /var/lib/postgresql/15/main/base/5/16503
```

Теперь файл занимает 66 мегабайт, как было раньше.

> Не забудьте включить автовакуум

```sql
-- Включаем автовакуум для таблицы random_strings
postgres=# ALTER TABLE random_strings SET (autovacuum_enabled = true);

ALTER TABLE
```

## Задание со *
>
> Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице. Не забыть вывести номер шага цикла.

На основе цикла выше добавим вывод номера итерации:

```sql
postgres=# DO $$
DECLARE
  iteration_number INTEGER;
BEGIN
  FOR iteration_number IN 1..10 LOOP
    -- Вывод номера итерации
    RAISE NOTICE 'Iteration number: %', iteration_number;

    -- Ваша команда UPDATE
    UPDATE random_strings
    SET s = md5(random()::text);
  END LOOP;
END $$;

NOTICE:  Iteration number: 1
NOTICE:  Iteration number: 2
NOTICE:  Iteration number: 3
NOTICE:  Iteration number: 4
NOTICE:  Iteration number: 5
NOTICE:  Iteration number: 6
NOTICE:  Iteration number: 7
NOTICE:  Iteration number: 8
NOTICE:  Iteration number: 9
NOTICE:  Iteration number: 10
DO
```
