
-- =====================================================
-- CommerceDB
-- Test: 007_test_orders.sql
-- Purpose: Verify orders structure and constraints
-- Target: PostgreSQL 18
-- =====================================================

-- TEST 1: Verify table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- Expected: 13 columns


-- TEST 2: Verify constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.orders'::regclass
  AND contype IN ('p', 'u', 'f', 'c')
ORDER BY conname;

-- Expected:
-- pk_orders
-- uq_orders_number
-- fk_orders_customer
-- ck_orders_shipping_fee


-- TEST 3: Verify Orders-Customers relationship
SELECT
    o.order_id,
    o.order_number,
    c.full_name AS customer_name,
    o.order_status,
    o.shipping_city,
    o.shipping_fee,
    o.created_at
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id;


-- =====================================================
-- NEGATIVE TESTS
-- Execute individually.
-- Intentionally commented out.
-- =====================================================

-- TEST 4: Duplicate order number
-- Expected SQLSTATE: 23505
-- Constraint: uq_orders_number
--
-- Requires the sample order to exist.
--
-- INSERT INTO orders (
--     customer_id, order_number, order_status,
--     recipient_name, shipping_phone, shipping_street,
--     shipping_city, shipping_province,
--     shipping_postal_code, shipping_fee
-- )
-- VALUES (
--     1, 'ORD-20261010-001', 'PENDING',
--     'Andi Pratama', '081234567890',
--     'Jl. Merdeka No. 10', 'Bandung',
--     'Jawa Barat', '40111', 15000.00
-- );


-- TEST 5: Invalid customer reference
-- Expected SQLSTATE: 23503
-- Constraint: fk_orders_customer
--
-- Requires customer_id 999 to be absent.
--
-- INSERT INTO orders (
--     customer_id, order_number, order_status,
--     recipient_name, shipping_phone, shipping_street,
--     shipping_city, shipping_province,
--     shipping_postal_code, shipping_fee
-- )
-- VALUES (
--     999, 'ORD-20261010-002', 'PENDING',
--     'Budi Santoso', '081298765432',
--     'Jl. Sudirman No. 50', 'Bandung',
--     'Jawa Barat', '40115', 20000.00
-- );


-- TEST 6: Negative shipping fee
-- Expected SQLSTATE: 23514
-- Constraint: ck_orders_shipping_fee
--
-- UPDATE orders
-- SET shipping_fee = -15000.00
-- WHERE order_id = 1;


-- TEST 7: NULL recipient name
-- Expected SQLSTATE: 23502
--
-- UPDATE orders
-- SET recipient_name = NULL
-- WHERE order_id = 1;
