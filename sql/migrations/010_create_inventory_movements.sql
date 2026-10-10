
-- ============================================================
-- CommerceDB
-- Migration: 010_create_inventory_movements.sql
-- Purpose: Record physical inventory stock changes
-- Target: PostgreSQL 18
-- ============================================================

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================

CREATE TABLE public.inventory_movements (
    movement_id BIGINT GENERATED ALWAYS AS IDENTITY,

    inventory_id BIGINT NOT NULL,
    reservation_id BIGINT,

    movement_type VARCHAR(30) NOT NULL,
    quantity_change INTEGER NOT NULL,

    occurred_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    notes TEXT,

    -- Primary Key
    CONSTRAINT pk_inventory_movements
        PRIMARY KEY (movement_id),

    -- Foreign Key: Inventory
    CONSTRAINT fk_movements_inventory
        FOREIGN KEY (inventory_id)
        REFERENCES public.inventory(inventory_id)
        ON DELETE RESTRICT,

    -- Foreign Key: Reservation (optional)
    CONSTRAINT fk_movements_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES public.inventory_reservations(reservation_id)
        ON DELETE RESTRICT,

    -- Allowed movement types
    CONSTRAINT ck_movements_type
        CHECK (
            movement_type IN (
                'STOCK_IN',
                'STOCK_OUT',
                'ADJUSTMENT'
            )
        ),

    -- Every movement must change physical stock
    CONSTRAINT ck_movements_quantity_nonzero
        CHECK (quantity_change <> 0),

    -- STOCK_IN increases stock.
    -- STOCK_OUT decreases stock.
    -- ADJUSTMENT may increase or decrease stock.
    CONSTRAINT ck_movements_direction
        CHECK (
            (movement_type = 'STOCK_IN'
                AND quantity_change > 0)
            OR
            (movement_type = 'STOCK_OUT'
                AND quantity_change < 0)
            OR
            (movement_type = 'ADJUSTMENT'
                AND quantity_change <> 0)
        )
);

-- ============================================================
-- 2. FUNCTION: VALIDATE MOVEMENT RESERVATION
-- ============================================================

-- When reservation_id is provided, it must belong
-- to the same inventory_id as the movement.
--
-- Missing references are handled by Foreign Keys.

CREATE OR REPLACE FUNCTION public.validate_movement_reservation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_reservation_inventory_id BIGINT;
BEGIN

    IF NEW.reservation_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT inventory_id
    INTO v_reservation_inventory_id
    FROM public.inventory_reservations
    WHERE reservation_id = NEW.reservation_id
    FOR SHARE;

    IF v_reservation_inventory_id IS NOT NULL
       AND v_reservation_inventory_id <> NEW.inventory_id
    THEN
        RAISE EXCEPTION
            'Movement inventory mismatch: reservation inventory %, movement inventory %',
            v_reservation_inventory_id,
            NEW.inventory_id
        USING ERRCODE = '23514';
    END IF;

    RETURN NEW;

END;
$$;

-- ============================================================
-- 3. TRIGGER: VALIDATE MOVEMENT RESERVATION
-- ============================================================

CREATE TRIGGER trg_validate_movement_reservation
BEFORE INSERT OR UPDATE OF inventory_id, reservation_id
ON public.inventory_movements
FOR EACH ROW
EXECUTE FUNCTION public.validate_movement_reservation();

-- ============================================================
-- 4. INDEXES
-- ============================================================

-- Speed up inventory movement history queries.
CREATE INDEX idx_movements_inventory_occurred
ON public.inventory_movements (
    inventory_id,
    occurred_at DESC
);

-- Speed up reservation-based movement lookup.
CREATE INDEX idx_movements_reservation
ON public.inventory_movements (reservation_id)
WHERE reservation_id IS NOT NULL;

-- ============================================================
-- END OF MIGRATION 010
-- ============================================================
