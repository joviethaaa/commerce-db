
-- ============================================================
-- CommerceDB
-- Test: 011_test_payment_attempts.sql
-- Purpose: Verify payment attempt integrity
-- Target: PostgreSQL 18
-- ============================================================
--
-- PREREQUISITES:
-- Migration 011 must already be applied.
-- order_id = 1 must exist in public.orders.
--
-- Run as a complete SQL script in DBeaver.
-- All test data will be rolled back.
-- ============================================================

BEGIN;

-- ============================================================
-- TEST 01: VERIFY PREREQUISITES
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM public.orders
        WHERE order_id = 1
    ) THEN
        RAISE EXCEPTION
            'TEST 01 FAILED: Order 1 does not exist';
    END IF;

    RAISE NOTICE
        'TEST 01 PASS: Prerequisites verified';
END;
$$;

-- ============================================================
-- TEST 02: VALID PENDING
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status
    )
    VALUES (
        1,
        'TEST011-PENDING',
        'BANK_TRANSFER',
        100000,
        'PENDING'
    )
    RETURNING payment_attempt_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'PENDING'
          AND completed_at IS NULL
    ) THEN
        RAISE EXCEPTION
            'TEST 02 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 02 PASS: Valid PENDING';
END;
$$;

-- ============================================================
-- TEST 03: VALID SUCCESS
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status,
        completed_at
    )
    VALUES (
        1,
        'TEST011-SUCCESS',
        'BANK_TRANSFER',
        100000,
        'SUCCESS',
        CURRENT_TIMESTAMP
    )
    RETURNING payment_attempt_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'SUCCESS'
          AND completed_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION
            'TEST 03 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 03 PASS: Valid SUCCESS';
END;
$$;

-- ============================================================
-- TEST 04: VALID FAILED
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status,
        completed_at
    )
    VALUES (
        1,
        'TEST011-FAILED',
        'EWALLET',
        100000,
        'FAILED',
        CURRENT_TIMESTAMP
    )
    RETURNING payment_attempt_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'FAILED'
          AND completed_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION
            'TEST 04 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 04 PASS: Valid FAILED';
END;
$$;

-- ============================================================
-- TEST 05: VALID CANCELLED
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status,
        completed_at
    )
    VALUES (
        1,
        'TEST011-CANCELLED',
        'BANK_TRANSFER',
        100000,
        'CANCELLED',
        CURRENT_TIMESTAMP
    )
    RETURNING payment_attempt_id INTO v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'CANCELLED'
          AND completed_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION
            'TEST 05 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 05 PASS: Valid CANCELLED';
END;
$$;

-- ============================================================
-- TEST 06: ZERO AMOUNT
-- Expected: CHECK violation
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount
        )
        VALUES (
            1,
            'TEST011-ZERO',
            'BANK_TRANSFER',
            0
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 06 FAILED: Zero amount accepted';
    END IF;

    RAISE NOTICE
        'TEST 06 PASS: Zero amount rejected';
END;
$$;

-- ============================================================
-- TEST 07: NEGATIVE AMOUNT
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount
        )
        VALUES (
            1,
            'TEST011-NEGATIVE',
            'BANK_TRANSFER',
            -100
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 07 FAILED: Negative amount accepted';
    END IF;

    RAISE NOTICE
        'TEST 07 PASS: Negative amount rejected';
END;
$$;

-- ============================================================
-- TEST 08: INVALID PAYMENT STATUS
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status
        )
        VALUES (
            1,
            'TEST011-INVALID',
            'BANK_TRANSFER',
            100000,
            'INVALID'
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 08 FAILED: Invalid status accepted';
    END IF;

    RAISE NOTICE
        'TEST 08 PASS: Invalid status rejected';
END;
$$;

-- ============================================================
-- TEST 09: PENDING WITH COMPLETED_AT
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status,
            completed_at
        )
        VALUES (
            1,
            'TEST011-PENDING-DATE',
            'BANK_TRANSFER',
            100000,
            'PENDING',
            CURRENT_TIMESTAMP
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 09 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 09 PASS: PENDING with completed_at rejected';
END;
$$;

-- ============================================================
-- TEST 10: SUCCESS WITHOUT COMPLETED_AT
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status
        )
        VALUES (
            1,
            'TEST011-SUCCESS-NODATE',
            'BANK_TRANSFER',
            100000,
            'SUCCESS'
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 10 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 10 PASS: SUCCESS without completed_at rejected';
END;
$$;

-- ============================================================
-- TEST 11: FAILED WITHOUT COMPLETED_AT
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status
        )
        VALUES (
            1,
            'TEST011-FAILED-NODATE',
            'BANK_TRANSFER',
            100000,
            'FAILED'
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 11 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 11 PASS: FAILED without completed_at rejected';
END;
$$;

-- ============================================================
-- TEST 12: CANCELLED WITHOUT COMPLETED_AT
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status
        )
        VALUES (
            1,
            'TEST011-CANCELLED-NODATE',
            'BANK_TRANSFER',
            100000,
            'CANCELLED'
        );

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 12 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 12 PASS: CANCELLED without completed_at rejected';
END;
$$;

