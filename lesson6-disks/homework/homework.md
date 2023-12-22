Homework. Installing PostgreSQL (here we go again)
=================

- [Homework. Installing PostgreSQL (here we go again)](#homework-installing-postgresql-here-we-go-again)
  - [Описание](#описание)
    - [Цель](#цель)
  - [Задание и выполнение](#задание-и-выполнение)

Описание
--------

Установка и настройка `PostgreSQL`

### Цель

- создавать дополнительный диск для уже существующей виртуальной машины, размечать его и делать на нем файловую систему
- переносить содержимое базы данных `PostgreSQL` на дополнительный диск
- переносить содержимое БД `PostgreSQL` между виртуальными машинами

Задание и выполнение
--------------------

> создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере

> поставьте на нее `PostgreSQL` 15 через `sudo apt`

Поднял VM в Yandex Cloud с помощью [terraform](../../terraform/) и установил PostgreSQL 15 с помощью [cloud-init](../../terraform/modules/tf-yc-instance/configs/users.yaml).

> проверьте что кластер запущен через `sudo -u postgres pg_lsclusters`

```bash
student@fhmkmqdhho3hm5m81l5g:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

> зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым

```sql
student@fhmkmqdhho3hm5m81l5g:~$ sudo -u postgres psql
could not change directory to "/home/student": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

-- Создаем таблицу test и вставляем данные
postgres=# create table test(c1 text);
postgres=# insert into test values('1');
```

> остановите postgres например через `sudo -u postgres pg_ctlcluster 15 main stop`

```bash
# Получаем предупреждение об ошибке
student@fhmkmqdhho3hm5m81l5g:~$ sudo -u postgres pg_ctlcluster 15 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@15-main

# Поэтому останавливаем через systemd
sudo systemctl stop postgresql@15-main

# Убедимся что PostgreSQL остановлен
student@fhmkmqdhho3hm5m81l5g:~$ sudo systemctl status postgresql@15-main
○ postgresql@15-main.service - PostgreSQL Cluster 15-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
     Active: inactive (dead) since Fri 2023-12-22 12:40:38 UTC; 1s ago
...
```

> создайте новый диск к ВМ размером 10GB

> добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk

Подключил второй диск на 10GB через [terraform](../../terraform/modules/tf-yc-disk/).

> проинициализируйте диск согласно инструкции и подмонтировать файловую систему

В инструкции предлагают воспользоваться `parted` для разметки диска, но я привык использовать `fdisk`:

```bash
# Создаем раздел
student@fhmkmqdhho3hm5m81l5g:~$ sudo fdisk /dev/vdb

Command (m for help): n

Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p

Partition number (1-4, default 1): 1

First sector (2048-20971519, default 2048): 2048

Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-20971519, default 20971519): 20971519

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

# Создаем файловую систему
student@fhmkmqdhho3hm5m81l5g:~$ sudo mkfs.ext4 /dev/vdb1

# Создаем директорию для монтирования
student@fhmkmqdhho3hm5m81l5g:~$ sudo mkdir /mnt/postgresql_data

# Монтируем файловую систему в директорию
student@fhmkmqdhho3hm5m81l5g:~$ sudo mount /dev/vdb1 /mnt/postgresql_data

# Проверим что мы успешно смонтировали директорию
student@fhmkmqdhho3hm5m81l5g:~$ lsblk --fs
NAME   FSTYPE   FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0  squashfs 4.0                                                    0   100% /snap/lxd/24322
loop1  squashfs 4.0                                                    0   100% /snap/core20/1822
loop2  squashfs 4.0                                                    0   100% /snap/snapd/18357
loop3                                                                  0   100% /snap/snapd/20290
vda
├─vda1
└─vda2 ext4     1.0         ed465c6e-049a-41c6-8e0b-c8da348a3577   14.3G    23% /
vdb
└─vdb1 ext4     1.0         ad96796f-cc3d-4849-869f-3c0b06124d96    9.2G     0% /mnt/postgresql_data

# Добавим запись о монтировании в /etc/fstab
student@fhmkmqdhho3hm5m81l5g:~$ sudo vi /etc/fstab
/dev/vdb1       /mnt/postgresql_data    ext4    defaults        0       2
```

> перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)

```bash
# Перезапускаем VM
student@fhmkmqdhho3hm5m81l5g:~$ sudo reboot

# Uptime (0 min)
student@fhmkmqdhho3hm5m81l5g:~$ uptime
 14:28:02 up 0 min,  1 user,  load average: 1.43, 0.35, 0.12

# Проверяем что диск примонтирован
student@fhmkmqdhho3hm5m81l5g:~$ lsblk --fs
NAME   FSTYPE   FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0  squashfs 4.0                                                    0   100% /snap/lxd/24322
loop1  squashfs 4.0                                                    0   100% /snap/snapd/18357
loop2  squashfs 4.0                                                    0   100% /snap/core20/1822
loop3  squashfs 4.0                                                    0   100% /snap/snapd/20290
vda
├─vda1
└─vda2 ext4     1.0         ed465c6e-049a-41c6-8e0b-c8da348a3577   14.3G    23% /
vdb
└─vdb1 ext4     1.0         ad96796f-cc3d-4849-869f-3c0b06124d96    9.2G     0% /mnt/postgresql_data
```

> сделайте пользователя postgres владельцем `/mnt/postgresql_data` - `chown -R postgres:postgres /mnt/postgresql_data`

```bash
student@fhmkmqdhho3hm5m81l5g:~$ sudo chown -R postgres:postgres /mnt/postgresql_data
```

> перенесите содержимое `/var/lib/postgres/15` в `/mnt/postgresql_data` - `mv /var/lib/postgresql/15 /mnt/postgresql_data`

```bash
# Остановим PostgreSQL, так как после перезагрузки он запустился
student@fhmkmqdhho3hm5m81l5g:~$ sudo systemctl stop postgresql@15-main

student@fhmkmqdhho3hm5m81l5g:~$ systemctl status postgresql@15-main
○ postgresql@15-main.service - PostgreSQL Cluster 15-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
     Active: inactive (dead) since Fri 2023-12-22 14:32:24 UTC; 2s ago
...

# Перенесем PGDATA
student@fhmkmqdhho3hm5m81l5g:~$ sudo mv /var/lib/postgresql/15 /mnt/postgresql_data

# Проверим что данные на месте
student@fhmkmqdhho3hm5m81l5g:~$ sudo ls /mnt/postgresql_data/15/main/
base pg_commit_ts  pg_logical    pg_notify  pg_serial     pg_stat     pg_subtrans  pg_twophase  pg_wal   postgresql.auto.conf
global pg_dynshmem   pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc  PG_VERSION   pg_xact  postmaster.opts
```

> попытайтесь запустить кластер - `sudo -u postgres pg_ctlcluster 15 main start`

> напишите получилось или нет и почему

```bash
student@fhmkmqdhho3hm5m81l5g:~$ sudo -u postgres pg_ctlcluster 15 main start
Error: /var/lib/postgresql/15/main is not accessible or does not exist
```

Мы получили ошибку, так как параметр конфигурации `data_directory` указывает на старую папку, которая пуста:

```ini
student@fhmkmqdhho3hm5m81l5g:~$ sudo grep --color data_directory /etc/postgresql/15/main/postgresql.conf
data_directory = '/var/lib/postgresql/15/main'  # use data in another directory
```

> задание: найти конфигурационный параметр в файлах раположенных в `/etc/postgresql/15/main` который надо поменять и поменяйте его

> напишите что и почему поменяли

Поменял параметр `data_directory` в файле `/etc/postgresql/15/main/postgresql.conf`

```ini
data_directory = '/mnt/postgresql_data/15/main'
```

> попытайтесь запустить кластер - `sudo -u postgres pg_ctlcluster 15 main start`

> напишите получилось или нет и почему

```bash
# Запустим через systemctl
student@fhmkmqdhho3hm5m81l5g:~$ sudo systemctl start postgresql@15-main

# Посмотрим статус
student@fhmkmqdhho3hm5m81l5g:~$ sudo systemctl status postgresql@15-main
● postgresql@15-main.service - PostgreSQL Cluster 15-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
     Active: active (running) since Fri 2023-12-22 14:40:33 UTC; 7s ago
...
```

> зайдите через через `psql` и проверьте содержимое ранее созданной таблицы

```sql
-- Посмотрим список таблиц
postgres=# \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | test | table | postgres
(1 row)

-- Получим содержимое таблицы test
postgres=# SELECT * FROM test;
 c1
----
 1
(1 row)
```

**Все ок, данные доступны.**

Задание со * не делал.
