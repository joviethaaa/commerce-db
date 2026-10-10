
-- =====================================================
-- CommerceDB
-- Test: 006_test_inventory_alignment.sql
-- Purpose: Verify inventory schema alignment
-- Target: PostgreSQL 18
-- =====================================================

-- TEST 1: Verify inventory columns
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'inventory'
ORDER BY ordinal_position;

-- Expected:
-- inventory_id
-- product_id
-- quantity_on_hand
-- updated_at
-- quantity_reserved


-- TEST 2: Verify inventory constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.inventory'::regclass
  AND contype = 'c'
ORDER BY conname;

-- Expected:
-- ck_inventory_quantity_on_hand
-- ck_inventory_reserved_balance


-- TEST 3: Verify available stock
SELECT
    p.product_name,
    i.quantity_on_hand,
    i.quantity_reserved,
    (
        i.quantity_on_hand - i.quantity_reserved
    ) AS quantity_available
FROM products AS p
INNER JOIN inventory AS i
    ON p.product_id = i.product_id
ORDER BY p.product_id;


-- =====================================================
-- NEGATIVE TESTS
-- Run individually.
-- Intentionally commented out.
-- =====================================================

-- TEST 4: Reserved quantity exceeds physical stock
-- Expected SQLSTATE: 23514
--
-- UPDATE inventory
-- SET quantity_reserved = 20
-- WHERE product_id = 1;


-- TEST 5: Negative reserved quantity
-- Expected SQLSTATE: 23514
--
-- UPDATE inventory
-- SET quantity_reserved = -5
-- WHERE product_id = 2;


-- =====================================================
-- POSITIVE TRANSACTION TEST
-- Execute statements individually.
-- Always ROLLBACK after verification.
-- =====================================================

-- BEGIN;

-- UPDATE inventory
-- SET
--     quantity_reserved = quantity_reserved + 3,
--     updated_at = CURRENT_TIMESTAMP
-- WHERE product_id = 1
--   AND quantity_on_hand - quantity_reserved >= 3
-- RETURNING
--     product_id,
--     quantity_on_hand,
--     quantity_reserved,
--     quantity_on_hand - quantity_reserved
--         AS quantity_available;

-- ROLLBACK;
