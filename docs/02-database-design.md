# CommerceDB — Conceptual & Logical Database Design

**Document ID:** CDB-DDD-002  
**Version:** 1.1  
**Status:** Logical Design Baseline  
**Project:** CommerceDB Enterprise E-Commerce Database System  
**Target DBMS:** PostgreSQL 18

---

## 1. Introduction

This document describes the conceptual and logical relational database design for CommerceDB.

The design is based on the requirements defined in `01-requirements.md` and supports a single-vendor e-commerce platform operating one warehouse.

The primary design objectives are:

- Establish clear entity responsibilities.
- Define primary and foreign key relationships.
- Preserve transactional history.
- Support referential and domain integrity.
- Provide a foundation for concurrency-safe inventory operations.
- Target Third Normal Form (3NF).
- Prepare for PostgreSQL physical schema implementation.

## 2. Database Domains

CommerceDB consists of 12 core entities divided into six domains.

| Domain | Entities |
|---|---|
| Customer | customers, customer_addresses |
| Catalog | categories, products |
| Order | orders, order_items, order_status_history |
| Inventory | inventory, inventory_reservations, inventory_movements |
| Payment | payment_attempts |
| Fulfillment | shipments |

## 3. Naming Conventions

- Table names use plural nouns.
- Column names follow snake_case.
- Primary keys generally use the pattern `entity_id`.
- Foreign keys reference stable primary keys.
- Monetary values use exact decimal types.
- Timestamp attributes use timezone-aware timestamps.
- Business identifiers such as SKU and order number must be unique.

## 4. Logical Data Dictionary

The following attributes describe the proposed logical schema. Data types represent preliminary PostgreSQL implementation choices.

### 4.1 customers

**Purpose:** Store registered customer information.

| Attribute | Type | Constraint |
|---|---|---|
| customer_id | BIGINT | PK |
| full_name | VARCHAR(150) | NOT NULL |
| email | VARCHAR(254) | UNIQUE, NOT NULL |
| phone_number | VARCHAR(25) | NULL |
| created_at | TIMESTAMPTZ | NOT NULL |
| updated_at | TIMESTAMPTZ | NOT NULL |

### 4.2 customer_addresses

**Purpose:** Store customer-managed delivery addresses.

| Attribute | Type | Constraint |
|---|---|---|
| address_id | BIGINT | PK |
| customer_id | BIGINT | FK → customers |
| recipient_name | VARCHAR(150) | NOT NULL |
| phone_number | VARCHAR(25) | NOT NULL |
| street_address | TEXT | NOT NULL |
| city | VARCHAR(100) | NOT NULL |
| province | VARCHAR(100) | NOT NULL |
| postal_code | VARCHAR(20) | NOT NULL |
| is_default | BOOLEAN | NOT NULL |

Each customer may have multiple addresses. A business rule may restrict a customer to one default address.

### 4.3 categories

**Purpose:** Organize products into categories.

| Attribute | Type | Constraint |
|---|---|---|
| category_id | BIGINT | PK |
| category_name | VARCHAR(100) | UNIQUE, NOT NULL |
| description | TEXT | NULL |
| is_active | BOOLEAN | NOT NULL |

### 4.4 products

**Purpose:** Store product catalog information and current selling prices.

| Attribute | Type | Constraint |
|---|---|---|
| product_id | BIGINT | PK |
| category_id | BIGINT | FK → categories |
| sku | VARCHAR(50) | UNIQUE, NOT NULL |
| product_name | VARCHAR(200) | NOT NULL |
| description | TEXT | NULL |
| unit_price | NUMERIC(15,2) | NOT NULL, ≥ 0 |
| is_active | BOOLEAN | NOT NULL |
| created_at | TIMESTAMPTZ | NOT NULL |
| updated_at | TIMESTAMPTZ | NOT NULL |

### 4.5 inventory

**Purpose:** Maintain physical and reserved inventory balances.

| Attribute | Type | Constraint |
|---|---|---|
| inventory_id | BIGINT | PK |
| product_id | BIGINT | FK → products, UNIQUE |
| quantity_on_hand | INTEGER | NOT NULL, ≥ 0 |
| quantity_reserved | INTEGER | NOT NULL, ≥ 0 |
| updated_at | TIMESTAMPTZ | NOT NULL |

