
-- =====================================================
-- CommerceDB
-- Migration: 004_create_products.sql
-- Purpose: Create product catalog table
-- Target: PostgreSQL 18
-- =====================================================

CREATE TABLE products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY,

    category_id BIGINT NOT NULL,

    sku VARCHAR(50) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,

    unit_price NUMERIC(15,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products
        PRIMARY KEY (product_id),

    CONSTRAINT uq_products_sku
        UNIQUE (sku),

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_products_unit_price
        CHECK (unit_price >= 0)
);
