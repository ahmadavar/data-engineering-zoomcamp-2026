-- ============================================================================
-- QUESTION 4: Counting Zero Fare Trips
-- ============================================================================
-- How many records have a fare_amount of 0?
--
-- Options:
--   a) 128,210
--   b) 546,578
--   c) 20,188,016
--   d) 8,333
--
-- Concept:
--   Simple WHERE clause filtering
--   Use materialized table for accurate count
-- ============================================================================

SELECT
  COUNT(*) as zero_fare_trips,
  FORMAT("%'d", COUNT(*)) as formatted_count
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
WHERE
  fare_amount = 0;

-- Expected Result: Will match one of the options above


-- ============================================================================
-- ADDITIONAL ANALYSIS: Why zero fares?
-- ============================================================================
-- Let's investigate these zero-fare trips

-- 1. Distribution by payment type
SELECT
  payment_type,
  COUNT(*) as trip_count,
  FORMAT("%'d", COUNT(*)) as formatted_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
WHERE
  fare_amount = 0
GROUP BY
  payment_type
ORDER BY
  trip_count DESC;

-- Payment type codes:
--   1 = Credit card
--   2 = Cash
--   3 = No charge
--   4 = Dispute
--   5 = Unknown
--   6 = Voided trip


-- 2. Check trip distances for zero-fare trips
SELECT
  CASE
    WHEN trip_distance = 0 THEN 'Zero distance'
    WHEN trip_distance > 0 AND trip_distance <= 1 THEN 'Short (0-1 mi)'
    WHEN trip_distance > 1 AND trip_distance <= 5 THEN 'Medium (1-5 mi)'
    WHEN trip_distance > 5 THEN 'Long (5+ mi)'
    ELSE 'Unknown'
  END as distance_category,
  COUNT(*) as trip_count,
  ROUND(AVG(trip_distance), 2) as avg_distance
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized`
WHERE
  fare_amount = 0
GROUP BY
  distance_category
ORDER BY
  trip_count DESC;


-- 3. Monthly trend of zero-fare trips
SELECT
  FORMAT_DATE('%Y-%m', DATE(tpep_pickup_datetime)) as month,
  COUNT(*) as zero_fare_count,
  (SELECT COUNT(*) FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized` m
   WHERE FORMAT_DATE('%Y-%m', DATE(m.tpep_pickup_datetime)) = FORMAT_DATE('%Y-%m', DATE(t.tpep_pickup_datetime))
  ) as total_trips_month,
  ROUND(COUNT(*) * 100.0 / (
    SELECT COUNT(*) FROM `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized` m
    WHERE FORMAT_DATE('%Y-%m', DATE(m.tpep_pickup_datetime)) = FORMAT_DATE('%Y-%m', DATE(t.tpep_pickup_datetime))
  ), 2) as zero_fare_percentage
FROM
  `electric-cosine-485318-f9.o3_warehouse.yellow_tripdata_materialized` t
WHERE
  fare_amount = 0
GROUP BY
  month
ORDER BY
  month;


-- ============================================================================
-- INSIGHTS
-- ============================================================================
-- Zero-fare trips can occur due to:
--   1. Driver errors (forgot to start meter)
--   2. Voided/cancelled trips
--   3. Disputes or refunds
--   4. Test rides or employee rides
--   5. No-charge rides (promotional, accessibility services)
--
-- Data Quality Note:
--   High percentage of zero fares may indicate data quality issues
--   These records might need special handling in analysis
-- ============================================================================
