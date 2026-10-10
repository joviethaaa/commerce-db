
-- =====================================================
-- CommerceDB
-- Test: 004_test_products.sql
-- Purpose: Verify products table and constraints
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
  AND table_name = 'products'
ORDER BY ordinal_position;

-- Expected: 9 columns


-- TEST 2: Verify database constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.products'::regclass
  AND contype IN ('p', 'u', 'f', 'c')
ORDER BY conname;

-- Expected:
-- pk_products             -> PRIMARY KEY
-- uq_products_sku         -> UNIQUE
-- fk_products_category    -> FOREIGN KEY
-- ck_products_unit_price  -> CHECK


-- TEST 3: Verify products and categories
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    p.unit_price,
    p.is_active
FROM products AS p
INNER JOIN categories AS c
    ON p.category_id = c.category_id
ORDER BY p.product_id;


-- TEST 4: Verify product count
SELECT COUNT(*) AS total_products
FROM products;

-- Expected: 3 for initial development dataset


-- =====================================================
-- NEGATIVE TESTS
-- Run individually in the development database.
-- Intentionally commented out.
-- =====================================================

-- TEST 5: Negative unit price
-- Expected SQLSTATE: 23514
-- Constraint: ck_products_unit_price
--
-- INSERT INTO products (
--     category_id, sku, product_name, unit_price
-- )
-- VALUES (
--     1, 'ELEC-TEST-NEG-001',
--     'Invalid Price Product', -150000.00
-- );


-- TEST 6: Duplicate SKU
-- Expected SQLSTATE: 23505
-- Constraint: uq_products_sku
--
-- INSERT INTO products (
--     category_id, sku, product_name, unit_price
-- )
-- VALUES (
--     1, 'ELEC-LAP-001',
--     'Another Laptop', 6500000.00
-- );


-- TEST 7: NULL product name
-- Expected SQLSTATE: 23502
--
-- INSERT INTO products (
--     category_id, sku, product_name, unit_price
-- )
-- VALUES (
--     1, 'ELEC-TEST-NULL-001',
--     NULL, 250000.00
-- );


-- TEST 8: Invalid category reference
-- Expected SQLSTATE: 23503
-- Constraint: fk_products_category
--
-- INSERT INTO products (
--     category_id, sku, product_name, unit_price
-- )
-- VALUES (
--     999, 'ELEC-TEST-FK-001',
--     'Invalid Category Product', 350000.00
-- );


-- TEST 9: Duplicate primary key
-- Expected SQLSTATE: 23505
-- Constraint: pk_products
--
-- INSERT INTO products (
--     product_id,
--     category_id,
--     sku,
--     product_name,
--     unit_price
-- )
-- OVERRIDING SYSTEM VALUE
-- VALUES (
--     1,
--     1,
--     'ELEC-TEST-PK-001',
--     'Duplicate Primary Key Product',
--     100000.00
-- );
