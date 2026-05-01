-- Test: Keyed MERGE with scoped delete
-- Replace CARRIER_1 / 2026-03-15 slice using real join predicate
-- Run against both `target` (clustered) and `target_flat` (flat)

MERGE INTO `YOUR_PROJECT.merge_test.target` T
USING `YOUR_PROJECT.merge_test.source_batch` S
ON T.record_id = S.record_id
  AND T.carrier_id = S.carrier_id
  AND T.load_date = S.load_date
WHEN MATCHED THEN
  UPDATE SET
    payload = S.payload,
    amount = S.amount,
    created_at = S.created_at
WHEN NOT MATCHED BY TARGET THEN
  INSERT (record_id, carrier_id, load_date, payload, amount, created_at)
  VALUES (S.record_id, S.carrier_id, S.load_date, S.payload, S.amount, S.created_at)
WHEN NOT MATCHED BY SOURCE
  AND T.carrier_id = 'CARRIER_1'
  AND T.load_date = DATE '2026-03-15'
THEN DELETE;
