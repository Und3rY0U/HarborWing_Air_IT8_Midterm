-- ============================================================================
-- HarborWing Air Relational Database - Demonstration & Verification Queries
-- Midterm Drill / IT8 - Part 1
-- Database System: MySQL 8.0+ / MariaDB 10.5+
-- ============================================================================

USE harborwing_air;

-- ============================================================================
-- 1. ROW COUNT VERIFICATION QUERY
-- Verifies that every one of the 11 tables contains at least 50 rows.
-- ============================================================================
SELECT 'airport' AS table_name, COUNT(*) AS row_count, IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') AS status FROM airport
UNION ALL
SELECT 'booking_agent', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM booking_agent
UNION ALL
SELECT 'calendar_date', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM calendar_date
UNION ALL
SELECT 'passenger', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM passenger
UNION ALL
SELECT 'flight_schedule', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM flight_schedule
UNION ALL
SELECT 'flight_cost', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM flight_cost
UNION ALL
SELECT 'flight_leg', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM flight_leg
UNION ALL
SELECT 'payment', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM payment
UNION ALL
SELECT 'reservation', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM reservation
UNION ALL
SELECT 'reservation_payment', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM reservation_payment
UNION ALL
SELECT 'reservation_leg', COUNT(*), IF(COUNT(*) >= 50, 'PASS (>= 50)', 'FAIL') FROM reservation_leg;

-- ============================================================================
-- 2. QUERY 1: Viewing a reservation with passenger, agent, payments, and legs
-- IMPORTANT REQUIREMENT: "Avoid inflating payment totals when joining multiple
-- payments and multiple legs."
--
-- Why inflation occurs naively:
-- If reservation #1 has 2 payments and 2 legs, a direct multi-table JOIN creates
-- 2 * 2 = 4 product rows, multiplying payment amounts twice in a SUM() aggregation.
--
-- Solution: Pre-aggregate payments and legs separately using Common Table
-- Expressions (CTEs) before joining them back to the parent reservation.
-- ============================================================================
WITH PaymentAggregation AS (
    SELECT 
        rp.reservation_id, 
        COUNT(p.payment_id) AS payment_count,
        SUM(p.payment_amount) AS total_paid_amount,
        GROUP_CONCAT(
            CONCAT('PayID #', p.payment_id, ': $', p.payment_amount, ' [', p.payment_status_code, ']') 
            ORDER BY p.payment_id 
            SEPARATOR '; '
        ) AS payment_breakdown
    FROM reservation_payment rp
    JOIN payment p ON rp.payment_id = p.payment_id
    GROUP BY rp.reservation_id
),
LegAggregation AS (
    SELECT 
        rl.reservation_id,
        COUNT(fl.leg_id) AS leg_count,
        GROUP_CONCAT(
            CONCAT('Leg #', fl.leg_id, ' (', fl.scheduled_flight, ': ', fl.origin_airport, ' -> ', fl.destination_airport, ')')
            ORDER BY fl.leg_id 
            SEPARATOR ' | '
        ) AS flight_itinerary
    FROM reservation_leg rl
    JOIN flight_leg fl ON rl.leg_id = fl.leg_id
    GROUP BY rl.reservation_id
)
SELECT 
    r.reservation_id,
    r.reservation_status_code,
    r.ticket_type_code,
    r.travel_class_code,
    r.number_in_party,
    r.creation_date_time,
    CONCAT(pax.first_name, ' ', COALESCE(CONCAT(pax.second_name, ' '), ''), pax.last_name) AS main_passenger_name,
    pax.email_address AS passenger_email,
    pax.phone_number AS passenger_phone,
    COALESCE(agt.name, 'DIRECT BOOKING (No Booking Agent)') AS booking_agent_name,
    COALESCE(pa.payment_count, 0) AS total_payments_made,
    COALESCE(pa.total_paid_amount, 0.00) AS total_amount_paid,
    COALESCE(pa.payment_breakdown, 'None') AS payment_details,
    COALESCE(la.leg_count, 0) AS total_flight_legs,
    COALESCE(la.flight_itinerary, 'None') AS flight_itinerary
