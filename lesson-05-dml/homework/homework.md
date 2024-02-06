# SQL. DML

- [SQL. DML](#sql-dml)
  - [Topics](#topics)
  - [Tasks](#tasks)

## Topics

- `SELECT`ing
- Joins (`ON`, `USING`, `NATURAL`), several joins in one select
- `WHERE` statement
- `is NULL` vs `= NULL`
- `exists()`
- `LIKE` (`~~`), `ILIKE` (`~~*`), `NOT LIKE` (`!~~`), `NOT ILIKE` (`!~~*`)
- `SIMILAR TO` (`~`)
- `INSERT INTO ...`
- `INSERT INTO` / `UPDATE` / `DELETE ... RETURNING`
- (copying tables)
  1. `CREATE TABLE foo AS SELECT ...`;
  2. `SELECT * INTO foo FROM bar`;
- `INSERT INTO foo VALUES (...) SELECT ...`;
- `INSERT INTO ... ON CONFICT DO NOTHING ...`;
- `UPDATE foo SET bar = (SELECT ...)`;
- `UPDATE foo SET a = f.a, b = f.b FROM (SELECT ...)`;
- (CTE) `WITH`;

## Tasks

1. Restore [sakila](https://github.com/jOOQ/sakila) sample database into your PostgreSQL cluster.
2. Find all info about film with id = 842
3. Find out title, language and category of the film with id = 227
4. Find ids of films containing FOO in the title
5. Find ids of films starting with D and ending with R
6.