-- ============================================================
-- TEST 13: INVALID ORDER FOREIGN KEY
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount
        )
        VALUES (
            999999,
            'TEST011-BAD-ORDER',
            'BANK_TRANSFER',
            100000
        );

    EXCEPTION WHEN foreign_key_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 13 FAILED: Invalid order accepted';
    END IF;

    RAISE NOTICE
        'TEST 13 PASS: Invalid order rejected';
END;
$$;

-- ============================================================
-- TEST 14: DUPLICATE PAYMENT REFERENCE
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount
        )
        VALUES (
            1,
            'TEST011-PENDING',
            'EWALLET',
            100000
        );

    EXCEPTION WHEN unique_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 14 FAILED: Duplicate reference accepted';
    END IF;

    RAISE NOTICE
        'TEST 14 PASS: Duplicate reference rejected';
END;
$$;

-- ============================================================
-- TEST 15: TWO SUCCESS PAYMENTS FOR SAME ORDER
-- ============================================================

-- TEST 03 has already inserted a SUCCESS payment
-- for order_id = 1 in this transaction.

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status,
            completed_at
        )
        VALUES (
            1,
            'TEST011-SECOND-SUCCESS',
            'EWALLET',
            100000,
            'SUCCESS',
            CURRENT_TIMESTAMP
        );

    EXCEPTION WHEN unique_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 15 FAILED: Second SUCCESS accepted';
    END IF;

    RAISE NOTICE
        'TEST 15 PASS: Second SUCCESS rejected';
END;
$$;

-- ============================================================
-- TEST 16: MULTIPLE FAILED PAYMENTS ALLOWED
-- ============================================================

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status,
        completed_at
    )
    VALUES (
        1,
        'TEST011-FAILED-SECOND',
        'EWALLET',
        100000,
        'FAILED',
        CURRENT_TIMESTAMP
    );

    SELECT COUNT(*)
    INTO v_count
    FROM public.payment_attempts
    WHERE order_id = 1
      AND payment_status = 'FAILED'
      AND payment_reference IN (
          'TEST011-FAILED',
          'TEST011-FAILED-SECOND'
      );

    IF v_count <> 2 THEN
        RAISE EXCEPTION
            'TEST 16 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 16 PASS: Multiple FAILED payments allowed';
END;
$$;

-- ============================================================
-- TEST 17: VALID PENDING -> SUCCESS
-- ============================================================

-- Use a separate order for the transition.
-- To avoid requiring another seed order,
-- temporarily remove the earlier SUCCESS test row.

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    DELETE FROM public.payment_attempts
    WHERE payment_reference = 'TEST011-SUCCESS';

    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status
    )
    VALUES (
        1,
        'TEST011-TRANSITION-SUCCESS',
        'BANK_TRANSFER',
        100000,
        'PENDING'
    )
    RETURNING payment_attempt_id INTO v_id;

    UPDATE public.payment_attempts
    SET
        payment_status = 'SUCCESS',
        completed_at = CURRENT_TIMESTAMP
    WHERE payment_attempt_id = v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'SUCCESS'
          AND completed_at IS NOT NULL
    ) THEN
        RAISE EXCEPTION
            'TEST 17 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 17 PASS: PENDING -> SUCCESS';
END;
$$;

-- ============================================================
-- TEST 18: VALID PENDING -> FAILED
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount
    )
    VALUES (
        1,
        'TEST011-TRANSITION-FAILED',
        'BANK_TRANSFER',
        100000
    )
    RETURNING payment_attempt_id INTO v_id;

    UPDATE public.payment_attempts
    SET
        payment_status = 'FAILED',
        completed_at = CURRENT_TIMESTAMP
    WHERE payment_attempt_id = v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'FAILED'
    ) THEN
        RAISE EXCEPTION
            'TEST 18 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 18 PASS: PENDING -> FAILED';
