
-- ============================================================
-- CommerceDB
-- Test: 010_test_inventory_movements.sql
-- Target: PostgreSQL 18
-- Purpose: Verify inventory movement integrity
-- ============================================================
--
-- PREREQUISITES:
-- inventory_id 1 and 3 must exist.
-- reservation_id 26 must reference inventory_id 1.
--
-- Run as a complete SQL script in DBeaver.
-- All test inserts and updates are rolled back.
-- ============================================================

BEGIN;

-- ============================================================
-- 01. VERIFY PREREQUISITES
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.inventory
        WHERE inventory_id = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM public.inventory
        WHERE inventory_id = 3
    ) OR NOT EXISTS (
        SELECT 1 FROM public.inventory_reservations
        WHERE reservation_id = 26 AND inventory_id = 1
    ) THEN
        RAISE EXCEPTION
            'TEST SETUP FAILED: Required inventory or reservation missing';
    END IF;

    RAISE NOTICE 'TEST 01 PASS: Prerequisites verified';
END;
$$;

-- ============================================================
-- 02. VALID STOCK_IN
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, movement_type, quantity_change
    )
    VALUES (1, 'STOCK_IN', 10)
    RETURNING movement_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.inventory_movements
        WHERE movement_id = v_id
          AND movement_type = 'STOCK_IN'
          AND quantity_change = 10
    ) THEN
        RAISE EXCEPTION 'TEST 02 FAILED';
    END IF;

    RAISE NOTICE 'TEST 02 PASS: Valid STOCK_IN';
END;
$$;

-- ============================================================
-- 03. VALID STOCK_OUT
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, movement_type, quantity_change
    )
    VALUES (1, 'STOCK_OUT', -2)
    RETURNING movement_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.inventory_movements
        WHERE movement_id = v_id
          AND movement_type = 'STOCK_OUT'
          AND quantity_change = -2
    ) THEN
        RAISE EXCEPTION 'TEST 03 FAILED';
    END IF;

    RAISE NOTICE 'TEST 03 PASS: Valid STOCK_OUT';
END;
$$;

-- ============================================================
-- 04. VALID ADJUSTMENT
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, movement_type, quantity_change
    )
    VALUES (1, 'ADJUSTMENT', -1)
    RETURNING movement_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.inventory_movements
        WHERE movement_id = v_id
          AND movement_type = 'ADJUSTMENT'
          AND quantity_change = -1
    ) THEN
        RAISE EXCEPTION 'TEST 04 FAILED';
    END IF;

    RAISE NOTICE 'TEST 04 PASS: Valid ADJUSTMENT';
END;
$$;

-- ============================================================
-- 05. ZERO QUANTITY MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (1, 'STOCK_IN', 0);
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 05 FAILED: Zero quantity accepted';
    END IF;

    RAISE NOTICE 'TEST 05 PASS: Zero quantity rejected';
END;
$$;

-- ============================================================
-- 06. INVALID MOVEMENT TYPE MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (1, 'INVALID', 10);
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 06 FAILED: Invalid type accepted';
    END IF;

    RAISE NOTICE 'TEST 06 PASS: Invalid type rejected';
END;
$$;

-- ============================================================
-- 07. NEGATIVE STOCK_IN MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (1, 'STOCK_IN', -5);
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 07 FAILED';
    END IF;

    RAISE NOTICE 'TEST 07 PASS: Negative STOCK_IN rejected';
END;
$$;

-- ============================================================
-- 08. POSITIVE STOCK_OUT MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (1, 'STOCK_OUT', 5);
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 08 FAILED';
    END IF;

    RAISE NOTICE 'TEST 08 PASS: Positive STOCK_OUT rejected';
END;
$$;

-- ============================================================
-- 09. INVALID INVENTORY FOREIGN KEY
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (999, 'STOCK_IN', 10);
    EXCEPTION WHEN foreign_key_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 09 FAILED: Invalid inventory accepted';
    END IF;

    RAISE NOTICE 'TEST 09 PASS: Invalid inventory rejected';
END;
$$;

