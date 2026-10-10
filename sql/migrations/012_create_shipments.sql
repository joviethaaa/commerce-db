
-- ============================================================
-- CommerceDB
-- Migration: 012_create_shipments.sql
-- Purpose: Track shipment and delivery information
-- Target: PostgreSQL 18
-- ============================================================

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================

CREATE TABLE public.shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY,

    order_id BIGINT NOT NULL,

    tracking_number VARCHAR(100),
    courier_name VARCHAR(100) NOT NULL,
    shipment_status VARCHAR(30) NOT NULL
        DEFAULT 'PENDING',

    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_shipments
        PRIMARY KEY (shipment_id),

    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES public.orders(order_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_shipments_tracking_number
        UNIQUE (tracking_number),

    CONSTRAINT ck_shipments_status
        CHECK (
            shipment_status IN (
                'PENDING',
                'SHIPPED',
                'DELIVERED',
                'CANCELLED'
            )
        ),

    CONSTRAINT ck_shipments_timestamps
        CHECK (
            (
                shipment_status = 'PENDING'
                AND shipped_at IS NULL
                AND delivered_at IS NULL
            )
            OR
            (
                shipment_status = 'SHIPPED'
                AND shipped_at IS NOT NULL
                AND delivered_at IS NULL
            )
            OR
            (
                shipment_status = 'DELIVERED'
                AND shipped_at IS NOT NULL
                AND delivered_at IS NOT NULL
                AND delivered_at >= shipped_at
            )
            OR
            (
                shipment_status = 'CANCELLED'
                AND delivered_at IS NULL
            )
        )
);

-- ============================================================
-- 2. PARTIAL UNIQUE INDEX
-- ============================================================

-- At most one active shipment per order.

CREATE UNIQUE INDEX uq_shipments_one_active_per_order
ON public.shipments (order_id)
WHERE shipment_status IN ('PENDING', 'SHIPPED');

-- ============================================================
-- 3. PERFORMANCE INDEX
-- ============================================================

CREATE INDEX idx_shipments_order_created
ON public.shipments (
    order_id,
    created_at DESC
);

-- ============================================================
-- 4. FUNCTION: VALIDATE STATUS TRANSITION
-- ============================================================

CREATE OR REPLACE FUNCTION public.validate_shipment_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    -- DELIVERED and CANCELLED are final statuses.
    IF OLD.shipment_status IN ('DELIVERED', 'CANCELLED')
       AND (
           NEW.shipment_status IS DISTINCT FROM OLD.shipment_status
           OR NEW.shipped_at IS DISTINCT FROM OLD.shipped_at
           OR NEW.delivered_at IS DISTINCT FROM OLD.delivered_at
       )
    THEN
        RAISE EXCEPTION
            'Cannot change status or timestamps of finalized shipment: %',
            OLD.shipment_id
        USING ERRCODE = '23514';
    END IF;

    -- SHIPPED cannot return to PENDING.
    IF OLD.shipment_status = 'SHIPPED'
       AND NEW.shipment_status = 'PENDING'
    THEN
        RAISE EXCEPTION
            'Cannot revert shipped shipment to PENDING: %',
            OLD.shipment_id
        USING ERRCODE = '23514';
    END IF;

    RETURN NEW;

END;
$$;

-- ============================================================
-- 5. TRIGGER: VALIDATE STATUS TRANSITION
-- ============================================================

CREATE TRIGGER trg_validate_shipment_status_transition
BEFORE UPDATE OF shipment_status, shipped_at, delivered_at
ON public.shipments
FOR EACH ROW
EXECUTE FUNCTION public.validate_shipment_status_transition();

-- ============================================================
-- END OF MIGRATION 012
-- ============================================================
