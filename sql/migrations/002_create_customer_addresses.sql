
-- =====================================================
-- CommerceDB
-- Migration: 002_create_customer_addresses.sql
-- Purpose: Create customer addresses table
-- Target: PostgreSQL 18
-- =====================================================

CREATE TABLE customer_addresses (
    address_id BIGINT GENERATED ALWAYS AS IDENTITY,

    customer_id BIGINT NOT NULL,

    recipient_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(25) NOT NULL,

    street_address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,

    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_customer_addresses
        PRIMARY KEY (address_id),

    CONSTRAINT fk_customer_addresses_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT
);