Inventory invariant:

`0 ≤ quantity_reserved ≤ quantity_on_hand`

Available inventory is calculated as:

`quantity_on_hand - quantity_reserved`

### 4.6 orders

**Purpose:** Store order-level information and immutable shipping address snapshots.

| Attribute | Type | Constraint |
|---|---|---|
| order_id | BIGINT | PK |
| customer_id | BIGINT | FK → customers |
| order_number | VARCHAR(40) | UNIQUE, NOT NULL |
| order_status | VARCHAR(30) | NOT NULL |
| recipient_name | VARCHAR(150) | NOT NULL |
| shipping_phone | VARCHAR(25) | NOT NULL |
| shipping_street | TEXT | NOT NULL |
| shipping_city | VARCHAR(100) | NOT NULL |
| shipping_province | VARCHAR(100) | NOT NULL |
| shipping_postal_code | VARCHAR(20) | NOT NULL |
| shipping_fee | NUMERIC(15,2) | NOT NULL, ≥ 0 |
| created_at | TIMESTAMPTZ | NOT NULL |
| updated_at | TIMESTAMPTZ | NOT NULL |

Shipping address attributes represent historical order information and must not be automatically updated when a customer's saved address changes.

### 4.7 order_items

**Purpose:** Store purchased products and historical unit prices.

| Attribute | Type | Constraint |
|---|---|---|
| order_item_id | BIGINT | PK |
| order_id | BIGINT | FK → orders |
| product_id | BIGINT | FK → products |
| quantity | INTEGER | NOT NULL, > 0 |
| unit_price | NUMERIC(15,2) | NOT NULL, ≥ 0 |
| created_at | TIMESTAMPTZ | NOT NULL |

Additional candidate key:

`UNIQUE(order_id, product_id)`

The unit price must remain independent of subsequent catalog price updates.

### 4.8 order_status_history

**Purpose:** Record order state transitions.

| Attribute | Type | Constraint |
|---|---|---|
| history_id | BIGINT | PK |
| order_id | BIGINT | FK → orders |
| old_status | VARCHAR(30) | NULL for initial event |
| new_status | VARCHAR(30) | NOT NULL |
| changed_at | TIMESTAMPTZ | NOT NULL |
| change_reason | TEXT | NULL |

### 4.9 inventory_reservations

**Purpose:** Track inventory allocations for order items.

| Attribute | Type | Constraint |
|---|---|---|
| reservation_id | BIGINT | PK |
| order_item_id | BIGINT | FK → order_items |
| inventory_id | BIGINT | FK → inventory |
| quantity | INTEGER | NOT NULL, > 0 |
| reservation_status | VARCHAR(20) | NOT NULL |
| reserved_at | TIMESTAMPTZ | NOT NULL |
| resolved_at | TIMESTAMPTZ | NULL |

Reservation statuses:

- ACTIVE
- RELEASED
- CONSUMED

A reservation must refer to the same product as its associated order item.

### 4.10 inventory_movements

**Purpose:** Record physical changes in inventory.

| Attribute | Type | Constraint |
|---|---|---|
| movement_id | BIGINT | PK |
| inventory_id | BIGINT | FK → inventory |
| reservation_id | BIGINT | Nullable FK → inventory_reservations |
| movement_type | VARCHAR(30) | NOT NULL |
| quantity_change | INTEGER | NOT NULL, nonzero |
| occurred_at | TIMESTAMPTZ | NOT NULL |
| notes | TEXT | NULL |

Inventory movements record changes in physical stock. Reservation and release operations modify reserved balances without automatically changing physical stock.

### 4.11 payment_attempts

**Purpose:** Record payment attempts and their outcomes.

| Attribute | Type | Constraint |
|---|---|---|
| payment_attempt_id | BIGINT | PK |
| order_id | BIGINT | FK → orders |
| payment_reference | VARCHAR(100) | UNIQUE, NOT NULL |
| payment_method | VARCHAR(30) | NOT NULL |
| amount | NUMERIC(15,2) | NOT NULL, > 0 |
| payment_status | VARCHAR(20) | NOT NULL |
| created_at | TIMESTAMPTZ | NOT NULL |
| completed_at | TIMESTAMPTZ | NULL |

