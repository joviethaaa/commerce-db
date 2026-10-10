
-- =====================================================
-- CommerceDB
-- Test: 001_test_customers.sql
-- Purpose: Verify customers table constraints
-- Target: PostgreSQL 18
-- =====================================================

-- TEST 1: Verify table structure
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'customers'
ORDER BY ordinal_position;

-- TEST 2: Verify stored customer data
SELECT
    customer_id,
    full_name,
    email
FROM customers
ORDER BY customer_id;

-- TEST 3: Verify PRIMARY KEY and UNIQUE constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint
WHERE conrelid = 'public.customers'::regclass
ORDER BY conname;

-- Expected:
-- pk_customers -> p (PRIMARY KEY)
-- uq_customers_email -> u (UNIQUE)

-- NEGATIVE TESTS (run individually)
-- The statements below are intentionally commented out.
-- Uncomment only the test you want to execute.

-- TEST 4: Duplicate email (Expected SQLSTATE 23505)
-- INSERT INTO customers (full_name, email)
-- VALUES ('Budi Santoso', 'andi@example.com');

-- TEST 5: NULL full_name (Expected SQLSTATE 23502)
-- INSERT INTO customers (full_name, email)
-- VALUES (NULL, 'citra@example.com');

-- TEST 6: Duplicate customer_id (Expected SQLSTATE 23505)
-- INSERT INTO customers (customer_id, full_name, email)
-- OVERRIDING SYSTEM VALUE
-- VALUES (1, 'Dina Putri', 'dina@example.com');
