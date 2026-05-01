# MERGE ON FALSE — BigQuery Empirical Test

Companion code for the blog post: [MERGE ON FALSE Is Not the Anti-Pattern You Think It Is](https://yogirk.dev/posts/merge-on-false-is-not-the-antipattern/)

## What This Tests

Three DML patterns for slice replacement in BigQuery, each tested on a clustered table and a flat (unclustered) table:

1. `MERGE ... ON FALSE` with a scoped delete clause
2. Keyed `MERGE` with a real join predicate and scoped delete
3. `DELETE + INSERT` in a transaction

Plus the actual anti-pattern: `MERGE ON FALSE` with an **unscoped** `NOT MATCHED BY SOURCE THEN DELETE`.

## How to Run

1. Replace `YOUR_PROJECT` in all SQL files with your GCP project ID
2. Run scripts in order: `01` through `03` set up the data, `04` through `07` are the test queries
3. Run `08_collect_stats.sql` to compare job performance

## Files

| File | Description |
|------|-------------|
| `01_setup_clustered.sql` | Create partitioned + clustered target (5M rows) |
| `02_setup_flat.sql` | Create flat target, same data, no partitioning/clustering |
| `03_source_batch.sql` | Create source batch (10K rows, single carrier/day) |
| `04_merge_on_false_scoped.sql` | MERGE ON FALSE with partition/cluster-aligned delete filter |
| `05_keyed_merge_scoped.sql` | Keyed MERGE with real join predicate and scoped delete |
| `06_delete_insert_txn.sql` | DELETE + INSERT in a transaction |
| `07_merge_on_false_unscoped.sql` | MERGE ON FALSE with unscoped delete (the real anti-pattern) |
| `08_collect_stats.sql` | Pull job stats from INFORMATION_SCHEMA.JOBS |
