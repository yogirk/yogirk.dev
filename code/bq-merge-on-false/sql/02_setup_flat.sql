-- Setup: Create flat (unclustered, unpartitioned) target table (5M rows)
-- Same data as 01, but without partitioning or clustering

CREATE OR REPLACE TABLE `YOUR_PROJECT.merge_test.target_flat` (
  record_id INT64,
  carrier_id STRING,
  load_date DATE,
  payload STRING,
  amount NUMERIC,
  created_at TIMESTAMP
);

INSERT INTO `YOUR_PROJECT.merge_test.target_flat`
SELECT
  (a - 1) * 1000 + b AS record_id,
  CONCAT('CARRIER_', CAST(MOD((a - 1) * 1000 + b, 10) + 1 AS STRING)) AS carrier_id,
  DATE_ADD('2026-03-01', INTERVAL CAST(MOD((a - 1) * 1000 + b, 30) AS INT64) DAY) AS load_date,
  REPEAT('x', 100) AS payload,
  CAST(ROUND(RAND() * 10000, 2) AS NUMERIC) AS amount,
  TIMESTAMP_ADD('2026-03-01 00:00:00', INTERVAL CAST((a - 1) * 1000 + b AS INT64) SECOND) AS created_at
FROM
  UNNEST(GENERATE_ARRAY(1, 5000)) a,
  UNNEST(GENERATE_ARRAY(1, 1000)) b;