Payment statuses:

- PENDING
- SUCCESS
- FAILED
- CANCELLED

A single order may have multiple payment attempts, but no more than one successful payment attempt.

### 4.12 shipments

**Purpose:** Store shipping and delivery information.

| Attribute | Type | Constraint |
|---|---|---|
| shipment_id | BIGINT | PK |
| order_id | BIGINT | FK → orders |
| tracking_number | VARCHAR(100) | UNIQUE when present |
| courier_name | VARCHAR(100) | NOT NULL |
| shipment_status | VARCHAR(30) | NOT NULL |
| shipped_at | TIMESTAMPTZ | NULL |
| delivered_at | TIMESTAMPTZ | NULL |
| created_at | TIMESTAMPTZ | NOT NULL |

At most one shipment may be active per order.

## 5. Relationship Matrix

| Parent | Child | Cardinality |
|---|---|---|
| customers | customer_addresses | 1 : 0..N |
| customers | orders | 1 : 0..N |
| categories | products | 1 : 0..N |
| products | inventory | 1 : 1 for managed products |
| orders | order_items | 1 : 1..N for confirmed orders |
| products | order_items | 1 : 0..N |
| orders | order_status_history | 1 : 1..N after creation |
| orders | payment_attempts | 1 : 0..N |
| orders | shipments | 1 : 0..N historically |
| order_items | inventory_reservations | 1 : 0..N |
| inventory | inventory_reservations | 1 : 0..N |
| inventory | inventory_movements | 1 : 0..N |
| inventory_reservations | inventory_movements | 1 : 0..N when referenced |

Minimum-cardinality and conditional-uniqueness rules must be enforced through appropriate database constraints and transaction logic.

## 6. Key Design Decisions

### 6.1 Surrogate Primary Keys

Core entities use stable surrogate identifiers to avoid dependence on mutable business attributes.

### 6.2 Many-to-Many Relationship Resolution

The many-to-many relationship between orders and products is represented through order_items.

### 6.3 Historical Pricing

order_items stores the price applied to an order independently of products.unit_price.

### 6.4 Inventory Consistency

Physical balances, reserved balances, reservation records, and inventory movements are managed separately.

Critical balance changes must occur within atomic transactions.

### 6.5 Order Address Snapshots

Delivery information is copied to orders so historical shipments remain accurate when customer addresses change.

### 6.6 Payment Integrity

Conditional uniqueness must prevent more than one successful payment attempt per order.

### 6.7 Shipment Integrity

An order may have shipment history, but only one shipment may be active at a time.

## 7. Normalization Strategy

The logical database model targets Third Normal Form (3NF).

Key normalization considerations include:

- Customer information is separated from order headers.
- Product catalog attributes are separated from order items.
- Product categories are stored independently.
- Transaction-specific prices are preserved as historical facts.
- Inventory reservations and movements are represented as distinct business records.

A formal normalization review must examine candidate keys and functional dependencies before the design is considered fully validated.

## 8. Integrity Strategy

The implementation will use:

- Primary keys.
- Foreign keys.
- Unique constraints.
- Check constraints.
- Controlled status values.
- Conditional uniqueness.
- Atomic transactions.
- Appropriate referential actions.
- Restricted access to historical records.

## 9. Remaining Physical Design Decisions

The following require validation before implementation is finalized:

1. Exact identity-generation strategy.
2. Foreign key deletion and update policies.
3. Default-address uniqueness enforcement.
4. Payment amount calculation and reconciliation.
5. Status transition enforcement.
6. Inventory reservation consistency.
7. Shipment state and active-shipment definition.
8. Enforcement of minimum order item cardinality.
9. Index selection based on real workload patterns.
10. Formal functional dependency review.

## 10. Next Document

**CDB-DVR-001 — Database Design Validation Report**

The next document defines final business-state decisions, expected transaction behavior, and acceptance tests before physical schema implementation.