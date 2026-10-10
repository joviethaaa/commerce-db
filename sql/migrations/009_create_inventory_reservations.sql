
-- ============================================================
-- CommerceDB
-- Migration: 009_create_inventory_reservations.sql
-- Purpose: Track inventory allocations for order items
-- Target: PostgreSQL 18
-- ============================================================

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================

CREATE TABLE public.inventory_reservations (
    reservation_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_item_id BIGINT NOT NULL,
    inventory_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,

    reservation_status VARCHAR(20) NOT NULL
        DEFAULT 'ACTIVE',

    reserved_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    resolved_at TIMESTAMPTZ,

    -- Primary Key
    CONSTRAINT pk_inventory_reservations
        PRIMARY KEY (reservation_id),

    -- Foreign Key: Order Item
    CONSTRAINT fk_reservations_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES public.order_items(order_item_id)
        ON DELETE RESTRICT,

    -- Foreign Key: Inventory
    CONSTRAINT fk_reservations_inventory
        FOREIGN KEY (inventory_id)
        REFERENCES public.inventory(inventory_id)
        ON DELETE RESTRICT,

    -- Quantity must be positive
    CONSTRAINT ck_reservations_quantity
        CHECK (quantity > 0),

    -- Allowed reservation statuses
    CONSTRAINT ck_reservations_status
        CHECK (
            reservation_status IN (
                'ACTIVE',
                'RELEASED',
                'CONSUMED'
            )
        ),

    -- ACTIVE must not have resolved_at
    -- RELEASED / CONSUMED must have resolved_at
    CONSTRAINT ck_reservations_resolved
        CHECK (
            (
                reservation_status = 'ACTIVE'
                AND resolved_at IS NULL
            )
            OR
            (
                reservation_status IN (
                    'RELEASED',
                    'CONSUMED'
                )
                AND resolved_at IS NOT NULL
            )
        )
);

-- ============================================================
-- 2. FUNCTION: VALIDATE RESERVATION PRODUCT
-- ============================================================

-- Ensure the order item's product matches
-- the product associated with inventory.
-- Missing references are handled by Foreign Keys.

CREATE OR REPLACE FUNCTION public.validate_reservation_product()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_product_id BIGINT;
    v_inventory_product_id BIGINT;
BEGIN

    SELECT product_id
    INTO v_order_product_id
    FROM public.order_items
    WHERE order_item_id = NEW.order_item_id
    FOR SHARE;

    SELECT product_id
    INTO v_inventory_product_id
    FROM public.inventory
    WHERE inventory_id = NEW.inventory_id
    FOR SHARE;

    IF v_order_product_id IS NOT NULL
       AND v_inventory_product_id IS NOT NULL
       AND v_order_product_id <> v_inventory_product_id
    THEN
        RAISE EXCEPTION
            'Reservation product mismatch: order item product %, inventory product %',
            v_order_product_id,
            v_inventory_product_id
        USING ERRCODE = '23514';
    END IF;

    RETURN NEW;

END;
$$;

-- ============================================================
-- 3. FUNCTION: VALIDATE RESERVATION STATUS TRANSITION
-- ============================================================

-- Prevent resolved reservations from changing
-- their status or resolution timestamp.
--
-- Allowed:
-- ACTIVE -> RELEASED
-- ACTIVE -> CONSUMED
--
-- Disallowed:
-- RELEASED -> ACTIVE
-- RELEASED -> CONSUMED
-- CONSUMED -> ACTIVE
-- CONSUMED -> RELEASED

CREATE OR REPLACE FUNCTION public.validate_reservation_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.reservation_status IN (
        'RELEASED',
        'CONSUMED'
    )
    AND (
        NEW.reservation_status IS DISTINCT FROM
            OLD.reservation_status

        OR

        NEW.resolved_at IS DISTINCT FROM
            OLD.resolved_at
    )
    THEN
        RAISE EXCEPTION
            'Cannot change status or resolution time of a resolved reservation: %',
            OLD.reservation_id
        USING ERRCODE = '23514';
    END IF;

    RETURN NEW;

END;
$$;

-- ============================================================
-- 4. TRIGGER: VALIDATE RESERVATION PRODUCT
-- ============================================================

CREATE TRIGGER trg_validate_reservation_product
BEFORE INSERT OR UPDATE OF order_item_id, inventory_id
ON public.inventory_reservations
FOR EACH ROW
EXECUTE FUNCTION public.validate_reservation_product();

-- ============================================================
-- 5. TRIGGER: VALIDATE STATUS TRANSITION
-- ============================================================

CREATE TRIGGER trg_validate_reservation_status_transition
BEFORE UPDATE OF reservation_status, resolved_at
ON public.inventory_reservations
FOR EACH ROW
EXECUTE FUNCTION public.validate_reservation_status_transition();

-- ============================================================
-- END OF MIGRATION 009
-- ============================================================
