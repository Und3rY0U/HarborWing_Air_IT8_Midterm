# HarborWing Air - Relational Database System (Part 1)
**Course:** IT8 Midterm Drill / Laboratory Exam  
**Student Developer Project:** HarborWing Air Database Implementation  
**Technology Stack:** MySQL Server 8.4 LTS, MySQL Workbench, Python 3.12 (Faker, mysql-connector-python), Git  

---

## 1. Executive Summary & Company Background

HarborWing Air is a regional airline connecting coastal cities and island communities. Historically, the company operated using manual spreadsheets, leading to severe data integrity anomalies:
- **Redundant passenger data:** Passenger names, addresses, and contacts were repeatedly retyped across reservations, leading to update anomalies and typos.
- **Inconsistent airport codes:** Station names and locations lacked standardization.
- **Lost connection visibility:** Tracking itineraries with multiple flight legs was unreliable.
- **Duplicated billing:** Multi-reservation corporate payments could not be tracked without cloning payment entries.
- **Overwritten schedule times:** Operational delays overwrote timetables, destroying scheduled historical data.
- **Lost fare history:** Price updates overwrote older flight costs, ruining financial reporting.

This project delivers a normalized, 3NF relational database implemented on **MySQL 8.4 InnoDB** with synthetic data generated via **Python Faker**, satisfying all relational integrity constraints, business rules, and analytical query requirements.

---

## 2. Prerequisites & Environment Setup

All required applications have been configured on the system:
1. **MySQL Server 8.4 LTS:** Running locally on port `3306` with the root user.
   - If starting manually, run `start_mysql.bat` or launch `mysqld --datadir="%USERPROFILE%\mysql_data" --console`.
2. **MySQL Workbench:** Used for creating the EER diagram, running SQL scripts, and exporting `.mwb` / diagram images.
3. **Python 3.12:** Installed with `faker` and `mysql-connector-python`.
4. **Git & GitHub Desktop:** Configured for version control and repository submission.

---

## 3. Database Architecture & Table Explanations

The schema consists of **11 core tables** organized into distinct operational domains:

```
[passenger] <--(1:N)-- [reservation] --(N:M via reservation_payment)-- [payment]
                             |
                   (N:M via reservation_leg)
                             |
                             v
[airport] <--(1:N)-- [flight_schedule] <--(1:N)-- [flight_leg]
                             ^
                             | (1:N)
                             v
                       [flight_cost] <--(1:N)-- [calendar_date]
```

### Table Specifications:
1. **`booking_agent`**: Stores independent travel agencies and booking partners.
   - *Columns:* `agent_id` (PK, Auto-increment), `name`, `additional_details`.
   - *Deletion rule:* `ON DELETE SET NULL` on `reservation(booking_agent_id)`.
2. **`passenger`**: Stores master customer profiles. Eliminates duplicate contact entries.
   - *Columns:* `passenger_id` (PK), `first_name`, `second_name` (nullable), `last_name`, `phone_number`, `email_address` (UNIQUE), `address_lines`, `city`, `state_province_county`, `country`, `other_details`.
   - *Deletion rule:* `ON DELETE RESTRICT` protects historical reservation records.
3. **`calendar_date`**: Serves as a calendar dimension table for strict date validation.
   - *Columns:* `date` (PK), `day_of_the_month` (CHECK 1-31), `business_day_indicator`.
4. **`airport`**: Master table of coastal and island destinations.
   - *Columns:* `airport_code` (PK, CHAR(3) IATA), `name`, `location`, `other_details`.
5. **`flight_schedule`**: Timetable of scheduled flights.
   - *Columns:* `flight_number` (PK), `airline_code`, `usual_aircraft_type_code`, `origin_airport` (FK), `destination_airport` (FK), `scheduled_departure_time`, `scheduled_arrival_time`.
   - *Constraints:* Origin != Destination; Scheduled arrival > Scheduled departure.
