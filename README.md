# PostgreSQL Performance and PgBouncer Lab

## Objective

This hands-on lab demonstrates how to diagnose and optimize a slow PostgreSQL query, observe transaction isolation behavior, and configure PgBouncer for connection pooling.

## Step 1: Generate a Large Dataset

Created an `orders` table and populated it with **2,000,000 rows** using PostgreSQL's `generate_series()` function.

The table contains:

- Order ID
- Customer ID
- Amount
- Status
- Creation date

The table was analyzed using `ANALYZE orders;`.

## Step 2: Diagnose the Slow Query

Used:

```sql
EXPLAIN (ANALYZE, BUFFERS)
