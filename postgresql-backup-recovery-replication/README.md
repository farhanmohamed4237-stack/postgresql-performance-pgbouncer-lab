# PostgreSQL Hands-On Lab: Backups, PITR and Replication

## Objective

This lab demonstrates practical PostgreSQL database administration, including logical backups, physical backups, Write-Ahead Log (WAL) archiving, point-in-time recovery (PITR), and streaming replication.

All exercises were performed using PostgreSQL 17 on Windows.

## Lab Environment

- Operating system: Windows
- Database management system: PostgreSQL 17
- Primary PostgreSQL server: Port 5432
- Standby PostgreSQL server: Port 5433
- PITR recovery server: Port 5434
- Test database: `bootcamp`
- Main test table: `orders`
- Number of records: 2,000,000

## 1. Logical Backup and Restore

### Objective

Create a logical backup of the `bootcamp` database and verify that it can be restored successfully.

### Backup Command

```cmd
pg_dump -h localhost -p 5432 -U postgres -Fc -f "%USERPROFILE%\backups\bootcamp.dump" bootcamp
```

The database was backed up using PostgreSQL's custom backup format.

### Backup Verification

```cmd
pg_restore --list "%USERPROFILE%\backups\bootcamp.dump"
```

The backup contents included the `orders` table, table data, sequence and index.

### Restore Verification

A separate database named `bootcamp_check` was created, and the logical backup was restored using `pg_restore`.

The restored records were checked using:

```sql
SELECT COUNT(*) FROM orders;
```

**Result: 2,000,000 records.**

**Status: Successfully completed and verified.**

## 2. WAL Archiving and Physical Backup

### Objective

Configure continuous WAL archiving and create a physical base backup to support database recovery.

### PostgreSQL Configuration

The primary PostgreSQL server was configured with the following settings in `postgresql.conf`:

```conf
wal_level = replica
archive_mode = on
archive_command = 'cmd /c copy "%p" "C:\\Users\\user\\backups\\wal\\%f"'
```

PostgreSQL was restarted to activate the configuration.

### WAL Archiving Verification

The configuration and archiving status were checked using:

```sql
SHOW archive_mode;
SHOW archive_command;
SELECT pg_switch_wal();
SELECT archived_count, last_archived_wal, failed_count
FROM pg_stat_archiver;
```

The archiving checks confirmed:

- `archive_mode` was enabled.
- WAL files were successfully archived.
- The archiver reported 8 archived WAL files and 0 failures at the time of verification.

### Physical Base Backup

A compressed physical base backup was created using:

```cmd
pg_basebackup -h localhost -p 5432 -U postgres -D "%USERPROFILE%\backups\base" -Ft -z -Xs -P
```

The resulting backup directory contained:

- `base.tar.gz`
- `pg_wal.tar.gz`
- `backup_manifest`

**Status: Successfully completed and verified.**

## 3. Point-in-Time Recovery (PITR)

### Objective

Recover a database to a specific point in time before a test record was deleted.

### Recovery Test

A test table named `pitr_test` was created in the `bootcamp` database. A test record was inserted:

```text
1 | Data before disaster
```

A new physical base backup was taken after inserting the record. The recovery target timestamp was recorded:

```text
2026-09-26 11:09:03.530296+03
```

The test record was then deleted from the primary database to simulate accidental data loss.

### Recovery Procedure

The recovery base backup and WAL files were extracted into a separate PostgreSQL data directory.

The recovery server was configured with:

```conf
port = 5434
listen_addresses = 'localhost'
restore_command = 'cmd /c copy "C:\\Users\\user\\backups\\wal\\%f" "%p"'
recovery_target_time = '2026-09-26 11:09:03.530296+03'
recovery_target_action = 'pause'
```

A `recovery.signal` file was created to enable recovery, and the recovery instance was started separately on port 5434.

### PITR Verification

The following query was executed on the recovery instance:

```sql
SELECT pg_is_wal_replay_paused(), * FROM pitr_test;
```

**Result:**

```text
pg_is_wal_replay_paused | id | description
------------------------+----+----------------------
t                       | 1  | Data before disaster
```

The deleted record was successfully recovered at the selected recovery point.

**Status: Successfully completed and verified.**

## 4. Streaming Replication

### Objective

Configure a separate PostgreSQL standby server that continuously receives WAL changes from the primary server.

### Replication User

A dedicated replication account was created on the primary server:

```sql
CREATE ROLE replicator WITH REPLICATION LOGIN;
```

A password was assigned securely. The account's `Replication` role attribute was confirmed using:

```text
\du replicator
```

### Standby Creation

A physical base backup was taken using the dedicated replication account:

```cmd
pg_basebackup -h 127.0.0.1 -p 5432 -U replicator -D "%USERPROFILE%\backups\standby" -Fp -Xs -P -R
```

The backup completed successfully at 100%.

The `-R` option prepared the backup directory for standby operation by generating the standby signal and primary connection configuration.

Replication credentials were stored locally in PostgreSQL's password file. No credentials are included in this repository.

### Starting the Standby

The standby instance was started separately on port 5433:

```cmd
pg_ctl -D "%USERPROFILE%\backups\standby" -l "%USERPROFILE%\backups\standby.log" -o "-p 5433" start
```

### Replication Verification

The following query was executed on the primary PostgreSQL server:

```sql
SELECT application_name, state
FROM pg_stat_replication;
```

**Actual result:**

```text
application_name | state
-----------------+----------
walreceiver      | streaming
(1 row)
```

This confirms that the primary server had an active streaming replication connection to the standby.

**Status: Successfully completed and verified.**

## 5. Summary of Results

| Exercise | Verification | Status |
|---|---|---|
| Logical backup and restore | Restored 2,000,000 records | Completed |
| WAL archiving | Archiving enabled; archived WAL files confirmed | Completed |
| Physical base backup | Backup files and manifest verified | Completed |
| Point-in-time recovery | Deleted test record recovered | Completed |
| Streaming replication | `pg_stat_replication` showed `streaming` | Completed |

## Conclusion

The lab demonstrated logical database backup and restoration, continuous WAL archiving, physical backups, point-in-time recovery and streaming replication using PostgreSQL 17.

The exercises verified the ability to restore database records, recover data from a selected point in time and establish an active streaming replication connection between primary and standby PostgreSQL servers.

**Security note:** Database passwords, PostgreSQL password files, private configuration details and database backup files are not included in this repository.
