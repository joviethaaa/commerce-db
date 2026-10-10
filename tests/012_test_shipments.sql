
-- ============================================================
-- CommerceDB
-- Test: 012_test_shipments.sql
-- Purpose: Verify shipment integrity and state transitions
-- Target: PostgreSQL 18
-- ============================================================
--
-- REQUIREMENTS:
-- - Migration 012 has been applied.
-- - order_id = 1 exists.
-- - No pre-existing active shipment for order_id = 1.
--
-- Execute as a complete SQL script in DBeaver.
-- All test changes will be rolled back.
-- ============================================================

BEGIN;

-- ============================================================
-- TEST 01: PREREQUISITES
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.orders
        WHERE order_id = 1
    ) THEN
        RAISE EXCEPTION
            'TEST 01 FAILED: order_id 1 does not exist';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.shipments
        WHERE order_id = 1
          AND shipment_status IN ('PENDING', 'SHIPPED')
    ) THEN
        RAISE EXCEPTION
            'TEST 01 FAILED: Order 1 has an active shipment';
    END IF;

    RAISE NOTICE 'TEST 01 PASS: Prerequisites verified';
END;
$$;

-- ============================================================
-- TEST 02: VALID PENDING
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name, shipment_status
    )
    VALUES (1, 'JNE', 'PENDING')
    RETURNING shipment_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND shipment_status = 'PENDING'
          AND shipped_at IS NULL
          AND delivered_at IS NULL
    ) THEN
        RAISE EXCEPTION 'TEST 02 FAILED';
    END IF;

    DELETE FROM public.shipments
    WHERE shipment_id = v_id;

    RAISE NOTICE 'TEST 02 PASS: Valid PENDING';
END;
$$;

-- ============================================================
-- TEST 03: VALID SHIPPED
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, tracking_number, courier_name,
        shipment_status, shipped_at
    )
    VALUES (
        1, 'TEST012-SHIPPED', 'JNE',
        'SHIPPED', CURRENT_TIMESTAMP
    )
    RETURNING shipment_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND shipment_status = 'SHIPPED'
          AND shipped_at IS NOT NULL
          AND delivered_at IS NULL
    ) THEN
        RAISE EXCEPTION 'TEST 03 FAILED';
    END IF;

    DELETE FROM public.shipments
    WHERE shipment_id = v_id;

    RAISE NOTICE 'TEST 03 PASS: Valid SHIPPED';
END;
$$;

-- ============================================================
-- TEST 04: VALID DELIVERED
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, tracking_number, courier_name,
        shipment_status, shipped_at, delivered_at
    )
    VALUES (
        1, 'TEST012-DELIVERED', 'JNE',
        'DELIVERED',
        CURRENT_TIMESTAMP - INTERVAL '2 days',
        CURRENT_TIMESTAMP
    )
    RETURNING shipment_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND shipment_status = 'DELIVERED'
          AND delivered_at >= shipped_at
    ) THEN
        RAISE EXCEPTION 'TEST 04 FAILED';
    END IF;

    RAISE NOTICE 'TEST 04 PASS: Valid DELIVERED';
END;
$$;

-- ============================================================
-- TEST 05: VALID CANCELLED
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name, shipment_status
    )
    VALUES (1, 'JNE', 'CANCELLED')
    RETURNING shipment_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND shipment_status = 'CANCELLED'
          AND delivered_at IS NULL
    ) THEN
        RAISE EXCEPTION 'TEST 05 FAILED';
    END IF;

    RAISE NOTICE 'TEST 05 PASS: Valid CANCELLED';
END;
$$;

-- ============================================================
-- TEST 06: INVALID STATUS
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status
        )
        VALUES (1, 'JNE', 'INVALID');
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 06 FAILED';
    END IF;

    RAISE NOTICE 'TEST 06 PASS: Invalid status rejected';
END;
$$;

-- ============================================================
-- TEST 07: PENDING WITH SHIPPED_AT
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name,
            shipment_status, shipped_at
        )
        VALUES (1, 'JNE', 'PENDING', CURRENT_TIMESTAMP);
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 07 FAILED';
    END IF;

    RAISE NOTICE 'TEST 07 PASS: Invalid PENDING timestamp rejected';
END;
$$;

