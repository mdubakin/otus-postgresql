Homework. Settings
=================

- [Homework. Settings](#homework-settings)
  - [Описание](#описание)
    - [Цели](#цели)
  - [Задание и выполнение](#задание-и-выполнение)
    - [1. Инфраструктура](#1-инфраструктура)
    - [2. Настройка PostgreSQL на производительность](#2-настройка-postgresql-на-производительность)
    - [3. Нагрузочное тестирование с помощью pgbench](#3-нагрузочное-тестирование-с-помощью-pgbench)
    - [4. Задание со \*. Нагрузочное тестирование с помощью sysbench-tpcc](#4-задание-со--нагрузочное-тестирование-с-помощью-sysbench-tpcc)

Описание
--------

Нагрузочное тестирование и тюнинг PostgreSQL

### Цели

- сделать нагрузочное тестирование PostgreSQL
- настроить параметры PostgreSQL для достижения максимальной производительности

Задание и выполнение
--------------------

### 1. Инфраструктура

> Развернуть виртуальную машину любым удобным способом.

> Поставить на неё PostgreSQL 15 любым способом

VM с PostgreSQL развернута и настроена с предыдущих дз.

### 2. Настройка PostgreSQL на производительность

> Настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины

Давайте зафиксируем значение `tps` до настройки, для этого проведем нагрузочное тестирование с помощью pgbench:

```bash
postgres@fhmodlacmieaul194lf0:~$ pgbench -c 50 -j 2 -P 10 -T 60 -U postgres postgres
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 324.0 tps, lat 152.114 ms stddev 141.553, 0 failed
progress: 20.0 s, 423.3 tps, lat 118.323 ms stddev 96.253, 0 failed
progress: 30.0 s, 471.3 tps, lat 104.900 ms stddev 83.361, 0 failed
progress: 40.0 s, 408.8 tps, lat 123.376 ms stddev 112.715, 0 failed
progress: 50.0 s, 506.6 tps, lat 99.007 ms stddev 77.930, 0 failed
progress: 60.0 s, 541.8 tps, lat 92.128 ms stddev 70.125, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 26808
number of failed transactions: 0 (0.000%)
latency average = 111.996 ms
latency stddev = 97.781 ms
initial connection time = 65.450 ms
tps = 445.534067 (without initial connection time)
```

Теперь создадим файл `/etc/postgresql/15/main/conf.d/tune.conf` с содержимым (получил с помощью <https://pgconfigurator.cybertec.at/>):

```ini
# Connectivity
max_connections = 120
superuser_reserved_connections = 3

# Memory Settings
shared_buffers = '1024 MB'
work_mem = '32 MB'
maintenance_work_mem = '320 MB'
huge_pages = off
effective_cache_size = '3 GB'
effective_io_concurrency = 100 # concurrent IO only really activated if OS supports posix_fadvise function
random_page_cost = 1.25 # speed of random disk access relative to sequential access (1.0)

# Monitoring
shared_preload_libraries = 'pg_stat_statements' # per statement resource usage stats
track_io_timing=on # measure exact block IO times
track_functions=pl # track execution times of pl-language procedures if any

# Replication
wal_level = replica # consider using at least 'replica'
max_wal_senders = 10
synchronous_commit = on

# Checkpointing:
checkpoint_timeout = '15 min'
checkpoint_completion_target = 0.9
max_wal_size = '1024 MB'
min_wal_size = '512 MB'

# WAL archiving
archive_mode = on # having it on enables activating P.I.T.R. at a later time without restart›
archive_command = '/bin/true' # not doing anything yet with WAL-s


# WAL writing
wal_compression = on
wal_buffers = -1 # auto-tuned by Postgres till maximum of segment size (16MB by default)
wal_writer_delay = 200ms
wal_writer_flush_after = 1MB


# Background writer
bgwriter_delay = 200ms
bgwriter_lru_maxpages = 100
bgwriter_lru_multiplier = 2.0
bgwriter_flush_after = 0

# Parallel queries:
max_worker_processes = 2
max_parallel_workers_per_gather = 1
max_parallel_maintenance_workers = 1
max_parallel_workers = 2
parallel_leader_participation = on

# Advanced features
enable_partitionwise_join = on
enable_partitionwise_aggregate = on
jit = on
max_slot_wal_keep_size = '1000 MB'
track_wal_io_timing = on
maintenance_io_concurrency = 100
wal_recycle = on
```

Эти настройки с синхронными транзакциями.

Перезапустим кластер PostgreSQL:

```bash
root@fhmodlacmieaul194lf0:/home/student# systemctl restart postgresql@15-main
```

### 3. Нагрузочное тестирование с помощью pgbench

> Нагрузить кластер через утилиту через утилиту pgbench.

Снова нагружаем систему:

```bash
postgres@fhmodlacmieaul194lf0:/home/student$ pgbench -c 50 -j 2 -P 10 -T 60 -U postgres postgres
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 566.9 tps, lat 86.868 ms stddev 65.351, 0 failed
progress: 20.0 s, 498.3 tps, lat 100.420 ms stddev 78.272, 0 failed
progress: 30.0 s, 420.9 tps, lat 118.989 ms stddev 117.798, 0 failed
progress: 40.0 s, 597.9 tps, lat 83.532 ms stddev 62.929, 0 failed
progress: 50.0 s, 535.6 tps, lat 93.545 ms stddev 69.622, 0 failed
progress: 60.0 s, 415.4 tps, lat 119.987 ms stddev 131.000, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 30400
number of failed transactions: 0 (0.000%)
latency average = 98.687 ms
latency stddev = 88.930 ms
initial connection time = 65.011 ms
tps = 506.092547 (without initial connection time)
```

Это были настройки с включенными синхронными транзакциями (wal durability), но уже сейчас получили 50 tps в скорости.

Но мы можем выжать гораздо больше, если выключим синхронный режим, заменив параметры:

```ini
diff tune_sync.conf tune_async.conf
< synchronous_commit = on
< wal_writer_flush_after = 1MB
< wal_writer_delay = 200ms
---
> synchronous_commit = off
```

Заменим их и проведем еще одно нагрузочное тестирование:

```bash
postgres@fhmodlacmieaul194lf0:/home/student$ pgbench -c 50 -j 2 -P 10 -T 60 -U postgres postgres
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 2193.9 tps, lat 22.601 ms stddev 16.558, 0 failed
progress: 20.0 s, 2079.2 tps, lat 24.039 ms stddev 15.239, 0 failed
progress: 30.0 s, 1970.6 tps, lat 25.369 ms stddev 15.741, 0 failed
progress: 40.0 s, 2049.4 tps, lat 24.400 ms stddev 16.484, 0 failed
progress: 50.0 s, 2093.1 tps, lat 23.900 ms stddev 15.484, 0 failed
progress: 60.0 s, 2059.2 tps, lat 24.277 ms stddev 15.492, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 124504
number of failed transactions: 0 (0.000%)
latency average = 24.089 ms
latency stddev = 15.901 ms
initial connection time = 66.335 ms
tps = 2073.771631 (without initial connection time)
```

Таким образом мы добились x4 скорости, но эти настройки опасны, так как приводят к потенциальной потере данных последних N транзакций.

> Написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему.

Стандартный конфиг: `445 tps`
Улучшенный конфиг с синхронным режимом: `506 tps`
Улучшенный конфиг с асинхронным режимом: `2073 tps`

Настроек много, поэтому опишу самые важные:

> shared_buffers = '1024 MB'

Размер общей разделяемой памяти для всех процессов PostgreSQL. Рекомендованное значение 1/4 от всей RAM. Чем больше памяти, тем больше страниц с данными будут закешированы, а это прямым образом влияет на производительность чтения.

> work_mem = '32 MB'

Объём памяти, который будет использоваться для внутренних операций сортировки и хеш-таблиц. Рекомендаций нет, нужно смотреть от числа коннектов, но чем выше это значение, тем быстрее будут проходить операции сортировки хэширования.

> synchronous_commit = off

Это самый важный, с точки зрения повышения tps, параметр. Он определяет, будет ли сервер при фиксировании транзакции ждать, пока записи из WAL сохранятся на диске, прежде чем сообщить клиенту об успешном завершении операции. При его отключении, нам не приходится ждать дисковых операций, которые в разы дольше чем операции в RAM. Именно благодаря отключению этого параметра я добился 2к tps, однако это очень опасный параметр, который не рекомендуется отключать на проде.

### 4. Задание со *. Нагрузочное тестирование с помощью sysbench-tpcc

> аналогично протестировать через утилиту <https://github.com/Percona-Lab/sysbench-tpcc> (требует установки <https://github.com/akopytov/sysbench>)

Установим `sysbench`:

```bash
root@fhmodlacmieaul194lf0:/home/student# curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash

root@fhmodlacmieaul194lf0:/home/student# sudo apt -y install sysbench
```

Скачаем и перенесем скрипты `sysbench-tpcc`:

```bash
❯ git clone git@github.com:Percona-Lab/sysbench-tpcc.git

❯ scp -r sysbench-tpcc student@158.160.113.33:~/
```

Подготовим таблицы и данные:

```bash
postgres@fhmodlacmieaul194lf0:~/15/main/sysbench-tpcc$ ./tpcc.lua --pgsql-host=127.0.0.1 --pgsql-user=postgres --pgsql-password=postgres --pgsql-db=postgres --threads=2 --report-interval=10 --time=60 --tables=2 --scale=2 --db-driver=pgsql prepare
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Initializing worker threads...

DB SCHEMA public
Creating tables: 1

DB SCHEMA public
Creating tables: 2

Adding indexes 1 ... 

Adding indexes 2 ... 

Adding FK 1 ... 

Waiting on tables 30 sec

Adding FK 2 ... 

Waiting on tables 30 sec

loading tables: 1 for warehouse: 1

loading tables: 1 for warehouse: 2

loading tables: 2 for warehouse: 2

loading tables: 2 for warehouse: 1
```

Проведем нагрузочное тестирование:

```bash
postgres@fhmodlacmieaul194lf0:~/15/main/sysbench-tpcc$ ./tpcc.lua --pgsql-host=127.0.0.1 --pgsql-user=postgres --pgsql-password=postgres --pgsql-db=postgres --threads=2 --report-interval=10 --time=60 --tables=2 --scale=2 --db-driver=pgsql run
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Running the test with following options:
Number of threads: 2
Report intermediate results every 10 second(s)
Initializing random number generator from current time


Initializing worker threads...

DB SCHEMA public
DB SCHEMA public
Threads started!

[ 10s ] thds: 2 tps: 323.94 qps: 9157.53 (r/w/o: 4176.69/4313.76/667.07) lat (ms,95%): 15.83 err/s 10.70 reconn/s: 0.00
[ 20s ] thds: 2 tps: 328.70 qps: 9639.49 (r/w/o: 4393.34/4568.54/677.61) lat (ms,95%): 15.00 err/s 11.20 reconn/s: 0.00
[ 30s ] thds: 2 tps: 284.20 qps: 8118.79 (r/w/o: 3701.40/3829.00/588.40) lat (ms,95%): 18.61 err/s 11.10 reconn/s: 0.00
[ 40s ] thds: 2 tps: 301.80 qps: 8701.79 (r/w/o: 3959.75/4117.25/624.79) lat (ms,95%): 17.01 err/s 11.20 reconn/s: 0.00
[ 50s ] thds: 2 tps: 365.00 qps: 10375.96 (r/w/o: 4720.23/4902.73/753.00) lat (ms,95%): 14.21 err/s 12.60 reconn/s: 0.00
[ 60s ] thds: 2 tps: 339.00 qps: 9509.89 (r/w/o: 4327.10/4484.00/698.80) lat (ms,95%): 15.27 err/s 11.80 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            252797
        write:                           262168
        other:                           40100
        total:                           555065
    transactions:                        19429  (323.72 per sec.)
    queries:                             555065 (9248.38 per sec.)
    ignored errors:                      686    (11.43 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0156s
    total number of events:              19429

Latency (ms):
         min:                                    0.60
         avg:                                    6.18
         max:                                  147.00
         95th percentile:                       16.12
         sum:                               119974.74

Threads fairness:
    events (avg/stddev):           9714.5000/9.50
    execution time (avg/stddev):   59.9874/0.01
```