6. **`flight_leg`**: Represents individual operational flight instances/legs.
   - *Columns:* `leg_id` (PK), `scheduled_flight` (FK), `origin_airport` (FK), `destination_airport` (FK), `actual_departure_time` (nullable), `actual_arrival_time` (nullable).
   - *Constraints:* Actual departure and arrival can be `NULL` for future/unoperated flights; when present, arrival >= departure.
7. **`flight_cost`**: Historical and promotional pricing for flights and aircraft.
   - *Columns:* `flight_number` (FK), `aircraft_type_code`, `valid_from_date` (FK -> calendar_date), `valid_to_date` (FK -> calendar_date), `cost_amount` (CHECK >= 0).
   - *Primary Key:* Composite `(flight_number, aircraft_type_code, valid_from_date)`.
   - *Constraints:* `valid_to_date >= valid_from_date`.
8. **`payment`**: Standalone financial ledger of customer payments.
   - *Columns:* `payment_id` (PK), `payment_status_code`, `payment_date`, `payment_amount` (CHECK > 0).
9. **`reservation`**: Customer booking records.
   - *Columns:* `reservation_id` (PK), `main_passenger_id` (FK), `booking_agent_id` (FK, nullable for direct bookings), `reservation_status_code`, `ticket_type_code`, `travel_class_code`, `creation_date_time`, `number_in_party` (CHECK > 0).
10. **`reservation_payment` (Linking Table)**: Resolves the N:M relationship between reservations and payments.
    - *Columns:* `reservation_id` (PK, FK), `payment_id` (PK, FK).
    - Enforces uniqueness without duplicate pairs. Does **not** store an allocation amount per business rules.
11. **`reservation_leg` (Linking Table)**: Resolves the N:M relationship between reservations and flight legs.
    - *Columns:* `reservation_id` (PK, FK), `leg_id` (PK, FK).
    - Enables connecting itineraries and multi-passenger flights.

---

## 4. Design & Developer Explanation (Required Analysis)

### 4.1 Why the Two Linking Tables Are Necessary
- **`reservation_payment`:** In real airline operations, a customer may pay using split payment methods (e.g., credit card installment + voucher) requiring multiple payments for one reservation (1:N). Conversely, a corporate travel manager or family organizer may make a single bulk payment that covers multiple separate reservations (N:1). Direct foreign keys in either table would violate first or second normal form. The junction table resolves this into a clean **Many-to-Many (N:M)** structure.
- **`reservation_leg`:** A single reservation frequently consists of connecting flights (e.g., San Francisco -> Seattle -> Anchorage), meaning one reservation contains multiple flight legs. Similarly, a single flight leg carries dozens of reservations. A junction table allows unlimited connection legs per booking without array columns or row duplication.

### 4.2 Why Scheduled and Actual Times Are Separate
Spreadsheet systems suffered because operators entered actual gate departure times directly over scheduled times. In our schema:
- `flight_schedule` stores the contractual, planned timetable.
- `flight_leg` stores the real-time operational execution (`actual_departure_time`, `actual_arrival_time`).
- **Benefits:** Retains historical schedule accuracy, enables on-time performance analytics (delay calculations), and allows future flight legs to exist with `NULL` actual times before takeoff.

### 4.3 Why Flight Costs Use a Composite Key
- Primary Key: `(flight_number, aircraft_type_code, valid_from_date)`
- A flight route (e.g. `HW101`) may be operated by different aircraft types with different operating costs (e.g. Dash 8 vs. Cessna Caravan).
- Furthermore, pricing changes seasonally or during promotional windows. A single surrogate key or flight number alone cannot guarantee uniqueness across different pricing epochs. Combining `flight_number`, `aircraft_type_code`, and `valid_from_date` guarantees that a specific aircraft on a specific flight has a uniquely identifiable fare rule beginning on that date.

### 4.4 Simplifying Assumption vs. Production Airline Systems
- **Assumption made:** `flight_number` is treated as a unique schedule identifier.
- **Production reality:** In international aviation (IATA/ICAO), a flight number (e.g., `HW101`) repeats daily or weekly for decades. A production system requires an operational schedule identifier such as `(flight_number, flight_designator, schedule_season_id, frequency_mask, effective_date)` to differentiate Monday's HW101 from Tuesday's HW101, track aircraft tail numbers (fin numbers), manage codeshare airline partners, and handle daylight saving offsets.