-- ============================================================
-- TEST 08: SHIPPED WITHOUT SHIPPED_AT
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status
        )
        VALUES (1, 'JNE', 'SHIPPED');
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 08 FAILED';
    END IF;

    RAISE NOTICE 'TEST 08 PASS: SHIPPED without timestamp rejected';
END;
$$;

-- ============================================================
-- TEST 09: DELIVERED BEFORE SHIPPED
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status,
            shipped_at, delivered_at
        )
        VALUES (
            1, 'JNE', 'DELIVERED',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP - INTERVAL '1 day'
        );
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 09 FAILED';
    END IF;

    RAISE NOTICE 'TEST 09 PASS: Invalid delivery time rejected';
END;
$$;

-- ============================================================
-- TEST 10: DELIVERED WITHOUT DELIVERED_AT
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status,
            shipped_at
        )
        VALUES (
            1, 'JNE', 'DELIVERED', CURRENT_TIMESTAMP
        );
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 10 FAILED';
    END IF;

    RAISE NOTICE 'TEST 10 PASS: Missing delivery time rejected';
END;
$$;

-- ============================================================
-- TEST 11: INVALID ORDER FOREIGN KEY
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status
        )
        VALUES (999999, 'JNE', 'PENDING');
    EXCEPTION WHEN foreign_key_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 11 FAILED';
    END IF;

    RAISE NOTICE 'TEST 11 PASS: Invalid order rejected';
END;
$$;

-- ============================================================
-- TEST 12: DUPLICATE TRACKING NUMBER
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, tracking_number,
            courier_name, shipment_status,
            shipped_at, delivered_at
        )
        VALUES (
            1, 'TEST012-DELIVERED',
            'JNT', 'DELIVERED',
            CURRENT_TIMESTAMP - INTERVAL '1 day',
            CURRENT_TIMESTAMP
        );
    EXCEPTION WHEN unique_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 12 FAILED';
    END IF;

    RAISE NOTICE 'TEST 12 PASS: Duplicate tracking rejected';
END;
$$;

-- ============================================================
-- TEST 13: TWO ACTIVE SHIPMENTS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
    v_rejected BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name, shipment_status
    )
    VALUES (1, 'JNE', 'PENDING')
    RETURNING shipment_id INTO v_id;

    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status,
            shipped_at
        )
        VALUES (
            1, 'JNT', 'SHIPPED', CURRENT_TIMESTAMP
        );
    EXCEPTION WHEN unique_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 13 FAILED';
    END IF;

    DELETE FROM public.shipments
    WHERE shipment_id = v_id;

    RAISE NOTICE 'TEST 13 PASS: Second active shipment rejected';
END;
$$;

-- ============================================================
-- TEST 14: VALID PENDING -> SHIPPED
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name, shipment_status
    )
    VALUES (1, 'JNE', 'PENDING')
    RETURNING shipment_id INTO v_id;

    UPDATE public.shipments
    SET
        shipment_status = 'SHIPPED',
        shipped_at = CURRENT_TIMESTAMP
    WHERE shipment_id = v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND shipment_status = 'SHIPPED'
          AND shipped_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'TEST 14 FAILED';
    END IF;

    DELETE FROM public.shipments
    WHERE shipment_id = v_id;

    RAISE NOTICE 'TEST 14 PASS: PENDING -> SHIPPED';
END;
$$;

-- ============================================================
-- TEST 15: VALID SHIPPED -> DELIVERED
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name,
        shipment_status, shipped_at
    )
    VALUES (
        1, 'JNE', 'SHIPPED',
        CURRENT_TIMESTAMP - INTERVAL '1 day'
    )
    RETURNING shipment_id INTO v_id;

    UPDATE public.shipments
    SET
        shipment_status = 'DELIVERED',
        delivered_at = CURRENT_TIMESTAMP
    WHERE shipment_id = v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND shipment_status = 'DELIVERED'
          AND delivered_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'TEST 15 FAILED';
    END IF;

    RAISE NOTICE 'TEST 15 PASS: SHIPPED -> DELIVERED';
END;
$$;

-- ============================================================
-- TEST 16: DELIVERED -> PENDING MUST FAIL
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE public.shipments
        SET
            shipment_status = 'PENDING',
            shipped_at = NULL,
            delivered_at = NULL
        WHERE tracking_number = 'TEST012-DELIVERED';
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 16 FAILED';
    END IF;

    RAISE NOTICE 'TEST 16 PASS: DELIVERED -> PENDING rejected';
