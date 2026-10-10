
-- =====================================================
-- CommerceDB
-- Migration: 003_create_categories.sql
-- Purpose: Create product categories master table
-- Target: PostgreSQL 18
-- =====================================================

CREATE TABLE categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY,

    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_categories
        PRIMARY KEY (category_id),

    CONSTRAINT uq_categories_name
        UNIQUE (category_name)
);
