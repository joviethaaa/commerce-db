
-- =====================================================
-- CommerceDB
-- Migration: 006_align_inventory_schema.sql
-- Purpose: Align inventory with logical design v1.1
-- Target: PostgreSQL 18
-- =====================================================

BEGIN;

ALTER TABLE inventory
    RENAME COLUMN quantity TO quantity_on_hand;

ALTER TABLE inventory
    RENAME CONSTRAINT ck_inventory_quantity
    TO ck_inventory_quantity_on_hand;

ALTER TABLE inventory
    ADD COLUMN quantity_reserved INTEGER NOT NULL DEFAULT 0;

ALTER TABLE inventory
    ADD CONSTRAINT ck_inventory_reserved_balance
    CHECK (
        quantity_reserved >= 0
        AND quantity_reserved <= quantity_on_hand
    );

COMMIT;