END;
$$;

-- ============================================================
-- TEST 17: SHIPPED -> PENDING MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
    v_rejected BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name,
        shipment_status, shipped_at
    )
    VALUES (
        1, 'JNE', 'SHIPPED', CURRENT_TIMESTAMP
    )
    RETURNING shipment_id INTO v_id;

    BEGIN
        UPDATE public.shipments
        SET
            shipment_status = 'PENDING',
            shipped_at = NULL
        WHERE shipment_id = v_id;
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 17 FAILED';
    END IF;

    DELETE FROM public.shipments
    WHERE shipment_id = v_id;

    RAISE NOTICE 'TEST 17 PASS: SHIPPED -> PENDING rejected';
END;
$$;

-- ============================================================
-- TEST 18: CANCELLED -> SHIPPED MUST FAIL
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
    v_rejected BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.shipments (
        order_id, courier_name, shipment_status
    )
    VALUES (1, 'JNE', 'CANCELLED')
    RETURNING shipment_id INTO v_id;

    BEGIN
        UPDATE public.shipments
        SET
            shipment_status = 'SHIPPED',
            shipped_at = CURRENT_TIMESTAMP
        WHERE shipment_id = v_id;
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 18 FAILED';
    END IF;

    RAISE NOTICE 'TEST 18 PASS: CANCELLED -> SHIPPED rejected';
END;
$$;

-- ============================================================
-- TEST 19: NULL ORDER_ID MUST FAIL
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name
        )
        VALUES (NULL, 'JNE');
    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 19 FAILED';
    END IF;

    RAISE NOTICE 'TEST 19 PASS: NULL order rejected';
END;
$$;

-- ============================================================
-- TEST 20: NULL COURIER_NAME MUST FAIL
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name
        )
        VALUES (1, NULL);
    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 20 FAILED';
    END IF;

    RAISE NOTICE 'TEST 20 PASS: NULL courier rejected';
END;
$$;

-- ============================================================
-- TEST 21: NULL SHIPMENT_STATUS MUST FAIL
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.shipments (
            order_id, courier_name, shipment_status
        )
        VALUES (1, 'JNE', NULL);
    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 21 FAILED';
    END IF;

    RAISE NOTICE 'TEST 21 PASS: NULL status rejected';
END;
$$;

-- ============================================================
-- TEST 22: NULL TRACKING NUMBER ALLOWED
-- ============================================================

DO $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO public.shipments (
        order_id, tracking_number,
        courier_name, shipment_status
    )
    VALUES (
        1, NULL, 'JNE', 'CANCELLED'
    )
    RETURNING shipment_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE shipment_id = v_id
          AND tracking_number IS NULL
    ) THEN
        RAISE EXCEPTION 'TEST 22 FAILED';
    END IF;

    RAISE NOTICE 'TEST 22 PASS: NULL tracking allowed';
END;
$$;

-- ============================================================
-- TEST 23: FINALIZED DELIVERY TIMESTAMPS IMMUTABLE
-- ============================================================

DO $$
DECLARE v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE public.shipments
        SET delivered_at = CURRENT_TIMESTAMP + INTERVAL '1 day'
        WHERE tracking_number = 'TEST012-DELIVERED';
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST 23 FAILED';
    END IF;

    RAISE NOTICE 'TEST 23 PASS: Delivery timestamp immutable';
END;
$$;

-- ============================================================
-- TEST 24: VERIFY TEMPORARY ROWS
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.shipments
        WHERE tracking_number = 'TEST012-DELIVERED'
          AND shipment_status = 'DELIVERED'
    ) THEN
        RAISE EXCEPTION 'TEST 24 FAILED';
    END IF;

    RAISE NOTICE 'TEST 24 PASS: Transaction test data verified';
END;
$$;

-- ============================================================
-- ROLLBACK ALL TEST CHANGES
-- ============================================================

ROLLBACK;

-- ============================================================
-- FINAL DATABASE VERIFICATION
-- ============================================================

SELECT *
FROM public.shipments
ORDER BY shipment_id;

-- ============================================================
-- END OF TEST FILE
-- ============================================================