END;
$$;

-- ============================================================
-- TEST 19: VALID PENDING -> CANCELLED
-- ============================================================

DO $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO public.payment_attempts (
        order_id,
        payment_reference,
        payment_method,
        amount
    )
    VALUES (
        1,
        'TEST011-TRANSITION-CANCELLED',
        'EWALLET',
        100000
    )
    RETURNING payment_attempt_id INTO v_id;

    UPDATE public.payment_attempts
    SET
        payment_status = 'CANCELLED',
        completed_at = CURRENT_TIMESTAMP
    WHERE payment_attempt_id = v_id;

    IF NOT EXISTS (
        SELECT 1
        FROM public.payment_attempts
        WHERE payment_attempt_id = v_id
          AND payment_status = 'CANCELLED'
    ) THEN
        RAISE EXCEPTION
            'TEST 19 FAILED';
    END IF;

    RAISE NOTICE
        'TEST 19 PASS: PENDING -> CANCELLED';
END;
$$;

-- ============================================================
-- TEST 20: INVALID SUCCESS -> PENDING
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE public.payment_attempts
        SET
            payment_status = 'PENDING',
            completed_at = NULL
        WHERE payment_reference =
            'TEST011-TRANSITION-SUCCESS';

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 20 FAILED: SUCCESS -> PENDING accepted';
    END IF;

    RAISE NOTICE
        'TEST 20 PASS: SUCCESS -> PENDING rejected';
END;
$$;

-- ============================================================
-- TEST 21: INVALID FAILED -> SUCCESS
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE public.payment_attempts
        SET payment_status = 'SUCCESS'
        WHERE payment_reference =
            'TEST011-TRANSITION-FAILED';

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 21 FAILED: FAILED -> SUCCESS accepted';
    END IF;

    RAISE NOTICE
        'TEST 21 PASS: FAILED -> SUCCESS rejected';
END;
$$;

-- ============================================================
-- TEST 22: INVALID CANCELLED -> PENDING
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE public.payment_attempts
        SET
            payment_status = 'PENDING',
            completed_at = NULL
        WHERE payment_reference =
            'TEST011-TRANSITION-CANCELLED';

    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 22 FAILED: CANCELLED -> PENDING accepted';
    END IF;

    RAISE NOTICE
        'TEST 22 PASS: CANCELLED -> PENDING rejected';
END;
$$;

-- ============================================================
-- TEST 23: NULL AMOUNT
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount
        )
        VALUES (
            1,
            'TEST011-NULL-AMOUNT',
            'BANK_TRANSFER',
            NULL
        );

    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 23 FAILED: NULL amount accepted';
    END IF;

    RAISE NOTICE
        'TEST 23 PASS: NULL amount rejected';
END;
$$;

-- ============================================================
-- TEST 24: NULL PAYMENT STATUS
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount,
            payment_status
        )
        VALUES (
            1,
            'TEST011-NULL-STATUS',
            'BANK_TRANSFER',
            100000,
            NULL
        );

    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 24 FAILED: NULL status accepted';
    END IF;

    RAISE NOTICE
        'TEST 24 PASS: NULL status rejected';
END;
$$;

-- ============================================================
-- TEST 25: NULL PAYMENT REFERENCE
-- ============================================================

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.payment_attempts (
            order_id,
            payment_reference,
            payment_method,
            amount
        )
        VALUES (
            1,
            NULL,
            'BANK_TRANSFER',
            100000
        );

    EXCEPTION WHEN not_null_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION
            'TEST 25 FAILED: NULL reference accepted';
    END IF;

    RAISE NOTICE
        'TEST 25 PASS: NULL reference rejected';
END;
$$;

-- ============================================================
-- FINAL VERIFICATION
-- ============================================================

SELECT
    payment_attempt_id,
    order_id,
    payment_reference,
    payment_method,
    amount,
    payment_status,
    created_at,
    completed_at
FROM public.payment_attempts
ORDER BY payment_attempt_id;

-- ============================================================
-- ROLLBACK ALL TEST DATA
-- ============================================================

ROLLBACK;

-- ============================================================
-- VERIFY DATABASE AFTER ROLLBACK
-- ============================================================

SELECT
    payment_attempt_id,
    order_id,
    payment_reference,
    payment_status
FROM public.payment_attempts
ORDER BY payment_attempt_id;

-- ============================================================
-- END OF TEST FILE
-- ============================================================
