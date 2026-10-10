# CommerceDB — Database Design Validation Report

**Document ID:** CDB-DVR-001  
**Version:** 1.1  
**Status:** Design Review Baseline — Pending Implementation Validation  
**Project:** CommerceDB Enterprise E-Commerce Database System  
**Target DBMS:** PostgreSQL 18

---

## 1. Introduction

This document records the design validation strategy for CommerceDB, a simulated single-vendor e-commerce database operating with one warehouse.

The purpose of this review is to evaluate whether the proposed logical database model addresses the requirements documented in `01-requirements.md` and the entity structure defined in `02-database-design.md`.

This document defines expected behavior and planned validation procedures. It does not claim that physical database tests have been completed.

## 2. Validation Objectives

The database design must:

1. Maintain referential integrity across related entities.
2. Prevent invalid and inconsistent business data.
3. Preserve historical transaction information.
4. Support concurrent order processing without inventory overselling.
5. Prevent duplicate successful payments.
6. Maintain correct inventory reservations and physical stock balances.
7. Enforce valid order and shipment transitions.
8. Support future SQL performance evaluation.
9. Provide a foundation for database security and recovery testing.

## 3. Order Lifecycle Validation

The approved version 1 order lifecycle is:

PENDING_PAYMENT → PAID → PROCESSING → SHIPPED → DELIVERED

Unpaid orders may transition to CANCELLED or EXPIRED.

| Current Status | Allowed Next Status |
|---|---|
| PENDING_PAYMENT | PAID, CANCELLED, EXPIRED |
| PAID | PROCESSING |
| PROCESSING | SHIPPED |
| SHIPPED | DELIVERED |
| DELIVERED | None |
| CANCELLED | None |
| EXPIRED | None |

Post-payment cancellations, returns, and refunds are outside the scope of version 1.

### Validation Criteria

- Invalid state transitions must be rejected.
- Initial order creation must be recorded in order_status_history.
- Each valid status transition must produce a corresponding history record.
- Terminal states must not transition to another state through normal order processing.
- Order status changes and their history records must remain transactionally consistent.

## 4. Inventory Consistency Validation

CommerceDB uses two operational inventory balances:

- quantity_on_hand: Physical inventory still held by the warehouse.
- quantity_reserved: Inventory allocated to orders but not yet shipped.

Available inventory is derived as:

`available_stock = quantity_on_hand - quantity_reserved`

Required invariants:

- quantity_on_hand ≥ 0
- quantity_reserved ≥ 0
- quantity_reserved ≤ quantity_on_hand

### Inventory Operations

| Operation | On Hand | Reserved |
|---|---|---|
| Receive stock | Increase | Unchanged |
| Reserve stock during checkout | Unchanged | Increase |
| Payment retry | Unchanged | Unchanged |
| Cancel or expire unpaid order | Unchanged | Decrease |
| Ship reserved items | Decrease | Decrease |

### Concurrency Requirements

- Concurrent checkout operations must not reserve more inventory than available.
- Reservation and inventory balance changes must be atomic.
- The inventory record must correspond to the product referenced by the order item.
- Repeated cancellation must not release inventory more than once.
- Shipment must consume the relevant active inventory reservation only once.
- Physical stock changes must have corresponding inventory movement records.
- Inventory movement records must remain consistent with physical stock balances.

## 5. Payment Integrity Validation

CommerceDB stores payment attempts independently from orders.

A single order may have multiple payment attempts with statuses:

- PENDING
- SUCCESS
- FAILED
- CANCELLED

### Payment Rules

- Multiple failed attempts are allowed.
- At most one successful payment attempt may exist per order.
- Successful payment requires a valid PENDING_PAYMENT order.
- The payment amount must match the order's payable amount.
- Payment confirmation and order status updates must be handled consistently.
- Repeated payment notifications must not cause duplicated successful processing.

### Planned Enforcement

- Foreign key referencing orders.
- Unique payment reference.
- Conditional uniqueness for successful payments.
- Transactional payment confirmation.
- Idempotent processing of repeated payment events.

## 6. Historical Data Validation

CommerceDB must preserve historical transaction information.

### Order Pricing

The unit_price stored in order_items represents the price used during checkout.

Changing products.unit_price must not modify previously recorded order item prices.

### Shipping Address

Order shipping information is stored as a historical snapshot.

Updates to customer_addresses must not alter shipping information saved in existing orders.

### Order History

Order state transitions must remain traceable through order_status_history.

## 7. Shipment Validation

Shipment records are associated with orders.

Version 1 requirements:

- A shipment may only be created for an order with successful payment.
- An order may retain multiple historical shipment records.
- At most one shipment may be active for an order.
- Shipping status transitions must follow a defined lifecycle.
- Shipment creation and reservation consumption must be transactionally consistent.

The exact definition of active shipment statuses will be finalized during physical implementation design.

## 8. Referential Integrity Validation

The database must reject invalid relationships.

Examples include:

- An order referencing a nonexistent customer.
- An order item referencing a nonexistent product.
- A payment attempt referencing a nonexistent order.
- An inventory reservation referencing an invalid order item.
- A shipment referencing a nonexistent order.

Historical transactional records must be protected against accidental deletion.

## 9. Normalization Review

The logical database design targets Third Normal Form (3NF).

The review focuses on:

- Candidate keys and functional dependencies.
- Separation of customer master data from orders.
- Separation of product catalog data from order items.
- Product-to-category relationships.
- Preservation of legitimate historical snapshots.
- Identification of stored derived values requiring consistency controls.

Formal normalization evidence remains subject to detailed dependency analysis.

## 10. Planned Test Scenarios

| Test ID | Scenario | Expected Result |
|---|---|---|
| TC