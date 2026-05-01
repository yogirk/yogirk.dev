-- Setup: Create source batch (10K rows for CARRIER_1, single day)

CREATE OR REPLACE TABLE `YOUR_PROJECT.merge_test.source_batch` (
  record_id INT64,
  carrier_id STRING,
  load_date DATE,
  payload STRING,
  amount NUMERIC,
  created_at TIMESTAMP
);

INSERT INTO `YOUR_PROJECT.merge_test.source_batch`
SELECT
  5000000 + rn AS record_id,
  'CARRIER_1' AS carrier_id,
  DATE '2026-03-15' AS load_date,
  REPEAT('y', 100) AS payload,
  CAST(ROUND(RAND() * 10000, 2) AS NUMERIC) AS amount,
  CURRENT_TIMESTAMP() AS created_at
FROM UNNEST(GENERATE_ARRAY(1, 10000)) rn;