### 4.5 Reference Codes Strategy
Codes such as airline code (`'HW'`), aircraft types (`'DHC-8-400'`, `'ATR-72'`), statuses (`'CONFIRMED'`, `'COMPLETED'`), and travel classes (`'ECONOMY'`, `'BUSINESS'`) are treated as externally managed standard domain codes documented in our schema. Creating artificial reference tables for statuses or travel classes would require inserting 50 dummy statuses to satisfy the drill's blanket 50-row rule, which would degrade database realism.

---

## 5. Explicit Limitations Discussion

1. **Shared Payment Allocation Ambiguity:**
   - *Limitation:* When a single payment is linked to multiple reservations via `reservation_payment`, the table contains only `(reservation_id, payment_id)` with no split ratio or dollar amount stored.
   - *Impact:* It is impossible from the database alone to know whether a $1,000 payment split across two reservations was allocated as $500/$500 or $800/$200. Accounting systems must maintain an external ledger or ledger line-item entity if exact per-reservation credits are required.
2. **Party Size vs. Individual Traveler Identification:**
   - *Limitation:* The `reservation` table stores `main_passenger_id` and `number_in_party`, but does not store the names, passports, or seating for accompanying party members.
   - *Impact:* Security manifests, TSA PreCheck, and individual boarding passes cannot be issued for passengers 2 through $N$ without an additional `reservation_passenger_manifest` table.
3. **Normalization Overhead (Joins Required):**
   - *Limitation:* Splitting data across 11 tables eliminates data redundancy and anomalies, but querying complete customer journeys requires 5+ table joins.
   - *Impact:* Developers must write optimized queries with explicit indexes and CTEs to prevent Cartesian explosions and latency.
4. **Overlapping Cost Validity Periods Policy:**
   - *Limitation:* When a date falls within multiple valid date ranges for the same flight and aircraft, the database schema allows multiple matches.
   - *Impact:* The application layer or query must define a deterministic resolution policy, such as selecting the newest rule (`ORDER BY valid_from_date DESC LIMIT 1`) or the lowest promotional fare (`MIN(cost_amount)`).

---

## 6. How Another Developer Recreates, Seeds, and Queries the Database

### Step 1: Initialize Database Schema
In MySQL Workbench or command line:
```bash
# In PowerShell / CMD (or open schema.sql in MySQL Workbench and execute):
mysql -u root < schema.sql
```

### Step 2: Seed Synthetic Data (Repeatable with Fixed Seed 42)
You can seed using either the Python generator OR the pre-generated SQL seed:
- **Option A (Python Faker script):**
  ```bash
  python generate_data.py
  ```
- **Option B (Direct SQL file in MySQL Workbench):**
  Open `seed_data.sql` in MySQL Workbench and click the lightning bolt (Execute) icon.

### Step 3: Run Verification Queries
Open `queries.sql` in MySQL Workbench and execute to verify:
1. Every table has $\ge 50$ rows.
2. Query 1 aggregates multi-payment and multi-leg reservations without inflation.
3. Query 2 retrieves leg passenger manifests.
4. Query 3 inspects linked payments.
5. Query 4 retrieves valid flight costs for a specific flight, aircraft, and travel date.

---

## 7. Preventing Cartesian Product / Payment Total Inflation

When joining `reservation` to both `reservation_payment` (1:N) and `reservation_leg` (1:N), a naive `SELECT SUM(payment_amount) ... GROUP BY reservation_id` multiplies payment rows by the number of legs:

$$\text{Rows Produced} = N_{\text{payments}} \times N_{\text{legs}}$$

If a reservation has 2 payments totaling \$500 and 2 legs, a naive join computes:

$$2 \times 2 = 4 \text{ rows} \implies \$500 \times 2 = \$1000 \quad \text{(100\% inflation error!)}$$

