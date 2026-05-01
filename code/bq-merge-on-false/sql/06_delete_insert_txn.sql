-- Test: DELETE + INSERT in a transaction
-- Replace CARRIER_1 / 2026-03-15 slice
-- Run against both `target` (clustered) and `target_flat` (flat)

BEGIN TRANSACTION;

DELETE FROM `YOUR_PROJECT.merge_test.target`
WHERE carrier_id = 'CARRIER_1'
  AND load_date = DATE '2026-03-15';

INSERT INTO `YOUR_PROJECT.merge_test.target`
SELECT * FROM `YOUR_PROJECT.merge_test.source_batch`;

COMMIT TRANSACTION;
