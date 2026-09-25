-- Hands-On Lab: Diagnosing Slow Queries and Adding a Connection Pool
-- PostgreSQL Performance Lab

-- =====================================================
-- STEP 1: Generate a Big Table
-- =====================================================

CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT,
    amount NUMERIC(10,2),
    status TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO orders (customer_id, amount, status, created_at)
SELECT
    (random()*50000)::int,
    (random()*500)::numeric(10,2),
    (ARRAY['pending','shipped','delivered'])[ceil(random()*3)],
    now() - (random()*365)::int * interval '1 day'
FROM generate_series(1, 2000000);

ANALYZE orders;


-- =====================================================
-- STEP 2: Measure the Slow Query
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, SUM(amount)
FROM orders
WHERE status = 'pending'
  AND created_at > now() - interval '30 days'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;


-- =====================================================
-- STEP 3: Add a Targeted Index and Re-Measure
-- =====================================================

CREATE INDEX idx_pending_recent
ON orders (created_at DESC, customer_id)
WHERE status = 'pending';

-- Re-run the same query after creating the index

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, SUM(amount)
FROM orders
WHERE status = 'pending'
  AND created_at > now() - interval '30 days'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;


-- =====================================================
-- STEP 4: Observe Isolation Levels
-- =====================================================

-- SESSION 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT amount
FROM orders
WHERE id = 1;

-- SESSION 2 (run in a separate psql session)
UPDATE orders
SET amount = 9999
WHERE id = 1;

COMMIT;

-- SESSION 1 AGAIN
SELECT amount
FROM orders
WHERE id = 1;

COMMIT;


-- =====================================================
-- STEP 5: PgBouncer
-- =====================================================

-- PgBouncer was configured with:
--
-- [databases]
-- bootcamp = host=127.0.0.1 port=5432 dbname=bootcamp
--
-- [pgbouncer]
-- pool_mode = transaction
-- max_client_conn = 1000
-- default_pool_size = 20
-- listen_port = 6432
--
-- PgBouncer service was restarted and the connection
-- to the bootcamp database was successfully tested
-- through port 6432.
