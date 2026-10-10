
-- =====================================================
-- CommerceDB
-- Migration: 007_create_orders.sql
-- Purpose: Create orders with shipping snapshots
-- Target: PostgreSQL 18
-- =====================================================

CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY,

    customer_id BIGINT NOT NULL,

    order_number VARCHAR(40) NOT NULL,

    order_status VARCHAR(30) NOT NULL,

    recipient_name VARCHAR(150) NOT NULL,
    shipping_phone VARCHAR(25) NOT NULL,
    shipping_street TEXT NOT NULL,
    shipping_city VARCHAR(100) NOT NULL,
    shipping_province VARCHAR(100) NOT NULL,
    shipping_postal_code VARCHAR(20) NOT NULL,

    shipping_fee NUMERIC(15,2) NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_orders
        PRIMARY KEY (order_id),

    CONSTRAINT uq_orders_number
        UNIQUE (order_number),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_orders_shipping_fee
        CHECK (shipping_fee >= 0)
);
