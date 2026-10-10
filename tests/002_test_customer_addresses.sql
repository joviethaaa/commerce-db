
-- =====================================================
-- CommerceDB
-- Test: 002_test_customer_addresses.sql
-- Purpose: Verify address relationships and constraints
-- Target: PostgreSQL 18
-- =====================================================

-- TEST 1: Verify table structure
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'customer_addresses'
ORDER BY ordinal_position;

-- TEST 2: Verify PRIMARY KEY and FOREIGN KEY
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.customer_addresses'::regclass
  AND contype IN ('p', 'f')
ORDER BY conname;

-- TEST 3: Verify One-to-Many relationship
SELECT
    c.customer_id,
    c.full_name,
    a.address_id,
    a.city,
    a.province,
    a.is_default
FROM customers AS c
INNER JOIN customer_addresses AS a
    ON c.customer_id = a.customer_id
ORDER BY a.address_id;

-- TEST 4: Verify stored addresses
SELECT
    address_id,
    customer_id,
    city,
    is_default
FROM customer_addresses
ORDER BY address_id;

-- =====================================================
-- NEGATIVE TESTS
-- Run individually in the development database.
-- Intentionally commented out.
-- =====================================================

-- TEST 5: Invalid customer reference
-- Expected SQLSTATE: 23503
--
-- INSERT INTO customer_addresses (
--     customer_id,
--     recipient_name,
--     phone_number,
--     street_address,
--     city,
--     province,
--     postal_code,
--     is_default
-- )
-- VALUES (
--     999,
--     'Budi Santoso',
--     '081298765432',
--     'Jl. Sudirman No. 50',
--     'Bandung',
--     'Jawa Barat',
--     '40115',
--     FALSE
-- );

-- TEST 6: ON DELETE RESTRICT
-- Expected SQLSTATE: 23001
--
-- DELETE FROM customers
-- WHERE customer_id = 1;
