# PostgreSQL Hands-On Lab: Backups, PITR and Replication

## Objective
Create and verify a logical backup, configure WAL archiving, perform point-in-time recovery (PITR), and set up streaming replication.

Environment: Windows, PostgreSQL 17.
Database: bootcamp.

## 1. Logical Backup and Verification — Completed

Created a custom-format logical backup using pg_dump:

```cmd
"C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -h localhost -p 5432 -U postgres -Fc -f "%USERPROFILE%\backups\bootcamp.dump" bootcamp
```

Verified the backup contents:

```cmd
"C:\Program Files\PostgreSQL\17\bin\pg_restore.exe" --list "%USERPROFILE%\backups\bootcamp.dump"
```

The backup listing included the orders table, table data, sequence, primary key and index.

Created a separate database and restored the backup:

```cmd
"C:\Program Files\PostgreSQL\17\bin\createdb.exe" -h localhost -p 5432 -U postgres bootcamp_check

"C:\Program Files\PostgreSQL\17\bin\pg_restore.exe" -h localhost -p 5432 -U postgres -d bootcamp_check "%USERPROFILE%\backups\bootcamp.dump"
```

Verified the restored data:

```cmd
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -p 5432 -U postgres -d bootcamp_check -c "SELECT COUNT(*) FROM orders;"
```

Result: 2,000,000 rows.

## 2. WAL Archiving — Configuration Prepared, Not Verified

Prepared the following PostgreSQL configuration settings:

```ini
wal_level = replica
archive_mode = on
archive_command = 'cmd /c copy "%p" "C:\\Users\\user\\backups\\wal\\%f"'
```

Created a WAL archive directory and worked on permissions for the PostgreSQL service account.

The settings were not confirmed as active, WAL archiving was not tested, and a base backup was not completed.

## 3. Point-in-Time Recovery — Not Completed

The simulated disaster and point-in-time recovery test remain outstanding.

## 4. Streaming Replication — Not Completed

The replication role, standby database and replication monitoring remain outstanding.

## Conclusion

The logical backup, backup inspection, database restoration and row-count verification were completed successfully. WAL archiving configuration was prepared, but PITR and streaming replication still require implementation and testing.

This report documents completed work and clearly distinguishes it from unverified or outstanding tasks.
