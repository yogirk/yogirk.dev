---
title: "MERGE ON FALSE Is Not the Anti-Pattern You Think It Is"
date: 2026-04-04
draft: false
description: "The common advice says avoid MERGE ON FALSE in BigQuery. Empirical testing says the real problem is somewhere else."
tags: ["BigQuery", "Snowflake", "SQL", "MERGE", "Data Engineering", "TIL", "GCP"]
categories: ["Data Engineering"]
summary: "I set out to prove MERGE ON FALSE is an anti-pattern in BigQuery. The data told a different story. The real culprit is unclustered tables and unscoped delete clauses."
toc: true
---

I am currently consulting with a client on a Snowflake to BigQuery migration and as part of optimizing multiple pipelines, I ran into `MERGE ... ON FALSE` pattern and I wanted to get to the bottom of whether this is an anti-pattern in itself for BigQuery. I wanted to gather empirical evidence and fully understand what happens under the hood.  I started with the  assumption that it was a straightforward anti-pattern in BigQuery — something that works fine in Snowflake but causes full table scans in BQ due to architectural differences. I even convened an [agent council](https://github.com/yogirk/agent-council) (Claude, Gemini, Codex) to pre-validate this thesis before running any queries.

The council agreed with high confidence: "MERGE ON FALSE forces a full cross-join scan in BigQuery because BigQuery lacks micro-partition pruning." 

Then I created a test dataset and ran the queries. The results disagreed.

## The Setup

If you want to reproduce this and follow along, all the SQL scripts are in [bq-merge-on-false](https://github.com/yogirk/blog-code/tree/master/bq-merge-on-false). Replace `YOUR_PROJECT` with your GCP project ID and run them in order.

Target table: 5M rows, 10 carriers, 30 days of `load_date`. 
Source batch: 10K new rows for `CARRIER_1` on `2026-03-15`. 
The task: replace the CARRIER_1/2026-03-15 slice with the incoming batch.

I tested two versions of the target table:
- **Clustered**: `PARTITION BY load_date`, `CLUSTER BY carrier_id`
- **Flat**: no partitioning, no clustering

And three DML patterns:
1. `MERGE ... ON FALSE` with a scoped `WHEN NOT MATCHED BY SOURCE AND T.carrier_id = 'CARRIER_1' AND T.load_date = DATE '2026-03-15' THEN DELETE`
2. `MERGE` with a real key (`ON T.record_id = S.record_id AND T.carrier_id = S.carrier_id AND T.load_date = S.load_date`) and the same scoped delete
3. `DELETE + INSERT` inside a transaction, with the same partition/cluster-aligned WHERE clause

## Results on the Clustered Table

| Pattern | MB Processed | MB Billed | Slot (sec) |
|---------|-------------|-----------|------------|
| MERGE ON FALSE + scoped delete | **4.97** | 20.97 | 10 |
| Keyed MERGE + scoped delete | 138.83 | 139.46 | 33 |
| DELETE + INSERT (txn) | 3.25 | ~31 | 24 |

MERGE ON FALSE was the cheapest pattern (!!!). Not the worst, the _cheapest_. It processed 28x less data than the keyed MERGE.

## Wait, What?

I looked at the query plans to understand why.

**MERGE ON FALSE** produced a 6-stage plan. Stage 0 read only 50,000 rows. BQ pushed the `carrier_id = 'CARRIER_1' AND load_date = '2026-03-15'` predicates from the NOT MATCHED BY SOURCE clause into the input scan as partition + cluster pruning filters. Since `ON FALSE` means there's no join to perform, BQ skipped the hash-join entirely and just processed the filtered delete and insert as separate operations.

**Keyed MERGE** produced a 9-stage plan. Stage 1 read 5,010,000 rows — the entire target. The join key `ON T.record_id = S.record_id` doesn't align with the partition key (`load_date`) or cluster key (`carrier_id`), so BQ couldn't prune. It had to read every row to perform the hash join, even though the NOT MATCHED BY SOURCE clause had the same partition filter.

The ON FALSE eliminated the join. That was the advantage. No join means BQ doesn't need to read the target for matching purposes — it only reads whatever the delete filter touches.

## Results on the Flat Table

| Pattern | MB Processed | MB Billed | Slot (sec) |
|---------|-------------|-----------|------------|
| MERGE ON FALSE + scoped delete | **767.03** | 767.56 | 6 |
| Keyed MERGE + scoped delete | 768.56 | 768.61 | 22 |
| DELETE + INSERT (txn) | 768.56 | 788.53 | 11 |

**Every pattern scanned the full ~768 MB**. The filter predicates in NOT MATCHED BY SOURCE had nothing to prune against. Without clustering, the carrier_id and load_date filters are just post-scan filters — BQ reads everything and discards what doesn't match.

## The Delta

| Pattern | Clustered MB | Flat MB | Reduction from Clustering |
|---------|-------------|---------|--------------------------|
| MERGE ON FALSE + scoped delete | 4.97 | 767 | **154x** |
| DELETE + INSERT (txn) | 3.25 | 768 | **236x** |
| Keyed MERGE + scoped delete | 138.83 | 768 | **5.5x** |

MERGE ON FALSE benefits the _most_ from clustering because it relies entirely on filter pushdown for pruning. A keyed MERGE already reads broadly for the join, so clustering helps less.

## What About the Unscoped Delete?

I also tested `MERGE ON FALSE ... WHEN NOT MATCHED BY SOURCE THEN DELETE` without any filter. On the clustered table, it scanned 768 MB and deleted 5 million rows. That's the "replace everything with source" behavior — and it's a full table scan no matter what.

{{< callout type="info" >}}
This is the actual anti-pattern. Not ON FALSE, not MERGE, but **NOT MATCHED BY SOURCE without a partition/cluster-aligned predicate**.
{{< /callout >}}

## Cross-Checking with a Real Client Environment

I had a client pipeline that went through a similar optimization journey. The original was a Snowflake-style medallion pattern (BLK → STG → EXC → TGT) with separate DELETE + INSERT at each stage. Twelve-plus BQ jobs, 35 seconds. 

The progression:
- **Pass 1** (views instead of intermediate tables): 12 sec — fewer jobs, fewer writes
- **Pass 2** (temp tables): 14 sec — materialization overhead offset the wins
- **Pass 3** (single temp table + DELETE/INSERT with clustering): ~8 sec
- **Pass 4** (inline CTE + keyed MERGE, 3 jobs, clustering on DATASOURCE_KEY): ~8 sec

Two things stood out:

First, the biggest win was **reducing job count**, not changing the MERGE pattern. Going from 12+ jobs to 3 cut 20+ seconds. Each BQ scripting job carries ~2-3 seconds of fixed overhead (planning, scheduling, slot acquisition). When your pipeline fans out into many small jobs, that overhead dominates.

Second, the final keyed MERGE worked well because the **join key included the clustering column** (DATASOURCE_KEY). So BQ could prune the target read for both the join and the NOT MATCHED BY SOURCE delete. In our lab test, the keyed MERGE was expensive because the join key (`record_id`) didn't align with the cluster key (`carrier_id`) — forcing a full target scan for the join stage.

## What I Actually Learned

**1. MERGE ON FALSE is not an anti-pattern.** On a properly clustered table with a scoped delete clause, it's the cheapest pattern for slice replacement because it eliminates the join entirely. Maybe the dataset I generated is small enough that this is not a problem, but for now - empirical evidence says its not the main culprit. 

**2. The anti-pattern is unscoped NOT MATCHED BY SOURCE.** `WHEN NOT MATCHED BY SOURCE THEN DELETE` without partition/cluster-aligned predicates forces a full table scan regardless of ON FALSE or keyed MERGE.

**3. Clustering is the prerequisite, not the pattern choice.** Without clustering, every pattern scans the full table. With clustering, the filter pushdown from NOT MATCHED BY SOURCE is what saves you — and ON FALSE benefits the most because it doesn't add a competing join scan.

**4. If you use a keyed MERGE, align the key with clustering.** A keyed MERGE where the ON clause includes the clustering column gets pruning on both the join and the delete. A keyed MERGE where the join key doesn't align with clustering still reads the full target for the join.

**5. In BQ, job count often matters more than query pattern.** Each statement in a BEGIN/END script dispatches a separate job with ~2-3 sec fixed cost. Collapsing from 12 jobs to 3 can save more time than any MERGE optimization.

## The Snowflake Connection

The original question was: why does MERGE ON FALSE work in Snowflake but fail in BigQuery? The honest answer: it doesn't fail in BigQuery either, not when the table is clustered and the delete clause is scoped. The Snowflake community treats ON FALSE as idiomatic because Snowflake's micro-partition pruning makes it efficient by default — similar to how clustering makes it efficient in BQ.

The real difference between the two engines for this pattern is not capability, it's defaults. Snowflake tables come with micro-partition metadata out of the box. BigQuery tables are flat by default — you have to opt into partitioning and clustering. If you skip that step and port a Snowflake pipeline to BQ as-is, everything scans the full table, and MERGE ON FALSE gets blamed for a problem that belongs to the missing clustering.
