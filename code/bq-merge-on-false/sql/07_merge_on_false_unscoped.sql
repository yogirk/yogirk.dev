-- Test: MERGE ON FALSE with UNSCOPED delete (the actual anti-pattern)
-- WARNING: This deletes the entire target except source rows!
-- Only run this if you're prepared to reload the target table.

MERGE INTO `YOUR_PROJECT.merge_test.target` T
USING `YOUR_PROJECT.merge_test.source_batch` S
ON FALSE
WHEN NOT MATCHED BY TARGET THEN
  INSERT (record_id, carrier_id, load_date, payload, amount, created_at)
  VALUES (S.record_id, S.carrier_id, S.load_date, S.payload, S.amount, S.created_at)
WHEN NOT MATCHED BY SOURCE THEN DELETE;
