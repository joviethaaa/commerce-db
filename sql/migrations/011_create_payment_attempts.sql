
-- ============================================================
-- CommerceDB
-- Migration: 011_create_payment_attempts.sql
-- Purpose: Track payment attempts and their outcomes
-- Target: PostgreSQL 18
-- ============================================================

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================

CREATE TABLE public.payment_attempts (
    payment_attempt_id BIGINT GENERATED ALWAYS AS IDENTITY,

    order_id BIGINT NOT NULL,

    payment_reference VARCHAR(100) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,

    amount NUMERIC(15,2) NOT NULL,

    payment_status VARCHAR(20) NOT NULL
        DEFAULT 'PENDING',

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    completed_at TIMESTAMPTZ,

    -- Primary Key
    CONSTRAINT pk_payment_attempts
        PRIMARY KEY (payment_attempt_id),

    -- Foreign Key: Order
    CONSTRAINT fk_payment_attempts_order
        FOREIGN KEY (order_id)
        REFERENCES public.orders(order_id)
        ON DELETE RESTRICT,

    -- Payment reference must be unique
    CONSTRAINT uq_payment_attempts_reference
        UNIQUE (payment_reference),

    -- Payment amount must be positive
    CONSTRAINT ck_payment_attempts_amount
        CHECK (amount > 0),

    -- Allowed payment statuses
    CONSTRAINT ck_payment_attempts_status
        CHECK (
            payment_status IN (
                'PENDING',
                'SUCCESS',
                'FAILED',
                'CANCELLED'
            )
        ),

    -- PENDING must not have completed_at.
    -- Finalized payments must have completed_at.
    CONSTRAINT ck_payment_attempts_completed
        CHECK (
            (
                payment_status = 'PENDING'
                AND completed_at IS NULL
            )
            OR
            (
                payment_status IN (
                    'SUCCESS',
                    'FAILED',
                    'CANCELLED'
                )
                AND completed_at IS NOT NULL
            )
        )
);

-- ============================================================
-- 2. PARTIAL UNIQUE INDEX
-- ============================================================

-- An order may have multiple payment attempts,
-- but at most one payment with SUCCESS status.

CREATE UNIQUE INDEX uq_payment_attempts_one_success
ON public.payment_attempts (order_id)
WHERE payment_status = 'SUCCESS';

-- ============================================================
-- 3. PERFORMANCE INDEX
-- ============================================================

-- Optimize payment attempt history by order.

CREATE INDEX idx_payment_attempts_order_created
ON public.payment_attempts (
    order_id,
    created_at DESC
);

-- ============================================================
-- 4. FUNCTION: VALIDATE PAYMENT STATUS TRANSITION
-- ============================================================

-- Allowed:
-- PENDING -> SUCCESS
-- PENDING -> FAILED
-- PENDING -> CANCELLED
--
-- Disallowed:
-- SUCCESS -> PENDING / FAILED / CANCELLED
-- FAILED -> PENDING / SUCCESS / CANCELLED
-- CANCELLED -> PENDING / SUCCESS / FAILED
--
-- Finalized payment status and completed_at
-- cannot be modified.

CREATE OR REPLACE FUNCTION public.validate_payment_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.payment_status IN (
        'SUCCESS',
        'FAILED',
        'CANCELLED'
    )
    AND (
        NEW.payment_status IS DISTINCT FROM OLD.payment_status
        OR NEW.completed_at IS DISTINCT FROM OLD.completed_at
    )
    THEN
        RAISE EXCEPTION
            'Cannot change status or completion time of a finalized payment: %',
            OLD.payment_attempt_id
        USING ERRCODE = '23514';
    END IF;

    RETURN NEW;

END;
$$;

-- ============================================================
-- 5. TRIGGER: VALIDATE PAYMENT STATUS TRANSITION
-- ============================================================

CREATE TRIGGER trg_validate_payment_status_transition
BEFORE UPDATE OF payment_status, completed_at
ON public.payment_attempts
FOR EACH ROW
EXECUTE FUNCTION public.validate_payment_status_transition();

-- ============================================================
-- END OF MIGRATION 011
-- ============================================================
