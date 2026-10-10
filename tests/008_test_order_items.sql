
-- =====================================================
-- CommerceDB
-- Test: 008_test_order_items.sql
-- Purpose: Verify order_items structure and constraints
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
  AND table_name = 'order_items'
ORDER BY ordinal_position;

-- Expected: 6 columns


-- TEST 2: Verify constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.order_items'::regclass
  AND contype IN ('p', 'u', 'f', 'c')
ORDER BY conname;

-- Expected: 6 named constraints


-- TEST 3: Verify order item relationships
SELECT
    oi.order_item_id,
    o.order_number,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS subtotal
FROM order_items AS oi
INNER JOIN orders AS o
    ON oi.order_id = o.order_id
INNER JOIN products AS p
    ON oi.product_id = p.product_id
ORDER BY oi.order_item_id;


-- TEST 4: Verify order summary
SELECT
    o.order_id,
    o.order_number,
    COUNT(oi.order_item_id) AS total_product_types,
    SUM(oi.quantity) AS total_units,
    SUM(oi.quantity * oi.unit_price) AS items_subtotal,
    o.shipping_fee,
    SUM(oi.quantity * oi.unit_price)
        + o.shipping_fee AS order_total
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_id = 1
GROUP BY
    o.order_id,
    o.order_number,
    o.shipping_fee;


-- =====================================================
-- NEGATIVE TESTS
-- Run individually and only in a test database.
-- Intentionally commented out.
-- Assumes sample order_items 1 and 2 exist.
-- =====================================================

-- TEST 5: Duplicate order-product combination
-- Expected: SQLSTATE 23505
-- Constraint: uq_order_items_order_product
--
-- INSERT INTO order_items (
--     order_id, product_id, quantity, unit_price
-- )
-- VALUES (1, 1, 1, 8500000.00);


-- TEST 6: Invalid product reference
-- Expected: SQLSTATE 23503
-- Constraint: fk_order_items_product
--
-- INSERT INTO order_items (
--     order_id, product_id, quantity, unit_price
-- )
-- VALUES (1, 999, 1, 100000.00);


-- TEST 7: Invalid quantity
-- Expected: SQLSTATE 23514
-- Constraint: ck_order_items_quantity
--
-- UPDATE order_items
-- SET quantity = 0
-- WHERE order_item_id = 1;


-- TEST 8: Negative historical unit price
-- Expected: SQLSTATE 23514
-- Constraint: ck_order_items_unit_price
--
-- UPDATE order_items
-- SET unit_price = -100000.00
-- WHERE order_item_id = 2;


-- TEST 9: NULL quantity
-- Expected: SQLSTATE 23502
--
-- UPDATE order_items
-- SET quantity = NULL
-- WHERE order_item_id = 1;
