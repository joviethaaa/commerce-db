
-- ============================================================
-- CommerceDB
-- Test: 009_test_inventory_reservations.sql
-- Purpose: Test inventory reservation integrity
-- Target: PostgreSQL 18
-- ============================================================

-- REQUIREMENTS:
-- order_item_id 1 -> product_id 1
-- order_item_id 2 -> product_id 3
-- inventory_id 1  -> product_id 1
-- inventory_id 3  -> product_id 3
--
-- Run as a COMPLETE SQL SCRIPT in DBeaver.
-- Expected failures are caught and verified automatically.
-- All test data is rolled back.

BEGIN;

-- ============================================================
-- 01. VERIFY TEST PREREQUISITES
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM public.order_items
        WHERE order_item_id = 1 AND product_id = 1
    ) OR NOT EXISTS (
        SELECT 1
        FROM public.order_items
        WHERE order_item_id = 2 AND product_id = 3
    ) OR NOT EXISTS (
        SELECT 1
        FROM public.inventory
        WHERE inventory_id = 1 AND product_id = 1
    ) OR NOT EXISTS (
        SELECT 1
        FROM public.inventory
        WHERE inventory_id = 3 AND product_id = 3
    ) THEN
        RAISE EXCEPTION
            'Test prerequisites not satisfied. Check seed data.';
    END IF;
END;
$$;

-- ============================================================
-- 02. VALID ACTIVE RESERVATION
-- Expected: SUCCESS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status
    )
    VALUES (1, 1, 1, 'ACTIVE')
    RETURNING reservation_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.inventory_reservations
        WHERE reservation_id = v_id
          AND reservation_status = 'ACTIVE'
          AND resolved_at IS NULL
    ) THEN
        RAISE EXCEPTION 'TEST 02 FAILED';
    END IF;

    RAISE NOTICE 'TEST 02 PASS: Valid ACTIVE reservation';
END;
$$;

-- ============================================================
-- 03. VALID RELEASED RESERVATION
-- Expected: SUCCESS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status,
        resolved_at
    )
    VALUES (1, 1, 1, 'RELEASED', CURRENT_TIMESTAMP)
    RETURNING reservation_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.inventory_reservations
        WHERE reservation_id = v_id
          AND reservation_status = 'RELEASED'
          AND resolved_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'TEST 03 FAILED';
    END IF;

    RAISE NOTICE 'TEST 03 PASS: Valid RELEASED reservation';
END;
$$;

-- ============================================================
-- 04. VALID CONSUMED RESERVATION
-- Expected: SUCCESS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status,
        resolved_at
    )
    VALUES (2, 3, 1, 'CONSUMED', CURRENT_TIMESTAMP)
    RETURNING reservation_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.inventory_reservations
        WHERE reservation_id = v_id
          AND reservation_status = 'CONSUMED'
          AND resolved_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'TEST 04 FAILED';
    END IF;

    RAISE NOTICE 'TEST 04 PASS: Valid CONSUMED reservation';
END;
$$;

-- ============================================================
-- 05. INVALID QUANTITY
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity)
        VALUES (1, 1, 0);

        RAISE EXCEPTION 'TEST 05 FAILED: Invalid quantity accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 05 PASS: Invalid quantity rejected';
    END;
END;
$$;

-- ============================================================
-- 06. INVALID STATUS
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity, reservation_status)
        VALUES (1, 1, 1, 'INVALID');

        RAISE EXCEPTION 'TEST 06 FAILED: Invalid status accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 06 PASS: Invalid status rejected';
    END;
END;
$$;

-- ============================================================
-- 07. PRODUCT MISMATCH
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity)
        VALUES (1, 3, 1);

        RAISE EXCEPTION 'TEST 07 FAILED: Product mismatch accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 07 PASS: Product mismatch rejected';
    END;
END;
$$;

-- ============================================================
-- 08. INVALID ORDER ITEM FOREIGN KEY
-- Expected: SQLSTATE 23503
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity)
        VALUES (999, 1, 1);

        RAISE EXCEPTION 'TEST 08 FAILED: Invalid order item accepted';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'TEST 08 PASS: Invalid order item rejected';
    END;
END;
$$;

-- ============================================================
-- 09. INVALID INVENTORY FOREIGN KEY
-- Expected: SQLSTATE 23503
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity)
        VALUES (1, 999, 1);

        RAISE EXCEPTION 'TEST 09 FAILED: Invalid inventory accepted';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'TEST 09 PASS: Invalid inventory rejected';
    END;
END;
$$;

-- ============================================================
-- 10. NULL QUANTITY
-- Expected: SQLSTATE 23502
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity)
        VALUES (1, 1, NULL);

        RAISE EXCEPTION 'TEST 10 FAILED: NULL quantity accepted';

    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE 'TEST 10 PASS: NULL quantity rejected';
    END;
END;
$$;

-- ============================================================
-- 11. NULL STATUS
-- Expected: SQLSTATE 23502
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations
            (order_item_id, inventory_id, quantity, reservation_status)
        VALUES (1, 1, 1, NULL);

        RAISE EXCEPTION 'TEST 11 FAILED: NULL status accepted';

    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE 'TEST 11 PASS: NULL status rejected';
    END;
END;
$$;

-- ============================================================
-- 12. ACTIVE WITH RESOLVED_AT
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations (
            order_item_id,
            inventory_id,
            quantity,
            reservation_status,
            resolved_at
        )
        VALUES (1, 1, 1, 'ACTIVE', CURRENT_TIMESTAMP);

        RAISE EXCEPTION 'TEST 12 FAILED: ACTIVE with resolved_at accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 12 PASS: ACTIVE with resolved_at rejected';
    END;
