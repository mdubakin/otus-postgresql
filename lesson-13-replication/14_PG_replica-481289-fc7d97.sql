/*
 Параметр hot_standby_feedback в PostgreSQL отвечает за то, будет ли мастер-сервер отслеживать изменения,
 вносимые в реплику (standby) и использовать эту информацию для более эффективной синхронизации данных между
 мастером и репликой. Когда этот параметр включен, мастер-сервер будет отслеживать изменения, внесенные в реплику,
 и отправлять эту информацию обратно на реплику, чтобы избежать конфликтов и ускорить процесс репликации данных.
 */
pg_lsclusters -- наличие кластера Постгреса
sudo - u postgres psql SHOW wal_level;

-- alter system set wal_level = replica;
-- Создадим 2 кластер
sudo pg_createcluster - d / var / lib / postgresql / 14 / main2 14 main2
/*
 Зададим другой порт (задан по умолчанию)
 sudo echo 'port = 5433' >> /var/lib/postgresql/14/main2/postgresql.auto.conf
 Добавим параметр горячего резерва, чтобы реплика принимала запросы на чтение (задан по умолчанию ключом D)
 sudo echo 'hot_standby = on' >> /var/lib/postgresql/14/main2/postgresql.auto.conf
 */
-- Удалим оттуда файлы
sudo rm - rf / var / lib / postgresql / 14 / main2 -- Сделаем бэкап нашей БД. Ключ -R создаст заготовку управляющего файла recovery.conf.
sudo - u postgres pg_basebackup - p 5432 - R - D / var / lib / postgresql / 14 / main2 -- Стартуем кластер
sudo pg_ctlcluster 14 main2 START -- Смотрим как стартовал
pg_lsclusters sudo - u postgres psql - p 5433 -- Проверяем правильно ли у нас настроена репликация
CREATE DATABASE otus;

-- создать базу
\ c otus -- перейти в нее
CREATE TABLE students AS
SELECT
   generate_series(1, 10) AS id,
   md5(random() :: text) :: char(10) AS fio;

-- создаем таблицу
SHOW synchronous_commit;

/*
 В PostgreSQL параметр synchronous_commit управляет тем, как база данных подтверждает фиксацию транзакций.
 Когда synchronous_commit установлен в значение "on", база данных гарантирует, что коммит транзакции будет
 синхронно записан на диск перед тем, как сообщить клиенту об успешном завершении транзакции.
 
 Однако параметр sync_state в PostgreSQL отвечает за текущее состояние синхронизации, которое может быть "async"
 или "sync". Даже если synchronous_commit установлен в "on", sync_state может быть "async", что означает, что база данных
 временно разрешает асинхронную запись на диск для повышения производительности. Когда sync_state устанавливается в "sync",
 это означает, что все операции записи должны быть синхронизированы с диском.
 
 Таким образом, значение параметра sync_state не зависит напрямую от значения synchronous_commit, и асинхронная запись
 на диск может быть разрешена даже при включенной синхронной фиксации транзакций.
 */
/*
 В PostgreSQL параметр sync_state управляется с помощью функции pg_stat_replication. Этот параметр позволяет
 контролировать состояние синхронизации репликации, а именно, можно установить состояние синхронизации в "async" или "sync".
 
 Чтобы управлять параметром sync_state, необходимо выполнить следующие действия:
 
 1. Подключитесь к базе данных PostgreSQL с правами администратора или пользователя, имеющего привилегии на изменение параметров репликации.
 
 2. Выполните запрос к системной представлению pg_stat_replication для управления параметром sync_state.
 Например, чтобы установить состояние синхронизации в "async" для конкретной реплики, можно выполнить следующий запрос:
 
 SELECT pg_stat_replication.sync_state FROM pg_stat_replication WHERE application_name = 'имя_реплики';
 
 Затем можно изменить состояние синхронизации с помощью команды ALTER SYSTEM:
 ALTER SYSTEM SET synchronous_standby_names TO '';
 
 Или с помощью команды ALTER ROLE:
 ALTER ROLE имя_реплики SET synchronous_commit TO off;
 
 
 3. После внесения изменений в параметр sync_state, необходимо перезапустить сервер PostgreSQL или выполнить
 команду SELECT pg_reload_conf();, чтобы применить изменения.
 
 Управление параметром sync_state в PostgreSQL требует аккуратности, поскольку неправильная настройка может
 привести к потере целостности данных. Поэтому перед внесением изменений рекомендуется тщательно изучить документацию PostgreSQL
 и проконсультироваться с опытным специалистом.
 */
--Проверим состояние репликации:
-- на мастере
SELECT
   *
FROM
   pg_stat_replication \ gx
SELECT
   *
FROM
   pg_current_wal_lsn();

-- на реплике
SELECT
   *
FROM
   pg_stat_wal_receiver \ gx
SELECT
   pg_last_wal_receive_lsn();

SELECT
   pg_last_wal_replay_lsn();

sudo pg_ctlcluster 14 main2 STOP
INSERT INTO
   students
VALUES
   (11, 'otus');

sudo pg_ctlcluster 14 main2 START -- будет ли тут реплика?
SELECT
   *
FROM
   pg_stat_replication \ gx -- Перевод в состояние мастера
   sudo pg_ctlcluster 14 main2 promote
   /*
    Эта команда используется для повышения статуса реплики PostgreSQL до основной (мастер) в кластере.
    В данном случае, команда sudo pg_ctlcluster 14 main2 promote будет повышать реплику с именем "main2" в
    кластере версии 14 до основной роли, что позволит ей принимать записи и обрабатывать запросы от клиентов.
    */
SELECT
   *
FROM
   pg_stat_replication \ gx -- Логическая репликация
   sudo pg_dropcluster 14 main2 --stop
   ALTER system
SET
   wal_level = logical;

-- у первого сервера
-- Создадим 2 кластер
sudo pg_createcluster - d / var / lib / postgresql / 14 / main2 14 main2 sudo pg_ctlcluster 14 main2 START -- Рестартуем кластер
sudo pg_ctlcluster 14 main2 restart sudo - u postgres psql - p 5432 - d otus -- На первом сервере создаем публикацию:
CREATE publication test_pub FOR TABLE students;

-- Просмотр созданной публикации
\ dRp + -- Задать пароль (чтобы подключиться к мастеру указав нужный пароль)
\ PASSWORD -- otus123
sudo - u postgres psql - p 5433 CREATE TABLE IF NOT EXISTS students (id int, fio char(10));

sudo pg_ctlcluster 14 main START sudo - u postgres psql - p 5433
SELECT
   version();

--Cоздадим подписку на втором экземпляре (создадим подписку к БД по Порту с Юзером и Паролем и Копированием данных = false)
CREATE subscription test_sub connection 'host=localhost port=5432 user=postgres password=otus123 dbname=otus' publication test_pub WITH (copy_data = TRUE);

\ dRs
SELECT
   *
FROM
   pg_stat_subscription \ gx -- Конфликт:
   -- добавим одинаковые данные
   -- добавить индекс на подписчике
   CREATE UNIQUE INDEX ON students(id);

INSERT INTO
   students
VALUES
   (12, 'otus_1');

\ dS + students -- добавить одиноковые значения
-- удалить на втором экземпляре конфликтные записи
SELECT
   *
FROM
   pg_stat_subscription \ gx -- просмотр состояния (при конфликте пусто)
   -- Просмотр логов
   sudo - u postgres tail / var / log / postgresql / postgresql -14 - main2.log -- Удаление логической репликации
   DROP publication test_pub;

DROP subscription test_sub;

-- Удаление кластера
sudo pg_dropcluster 14 main2 --stop