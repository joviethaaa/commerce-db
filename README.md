# CommerceDB

### Enterprise E-Commerce Database Design & Optimization

CommerceDB is a database engineering portfolio project focused on designing, implementing, and optimizing a PostgreSQL-based transactional database for a simulated e-commerce platform.

## Project Overview

The project demonstrates practical database engineering concepts, including:

- Relational database modeling and normalization
- Primary keys, foreign keys, and referential integrity
- Transaction management and concurrency control
- Inventory reservation and order processing
- SQL performance analysis and query optimization
- Database reliability, backup, and recovery

## Technology Stack

| Technology | Purpose |
|---|---|
| PostgreSQL 18 | Relational database |
| Docker & Docker Compose | Database containerization |
| DBeaver Community | Database administration |
| SQL | Database queries and schema |
| Python (planned) | Data generation and benchmarking |
| Git & GitHub | Version control |

## Project Structure

- `docs/` — Requirements, ERD, and design documentation
- `sql/migrations/` — Database schema migrations
- `sql/queries/` — SQL queries
- `sql/indexes/` — Index optimization
- `scripts/` — Automation and data generation
- `tests/` — Database testing
- `benchmarks/` — Performance measurements

## Getting Started

1. Install Docker Desktop and Git.
2. Clone this repository.
3. Copy `.env.example` to `.env`.
4. Configure a strong local PostgreSQL password in `.env`.
5. Run `docker compose up -d`.
6. Connect using PostgreSQL credentials from `.env`.

## Current Development Status

- [x] Requirements analysis and initial design
- [x] Docker development environment
- [x] PostgreSQL 18 initialization
- [x] Database connection verified using psql
- [x] Database connection verified using DBeaver
- [ ] Physical database schema
- [ ] Transaction and integrity tests
- [ ] Data generation and performance benchmarks
- [ ] Backup and recovery tests

## Notes

CommerceDB currently uses synthetic business scenarios. No production customer data is stored in this repository.

Performance results will be published after reproducible benchmark testing.