END;
$$;

-- ============================================================
-- 13. RELEASED WITHOUT RESOLVED_AT
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO public.inventory_reservations (
            order_item_id,
            inventory_id,
            quantity,
            reservation_status
        )
        VALUES (1, 1, 1, 'RELEASED');

        RAISE EXCEPTION 'TEST 13 FAILED: RELEASED without resolved_at accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 13 PASS: RELEASED without resolved_at rejected';
    END;
END;
$$;

-- ============================================================
-- 14. VALID ACTIVE -> RELEASED
-- Expected: SUCCESS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status
    )
    VALUES (1, 1, 1, 'ACTIVE')
    RETURNING reservation_id INTO v_id;

    UPDATE public.inventory_reservations
    SET
        reservation_status = 'RELEASED',
        resolved_at = CURRENT_TIMESTAMP
    WHERE reservation_id = v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.inventory_reservations
        WHERE reservation_id = v_id
          AND reservation_status = 'RELEASED'
          AND resolved_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'TEST 14 FAILED';
    END IF;

    RAISE NOTICE 'TEST 14 PASS: ACTIVE -> RELEASED';
END;
$$;

-- ============================================================
-- 15. VALID ACTIVE -> CONSUMED
-- Expected: SUCCESS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status
    )
    VALUES (2, 3, 1, 'ACTIVE')
    RETURNING reservation_id INTO v_id;

    UPDATE public.inventory_reservations
    SET
        reservation_status = 'CONSUMED',
        resolved_at = CURRENT_TIMESTAMP
    WHERE reservation_id = v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.inventory_reservations
        WHERE reservation_id = v_id
          AND reservation_status = 'CONSUMED'
          AND resolved_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'TEST 15 FAILED';
    END IF;

    RAISE NOTICE 'TEST 15 PASS: ACTIVE -> CONSUMED';
END;
$$;

-- ============================================================
-- 16. INVALID RELEASED -> ACTIVE
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status,
        resolved_at
    )
    VALUES (1, 1, 1, 'RELEASED', CURRENT_TIMESTAMP)
    RETURNING reservation_id INTO v_id;

    BEGIN
        UPDATE public.inventory_reservations
        SET
            reservation_status = 'ACTIVE',
            resolved_at = NULL
        WHERE reservation_id = v_id;

        RAISE EXCEPTION 'TEST 16 FAILED: RELEASED -> ACTIVE accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 16 PASS: RELEASED -> ACTIVE rejected';
    END;
END;
$$;

-- ============================================================
-- 17. INVALID RELEASED -> CONSUMED
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status,
        resolved_at
    )
    VALUES (1, 1, 1, 'RELEASED', CURRENT_TIMESTAMP)
    RETURNING reservation_id INTO v_id;

    BEGIN
        UPDATE public.inventory_reservations
        SET reservation_status = 'CONSUMED'
        WHERE reservation_id = v_id;

        RAISE EXCEPTION 'TEST 17 FAILED: RELEASED -> CONSUMED accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 17 PASS: RELEASED -> CONSUMED rejected';
    END;
END;
$$;

-- ============================================================
-- 18. INVALID CONSUMED -> ACTIVE
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status,
        resolved_at
    )
    VALUES (2, 3, 1, 'CONSUMED', CURRENT_TIMESTAMP)
    RETURNING reservation_id INTO v_id;

    BEGIN
        UPDATE public.inventory_reservations
        SET
            reservation_status = 'ACTIVE',
            resolved_at = NULL
        WHERE reservation_id = v_id;

        RAISE EXCEPTION 'TEST 18 FAILED: CONSUMED -> ACTIVE accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 18 PASS: CONSUMED -> ACTIVE rejected';
    END;
END;
$$;

-- ============================================================
-- 19. INVALID CONSUMED -> RELEASED
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status,
        resolved_at
    )
    VALUES (2, 3, 1, 'CONSUMED', CURRENT_TIMESTAMP)
    RETURNING reservation_id INTO v_id;

    BEGIN
        UPDATE public.inventory_reservations
        SET reservation_status = 'RELEASED'
        WHERE reservation_id = v_id;

        RAISE EXCEPTION 'TEST 19 FAILED: CONSUMED -> RELEASED accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 19 PASS: CONSUMED -> RELEASED rejected';
    END;
END;
$$;

-- ============================================================
-- 20. INVALID PRODUCT UPDATE
-- Expected: SQLSTATE 23514
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_reservations (
        order_item_id,
        inventory_id,
        quantity,
        reservation_status
    )
    VALUES (1, 1, 1, 'ACTIVE')
    RETURNING reservation_id INTO v_id;

    BEGIN
        UPDATE public.inventory_reservations
        SET inventory_id = 3
        WHERE reservation_id = v_id;

        RAISE EXCEPTION 'TEST 20 FAILED: Product mismatch update accepted';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 20 PASS: Product mismatch update rejected';
    END;
END;
$$;

-- ============================================================
-- 21. FINAL VERIFICATION
-- ============================================================

SELECT
    reservation_id,
    order_item_id,
    inventory_id,
    quantity,
    reservation_status,
    reserved_at,
    resolved_at
FROM public.inventory_reservations
ORDER BY reservation_id;

-- ============================================================
-- ROLLBACK ALL TEST DATA
-- ============================================================

ROLLBACK;

-- ============================================================
-- 22. VERIFY DATABASE AFTER ROLLBACK
-- ============================================================

SELECT
    reservation_id,
    order_item_id,
    inventory_id,
    quantity,
    reservation_status,
    reserved_at,
    resolved_at
FROM public.inventory_reservations
ORDER BY reservation_id;

-- ============================================================
-- END OF TEST FILE
-- ============================================================
