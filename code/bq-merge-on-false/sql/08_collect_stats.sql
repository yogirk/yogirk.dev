-- Collect job stats after running the tests
-- Adjust the INTERVAL if needed based on when you ran them

SELECT
  job_id,
  statement_type,
  TIMESTAMP_DIFF(end_time, start_time, MILLISECOND) AS elapsed_ms,
  total_bytes_processed,
  ROUND(total_bytes_processed / 1e6, 2) AS mb_processed,
  ROUND(total_bytes_billed / 1e6, 2) AS mb_billed,
  total_slot_ms,
  dml_statistics
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
  AND statement_type IN ('MERGE', 'DELETE', 'INSERT')
  AND state = 'DONE'
  AND error_result IS NULL
ORDER BY creation_time ASC;