FROM reservation r
JOIN passenger pax ON r.main_passenger_id = pax.passenger_id
LEFT JOIN booking_agent agt ON r.booking_agent_id = agt.agent_id
LEFT JOIN PaymentAggregation pa ON r.reservation_id = pa.reservation_id
LEFT JOIN LegAggregation la ON r.reservation_id = la.reservation_id
WHERE r.reservation_id IN (1, 2, 3, 4, 5) -- Demonstrating reservations with split payments & multi-legs
ORDER BY r.reservation_id;

-- ============================================================================
-- 3. QUERY 2: Finding reservations using a particular leg
-- Use case: Flight operations & gate dispatch looking up manifest reservations.
-- Parameter: leg_id = 1
-- ============================================================================
SELECT 
    fl.leg_id,
    fl.scheduled_flight,
    fl.origin_airport,
    fl.destination_airport,
    fl.actual_departure_time,
    fl.actual_arrival_time,
    r.reservation_id,
    r.reservation_status_code,
    r.ticket_type_code,
    r.travel_class_code,
    r.number_in_party,
    CONCAT(pax.first_name, ' ', COALESCE(CONCAT(pax.second_name, ' '), ''), pax.last_name) AS main_passenger,
    pax.phone_number,
    pax.email_address,
    COALESCE(agt.name, 'Direct Booking') AS booking_channel
FROM flight_leg fl
JOIN reservation_leg rl ON fl.leg_id = rl.leg_id
JOIN reservation r ON rl.reservation_id = r.reservation_id
JOIN passenger pax ON r.main_passenger_id = pax.passenger_id
LEFT JOIN booking_agent agt ON r.booking_agent_id = agt.agent_id
WHERE fl.leg_id = 1
ORDER BY r.reservation_id;

-- ============================================================================
-- 4. QUERY 3: Finding payments linked to a reservation
-- Use case: Billing & accounting audit to review financial records for a booking.
-- Parameter: reservation_id = 1
-- ============================================================================
SELECT 
    r.reservation_id,
    r.reservation_status_code,
    CONCAT(pax.first_name, ' ', pax.last_name) AS main_passenger,
    p.payment_id,
    p.payment_status_code,
    p.payment_date,
    p.payment_amount
FROM reservation r
JOIN passenger pax ON r.main_passenger_id = pax.passenger_id
JOIN reservation_payment rp ON r.reservation_id = rp.reservation_id
JOIN payment p ON rp.payment_id = p.payment_id
WHERE r.reservation_id = 1
ORDER BY p.payment_date ASC;

-- Demonstrating shared payment (single payment linked to multiple reservations):
SELECT 
    p.payment_id,
    p.payment_status_code,
    p.payment_amount,
    p.payment_date,
    r.reservation_id,
    r.reservation_status_code,
    CONCAT(pax.first_name, ' ', pax.last_name) AS main_passenger
FROM payment p
JOIN reservation_payment rp ON p.payment_id = rp.payment_id
JOIN reservation r ON rp.reservation_id = r.reservation_id
JOIN passenger pax ON r.main_passenger_id = pax.passenger_id
WHERE p.payment_id = 20
ORDER BY r.reservation_id;

-- ============================================================================
-- 5. QUERY 4: Finding a flight cost for a flight, aircraft type, and date
-- Parameter: Flight 'HW101', Aircraft 'DHC-8-400', Date '2026-01-15'
-- Note on overlapping validity periods: If multiple promotional or seasonal
-- tariffs match the same queried date, policies such as ORDER BY valid_from_date
-- DESC LIMIT 1 (most recent policy) or MIN(cost_amount) (lowest fare) can be applied.
-- ============================================================================
SELECT 
    fc.flight_number,
    fc.aircraft_type_code,
    fc.valid_from_date,
    fc.valid_to_date,
    fc.cost_amount,
    '2026-01-15' AS target_travel_date
FROM flight_cost fc
WHERE fc.flight_number = 'HW101'
  AND fc.aircraft_type_code = 'DHC-8-400'
  AND '2026-01-15' BETWEEN fc.valid_from_date AND fc.valid_to_date
ORDER BY fc.valid_from_date DESC;
