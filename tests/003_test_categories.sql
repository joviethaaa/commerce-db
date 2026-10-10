
-- =====================================================
-- CommerceDB
-- Test: 003_test_categories.sql
-- Purpose: Verify categories table and constraints
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
  AND table_name = 'categories'
ORDER BY ordinal_position;

-- Expected: 4 columns
-- category_id, category_name, description, is_active


-- TEST 2: Verify PRIMARY KEY and UNIQUE constraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.categories'::regclass
  AND contype IN ('p', 'u')
ORDER BY conname;

-- Expected:
-- pk_categories      -> p
-- uq_categories_name -> u


-- TEST 3: Verify DEFAULT TRUE
SELECT
    category_id,
    category_name,
    is_active
FROM categories
ORDER BY category_id;

-- Expected:
-- Electronics   -> TRUE
-- Fashion       -> TRUE
-- Home & Living -> TRUE


-- TEST 4: Verify total categories
SELECT COUNT(*) AS total_categories
FROM categories;

-- Expected: 3 for the initial development dataset


-- =====================================================
-- NEGATIVE TESTS
-- Run individually in the development database.
-- Intentionally commented out.
-- =====================================================

-- TEST 5: Duplicate category name
-- Expected SQLSTATE: 23505
-- Constraint: uq_categories_name
--
-- INSERT INTO categories (
--     category_name,
--     description
-- )
-- VALUES (
--     'Electronics',
--     'Duplicate category for constraint testing'
-- );


-- TEST 6: NULL category name
-- Expected SQLSTATE: 23502
--
-- INSERT INTO categories (
--     category_name,
--     description
-- )
-- VALUES (
--     NULL,
--     'Testing NOT NULL constraint'
-- );


-- TEST 7: Duplicate PRIMARY KEY
-- Expected SQLSTATE: 23505
-- Constraint: pk_categories
--
-- INSERT INTO categories (
--     category_id,
--     category_name,
--     description
-- )
-- OVERRIDING SYSTEM VALUE
-- VALUES (
--     1,
--     'Sports',
--     'Sports equipment and accessories'
-- );
