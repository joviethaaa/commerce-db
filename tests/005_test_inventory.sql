
-- =====================================================
-- CommerceDB
-- Test: 005_test_inventory.sql
-- Purpose: Verify inventory structure and constraints
-- Target: PostgreSQL 18
-- =====================================================

-- TEST 1: Table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'inventory'
ORDER BY ordinal_position;

-- Expected: 4 columns


-- TEST 2: Verify constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.inventory'::regclass
  AND contype IN ('p', 'u', 'f', 'c')
ORDER BY conname;

-- Expected: pk_inventory, uq_inventory_product,
-- fk_inventory_product, ck_inventory_quantity


-- TEST 3: Inventory and products JOIN
SELECT
    p.product_id,
    p.product_name,
    i.inventory_id,
    i.quantity,
    i.updated_at
FROM products AS p
INNER JOIN inventory AS i
    ON p.product_id = i.product_id
ORDER BY p.product_id;

-- Expected development data:
-- ASUS Vivobook 14: 15
-- Samsung Galaxy A55: 30
-- Casual Sneakers: 50


-- TEST 4: Verify inventory count
SELECT COUNT(*) AS total_inventory
FROM inventory;

-- Expected: 3 for initial development dataset


-- =====================================================
-- NEGATIVE TESTS
-- Execute individually in development environment.
-- Intentionally commented out.
-- =====================================================

-- TEST 5: Negative quantity
-- Expected SQLSTATE: 23514
-- Constraint: ck_inventory_quantity
--
-- UPDATE inventory
-- SET quantity = -10
-- WHERE product_id = 1;


-- TEST 6: Duplicate product inventory
-- Expected SQLSTATE: 23505
-- Constraint: uq_inventory_product
--
-- INSERT INTO inventory (product_id, quantity)
-- VALUES (1, 25);


-- TEST 7: Invalid product reference
-- Expected SQLSTATE: 23503
-- Constraint: fk_inventory_product
--
-- INSERT INTO inventory (product_id, quantity)
-- VALUES (999, 20);


-- TEST 8: NULL quantity
-- Expected SQLSTATE: 23502
--
-- UPDATE inventory
-- SET quantity = NULL
-- WHERE product_id = 2;


-- TEST 9: Duplicate inventory primary key
-- Expected SQLSTATE: 23505
-- Constraint: pk_inventory
--
-- Note: Use a fresh product_id without an inventory
-- record to isolate the primary key test.
-- Execute inside a transaction and ROLLBACK.