-- ============================================================
-- 10. INVALID RESERVATION FOREIGN KEY
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, reservation_id,
            movement_type, quantity_change
        )
        VALUES (1, 999, 'STOCK_OUT', -1);
    EXCEPTION WHEN foreign_key_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 10 FAILED: Invalid reservation accepted';
    END IF;

    RAISE NOTICE 'TEST 10 PASS: Invalid reservation rejected';
END;
$$;

-- ============================================================
-- 11. RESERVATION INVENTORY MISMATCH
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, reservation_id,
            movement_type, quantity_change
        )
        VALUES (3, 26, 'STOCK_OUT', -1);
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 11 FAILED: Inventory mismatch accepted';
    END IF;

    RAISE NOTICE 'TEST 11 PASS: Inventory mismatch rejected';
END;
$$;

-- ============================================================
-- 12. VALID MOVEMENT WITH RESERVATION
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, reservation_id,
        movement_type, quantity_change
    )
    VALUES (1, 26, 'STOCK_OUT', -1)
    RETURNING movement_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.inventory_movements
        WHERE movement_id = v_id
          AND inventory_id = 1
          AND reservation_id = 26
    ) THEN
        RAISE EXCEPTION 'TEST 12 FAILED';
    END IF;

    RAISE NOTICE 'TEST 12 PASS: Valid reservation movement';
END;
$$;

-- ============================================================
-- 13. NULL INVENTORY ID MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (NULL, 'STOCK_IN', 10);
    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 13 FAILED';
    END IF;

    RAISE NOTICE 'TEST 13 PASS: NULL inventory rejected';
END;
$$;

-- ============================================================
-- 14. NULL MOVEMENT TYPE MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (1, NULL, 10);
    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 14 FAILED';
    END IF;

    RAISE NOTICE 'TEST 14 PASS: NULL movement type rejected';
END;
$$;

-- ============================================================
-- 15. NULL QUANTITY CHANGE MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_movements (
            inventory_id, movement_type, quantity_change
        )
        VALUES (1, 'STOCK_IN', NULL);
    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 15 FAILED';
    END IF;

    RAISE NOTICE 'TEST 15 PASS: NULL quantity rejected';
END;
$$;

-- ============================================================
-- 16. UPDATE INVENTORY MISMATCH MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
    v_rejected BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, reservation_id,
        movement_type, quantity_change
    )
    VALUES (1, 26, 'STOCK_OUT', -1)
    RETURNING movement_id INTO v_id;

    BEGIN
        UPDATE public.inventory_movements
        SET inventory_id = 3
        WHERE movement_id = v_id;
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 16 FAILED';
    END IF;

    RAISE NOTICE 'TEST 16 PASS: UPDATE inventory mismatch rejected';
END;
$$;

-- ============================================================
-- 17. UPDATE QUANTITY TO ZERO MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
    v_rejected BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, movement_type, quantity_change
    )
    VALUES (1, 'STOCK_IN', 10)
    RETURNING movement_id INTO v_id;

    BEGIN
        UPDATE public.inventory_movements
        SET quantity_change = 0
        WHERE movement_id = v_id;
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 17 FAILED';
    END IF;

    RAISE NOTICE 'TEST 17 PASS: UPDATE zero quantity rejected';
END;
$$;

-- ============================================================
-- 18. UPDATE INVALID DIRECTION MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
    v_rejected BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.inventory_movements (
        inventory_id, movement_type, quantity_change
    )
    VALUES (1, 'STOCK_IN', 10)
    RETURNING movement_id INTO v_id;

    BEGIN
        UPDATE public.inventory_movements
        SET movement_type = 'STOCK_OUT'
        WHERE movement_id = v_id;
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 18 FAILED';
    END IF;

    RAISE NOTICE 'TEST 18 PASS: Invalid UPDATE direction rejected';
END;
$$;

-- ============================================================
-- 19. VERIFY STOCK BALANCES
-- ============================================================

SELECT
    inventory_id,
    product_id,
    quantity_on_hand,
    quantity_reserved
FROM public.inventory
ORDER BY inventory_id;

-- ============================================================
-- 20. ROLLBACK ALL TEST DATA
-- ============================================================

ROLLBACK;

-- ============================================================
-- 21. FINAL VERIFICATION
-- ============================================================

SELECT *
FROM public.inventory_movements
ORDER BY movement_id;

-- ============================================================
-- END OF TEST FILE
-- ============================================================
