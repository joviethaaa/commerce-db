# CommerceDB — Database Requirements Specification

**Document ID:** CDB-SRS-001  
**Version:** 1.1  
**Status:** Requirements Baseline  
**Project:** Enterprise E-Commerce Database Design & Optimization  
**Target DBMS:** PostgreSQL 18

---

## 1. Project Overview

CommerceDB is a database engineering portfolio project that simulates the transactional infrastructure of a single-vendor e-commerce company.

The project focuses on relational database design, data integrity, transaction consistency, concurrency control, query optimization, and database reliability.

CommerceDB is developed as an engineering simulation rather than a production e-commerce service.

## 2. Problem Statement

E-commerce platforms must manage interconnected customer, product, inventory, order, payment, and shipping information.

Poor database design may result in:

- Inconsistent transactional records.
- Duplicate or redundant information.
- Inventory overselling during concurrent purchases.
- Incorrect historical order prices.
- Payment processing inconsistencies.
- Slow database queries as data volume increases.
- Difficulties recovering from database failures.

CommerceDB aims to address these challenges through structured relational modeling, database constraints, transaction management, and measurable performance testing.

## 3. Project Objectives

The primary objectives are:

1. Design a relational database targeting Third Normal Form (3NF).
2. Implement primary keys, foreign keys, and integrity constraints.
3. Support core e-commerce transactional operations.
4. Prevent inventory overselling under concurrent transactions.
5. Maintain accurate historical transaction records.
6. Evaluate query performance using representative workloads.
7. Implement database security and recovery mechanisms.
8. Document engineering decisions and reproducible test results.

## 4. Business Scope

CommerceDB represents a single-vendor e-commerce company operating one warehouse.

### In Scope

- Customer information management.
- Customer address management.
- Product catalog and categories.
- Order processing and order items.
- Inventory balances and reservations.
- Payment attempt tracking.
- Shipping and delivery records.
- Order status history.
- Referential and transactional integrity.
- SQL performance benchmarking.
- Database backup and recovery testing.

### Out of Scope

- Multi-vendor marketplace operations.
- Multi-warehouse inventory management.
- Live payment gateway integration.
- Product recommendation systems.
- Native mobile applications.
- Post-payment refunds and returns.

## 5. Stakeholders

| Stakeholder | Responsibility |
|---|---|
| Customer | Places orders and manages account information |
| Operations Staff | Manages order fulfillment |
| Inventory Staff | Maintains stock records |
| Finance Staff | Reviews payment records |
| Database Engineer | Designs, maintains, and optimizes the database |
| Management | Reviews operational and sales information |

## 6. Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | Manage customer information | Must |
| FR-002 | Manage product catalog and categories | Must |
| FR-003 | Record orders and associated order items | Must |
| FR-004 | Maintain inventory balances and reservations | Must |
| FR-005 | Track payment attempts and payment statuses | Must |
| FR-006 | Record shipments and shipping statuses | Must |
| FR-007 | Maintain order status history | Must |
| FR-008 | Support sales and transaction reporting | Should |
| FR-009 | Support auditing of critical data changes | Should |

## 7. Non-Functional Requirements

| ID | Category | Initial Acceptance Target |
|---|---|---|
| NFR-001 | Performance | p95 order lookup latency ≤100 ms under a documented benchmark workload |
| NFR-002 | Scalability | Evaluate workloads containing up to 1 million synthetic orders |
| NFR-003 | Integrity | Enforce appropriate relational and domain constraints |
| NFR-004 | Concurrency | Prevent overselling under tested concurrent checkout scenarios |
| NFR-005 | Security | Implement database roles with least-privilege access |
| NFR-006 | Reliability | Verify successful database backup and restoration |
| NFR-007 | Maintainability | Maintain version-controlled database migrations and documentation |

These figures represent engineering targets. No performance benchmark results are claimed at this stage.

## 8. Business Rules

### Customer and Order Management

- **BR-001:** Each order belongs to exactly one customer.
- **BR-002:** Each confirmed order contains at least one order item.
- **BR-003:** The same product may appear only once within a particular order; quantities are combined.
- **BR-004:** Historical order item prices remain unchanged when catalog prices are updated.
- **BR-005:** Each order preserves its shipping address as a historical snapshot.

### Inventory Management

- **BR-006:** Available inventory equals physical on-hand inventory minus reserved inventory.
- **BR-007:** Available inventory must not become negative.
- **BR-008:** Inventory reservations must be performed atomically.
- **BR-009:** Cancellation or expiry releases active stock reservations exactly once.
- **BR-010:** Physical stock is reduced when reserved goods are shipped.
- **BR-011:** Shipped inventory is not automatically restored through order cancellation.

### Payment Management

- **BR-012:** An order may contain multiple payment attempts.
- **BR-013:** At most one payment attempt per order may be successful.
- **BR-014:** Payment confirmation must validate the order state and payable amount.
- **BR-015:** Failed payments may be retried while the order remains eligible for payment.

### Fulfillment Management

- **BR-016:** Shipments can only be created for successfully paid orders.
- **BR-017:** At most one shipment may be active per order in version 1.
- **BR-018:** Order and shipping histories must be preserved.

### Order Lifecycle

- **BR-019:** Normal order progression is PENDING_PAYMENT → PAID → PROCESSING → SHIPPED → DELIVERED.
- **BR-020:** Unpaid orders may transition to CANCELLED or EXPIRED.
- **BR-021:** Post-payment cancellation and refund workflows are excluded from version 1.
- **BR-022:** Terminal order states cannot be modified through ordinary order processing.

## 9. Candidate Database Entities

CommerceDB includes 12 core entities:

1. customers
2. customer_addresses
3. categories
4. products
5. inventory
6. inventory_reservations
7. inventory_movements
8. orders
9. order_items
10. payment_attempts
11. shipments
12. order_status_history

The entity relationships, attributes, and constraints are described in `02-database-design.md`.

## 10. Assumptions and Constraints

- One company manages the complete product catalog.
- One warehouse maintains physical product inventory.
- All transactions use Indonesian Rupiah (IDR).
- Each managed product has one inventory balance record.
- Customer addresses may change without modifying historical order addresses.
- Payment outcomes are simulated.
- The application uses synthetic customer and transaction data.
- The project uses PostgreSQL as its primary database system.
- Database behavior must be testable independently of a graphical user interface.

## 11. Preliminary Acceptance Criteria

| ID | Acceptance Criteria |
|---|---|
| AC-001 | Invalid foreign key references are rejected |
| AC-002 | Duplicate restricted business identifiers are rejected |
| AC-003 | Historical order prices remain unchanged |
| AC-004 | Concurrent checkout cannot reserve more inventory than available |
| AC-005 | Repeated cancellation does not release inventory twice |
| AC-006 | Multiple successful payment attempts for one order are rejected |
| AC-007 | Shipment creation before successful payment is rejected |
| AC-008 | Backup and restore procedures pass verification |
| AC-009 | Performance results are measured and reproducible |

## 12. Planned Deliverables

- Requirements Specification.
- Logical Database Design and ERD.
- Design Validation Report.
- PostgreSQL Database Migrations.
- Integrity and Concurrency Tests.
- Synthetic Data Generation.
- Query Performance Benchmarks.
- Backup and Recovery Documentation.
- GitHub Portfolio Documentation.

## 13. Current Project Status

The local PostgreSQL development environment has been configured and verified using Docker, psql, and DBeaver.

The physical business schema, concurrency tests, and performance benchmarks have not yet been implemented.

---

**Next Document:** CDB-DDD-002 — Conceptual & Logical Database Design.