**Our Solution (in `queries.sql`):**  
Pre-aggregate payments and legs in independent Common Table Expressions (CTEs):
```sql
WITH PaymentAggregation AS (
    SELECT rp.reservation_id, SUM(p.payment_amount) AS total_paid
    FROM reservation_payment rp
    JOIN payment p ON rp.payment_id = p.payment_id
    GROUP BY rp.reservation_id
),
LegAggregation AS (
    SELECT rl.reservation_id, COUNT(fl.leg_id) AS leg_count
    FROM reservation_leg rl
    JOIN flight_leg fl ON rl.leg_id = fl.leg_id
    GROUP BY rl.reservation_id
)
SELECT r.reservation_id, pa.total_paid, la.leg_count
FROM reservation r
LEFT JOIN PaymentAggregation pa ON r.reservation_id = pa.reservation_id
LEFT JOIN LegAggregation la ON r.reservation_id = la.reservation_id;
```
This guarantees exact sums regardless of how many connecting flights or split payments exist.

---

## 8. MySQL Workbench EER Diagram Export Guide

To fulfill Deliverable #1 (`.mwb` file and image/PDF):
1. Open **MySQL Workbench**.
2. Click **File -> Import -> Reverse Engineer MySQL Create Script...**
3. Browse to `C:\Users\HomePC\.gemini\antigravity\scratch\harborwing-air\schema.sql`.
4. Check **"Place imported objects on a diagram"**.
5. Click **Execute**, then **Next**, then **Finish**.
6. MySQL Workbench automatically renders the complete EER diagram with all 11 tables and relationship lines.
7. Click **File -> Save Model As...** and save as `harborwing_air_eer.mwb`.
8. Click **File -> Export -> Export as PNG...** and save as `harborwing_air_eer.png`.

---

## 9. Explainer Video Checklist & Presentation Script

Use this 3-to-5-minute script while recording with your face visible (using OBS, Windows Snipping Tool, or Zoom):

| Time | Slide / Screen | Talking Points |
|---|---|---|
| **0:00 - 0:45** | **Camera on Face + Title Screen** | Introduce yourself, the course (IT8), and HarborWing Air. State the project goal: replacing spreadsheet anomalies with an 11-table relational database. |
| **0:45 - 1:45** | **MySQL Workbench EER Diagram** | Display the diagram. Walk through the key relationships: `passenger` to `reservation`, the two N:M linking tables (`reservation_payment` and `reservation_leg`), and why scheduled vs actual flight times are kept separate. |
| **1:45 - 2:45** | **Database Seeding & Row Counts** | Show your terminal running `python generate_data.py` (mentioning fixed seed 42). Show the row-count query execution proving **every single table has $\ge 50$ rows**. |
| **2:45 - 4:00** | **SQL Query Execution & CTE Demo** | Run Query 1 in Workbench. Point out how CTE pre-aggregation completely prevents payment inflation for bookings with multiple payments and multiple legs. Show Query 2, 3, and 4. |
| **4:00 - 4:30** | **Conclusion & Limitations** | Briefly mention the explicit limitations: shared payment allocation and party size vs traveler identity. Close the presentation. |

---

## 10. Verification Output Summary

```
+---------------------+-----------+---------------+
| table_name          | row_count | status        |
+---------------------+-----------+---------------+
| airport             |        55 | PASS (>= 50)  |
| booking_agent       |        60 | PASS (>= 50)  |
| calendar_date       |       100 | PASS (>= 50)  |
| passenger           |        75 | PASS (>= 50)  |
| flight_schedule     |        60 | PASS (>= 50)  |
| flight_cost         |        65 | PASS (>= 50)  |
| flight_leg          |        70 | PASS (>= 50)  |
| payment             |        75 | PASS (>= 50)  |
| reservation         |        75 | PASS (>= 50)  |
| reservation_payment |        85 | PASS (>= 50)  |
| reservation_leg     |        90 | PASS (>= 50)  |
+---------------------+-----------+---------------+
```
