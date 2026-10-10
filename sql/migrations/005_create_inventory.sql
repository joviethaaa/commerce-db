
-- =====================================================
-- CommerceDB
-- Migration: 005_create_inventory.sql
-- Purpose: Create product inventory table
-- Target: PostgreSQL 18
-- =====================================================

CREATE TABLE inventory (
    inventory_id BIGINT GENERATED ALWAYS AS IDENTITY,

    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory
        PRIMARY KEY (inventory_id),

    CONSTRAINT uq_inventory_product
        UNIQUE (product_id),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_inventory_quantity
        CHECK (quantity >= 0)
);
