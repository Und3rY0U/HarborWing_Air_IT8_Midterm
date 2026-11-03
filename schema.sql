-- ============================================================================
-- HarborWing Air Relational Database Schema
-- Midterm Drill / IT8 - Part 1
-- Database System: MySQL 8.0+ / MariaDB 10.5+
-- Storage Engine: InnoDB (for full ACID transaction & foreign-key enforcement)
-- Timestamp Convention: UTC (DATETIME)
-- ============================================================================

-- Drop schema if exists for reproducible reset process
DROP DATABASE IF EXISTS harborwing_air;
CREATE DATABASE harborwing_air 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

USE harborwing_air;

-- ----------------------------------------------------------------------------
-- 1. Table: booking_agent
-- Purpose: Stores travel agencies / booking agents who make reservations on
--          behalf of passengers.
-- Deletion Rule: ON DELETE SET NULL in `reservation` ensures booking records 
--                remain intact even if an agent account is retired.
-- ----------------------------------------------------------------------------
CREATE TABLE booking_agent (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    additional_details TEXT NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Table: passenger
-- Purpose: Master catalog of individual customers/passengers.
-- Business Rules: Normalized entity preventing repeated passenger details 
--                 across multiple bookings.
-- Deletion Rule: ON DELETE RESTRICT in `reservation` prevents deleting a
--                passenger with active or historical booking records.
-- ----------------------------------------------------------------------------
CREATE TABLE passenger (
    passenger_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    second_name VARCHAR(50) NULL, -- Optional second name / middle name
    last_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(30) NOT NULL,
    email_address VARCHAR(100) NOT NULL UNIQUE,
    address_lines VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state_province_county VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    other_details TEXT NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. Table: calendar_date
-- Purpose: Date dimension table used to ensure flight cost validity dates are
--          strictly validated against existing calendar dates.
-- Deletion Rule: ON DELETE RESTRICT in `flight_cost` prevents altering calendar 
--                timeline references.
-- ----------------------------------------------------------------------------
CREATE TABLE calendar_date (
    date DATE PRIMARY KEY,
    day_of_the_month INT NOT NULL,
    business_day_indicator BOOLEAN NOT NULL,
    CONSTRAINT chk_day_of_month CHECK (day_of_the_month BETWEEN 1 AND 31)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. Table: airport
-- Purpose: Standardized list of serviced airports (coastal cities & island hubs).
-- Deletion Rule: ON DELETE RESTRICT in schedules and legs prevents deleting an
--                airport that is part of any active or historic flight route.
-- ----------------------------------------------------------------------------
CREATE TABLE airport (
    airport_code CHAR(3) PRIMARY KEY, -- Standard 3-letter IATA code (e.g. SFO, SEA, OAK)
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    other_details TEXT NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. Table: flight_schedule
-- Purpose: Master planned timetable for flights.
-- Simplifying Assumption: Flight number uniquely identifies a schedule in this drill.
-- Validation Constraints: Origin and destination must differ; scheduled arrival 
--                         must be after scheduled departure.
-- Deletion Rule: ON DELETE CASCADE drops dependent legs/costs when a schedule
--                is decommissioned from the system.
-- ----------------------------------------------------------------------------
CREATE TABLE flight_schedule (
    flight_number VARCHAR(10) PRIMARY KEY,
    airline_code CHAR(2) NOT NULL DEFAULT 'HW', -- Externally managed airline code
    usual_aircraft_type_code VARCHAR(20) NOT NULL, -- Externally managed code (e.g. DHC-8, ATR-72)
    origin_airport CHAR(3) NOT NULL,
    destination_airport CHAR(3) NOT NULL,
    scheduled_departure_time DATETIME NOT NULL,
    scheduled_arrival_time DATETIME NOT NULL,
    CONSTRAINT fk_sched_origin FOREIGN KEY (origin_airport)
        REFERENCES airport(airport_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_sched_dest FOREIGN KEY (destination_airport)
        REFERENCES airport(airport_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_sched_origin_dest CHECK (origin_airport <> destination_airport),
    CONSTRAINT chk_sched_times CHECK (scheduled_arrival_time > scheduled_departure_time)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. Table: flight_leg
-- Purpose: Represents the actual flight operation / instance of a scheduled flight.
-- Business Rules: Origin and destination must differ. Actual times may be NULL
--                 if the flight has not operated yet.
-- ----------------------------------------------------------------------------
CREATE TABLE flight_leg (
    leg_id INT AUTO_INCREMENT PRIMARY KEY,
    scheduled_flight VARCHAR(10) NOT NULL,
    origin_airport CHAR(3) NOT NULL,
    destination_airport CHAR(3) NOT NULL,
    actual_departure_time DATETIME NULL,
    actual_arrival_time DATETIME NULL,
    CONSTRAINT fk_leg_sched FOREIGN KEY (scheduled_flight)
        REFERENCES flight_schedule(flight_number)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_leg_origin FOREIGN KEY (origin_airport)
        REFERENCES airport(airport_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_leg_dest FOREIGN KEY (destination_airport)
        REFERENCES airport(airport_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_leg_origin_dest CHECK (origin_airport <> destination_airport),
    CONSTRAINT chk_leg_actual_times CHECK (
        actual_arrival_time IS NULL 
        OR actual_departure_time IS NULL 
        OR actual_arrival_time >= actual_departure_time
    )
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 7. Table: flight_cost
-- Purpose: Historical and active pricing rules for flight schedules and aircraft types.
-- Business Rules: Flight number, aircraft type, and valid-from date together identify
--                 a cost record (Composite Primary Key).
--                 Both validity dates reference the calendar table.
--                 valid_to_date >= valid_from_date. Costs non-negative.
-- ----------------------------------------------------------------------------
CREATE TABLE flight_cost (
    flight_number VARCHAR(10) NOT NULL,
    aircraft_type_code VARCHAR(20) NOT NULL,
    valid_from_date DATE NOT NULL,
    valid_to_date DATE NOT NULL,
    cost_amount DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (flight_number, aircraft_type_code, valid_from_date),
    CONSTRAINT fk_cost_flight FOREIGN KEY (flight_number)
        REFERENCES flight_schedule(flight_number)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cost_valid_from FOREIGN KEY (valid_from_date)
        REFERENCES calendar_date(date)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_cost_valid_to FOREIGN KEY (valid_to_date)
        REFERENCES calendar_date(date)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_cost_validity CHECK (valid_to_date >= valid_from_date),
    CONSTRAINT chk_cost_amount CHECK (cost_amount >= 0)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 8. Table: payment
-- Purpose: Records financial payments made by passengers/agents.
-- Business Rules: Payment amounts must be strictly positive.
-- ----------------------------------------------------------------------------
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_status_code VARCHAR(20) NOT NULL, -- Externally managed: COMPLETED, PENDING, REFUNDED
    payment_date DATETIME NOT NULL,
    payment_amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT chk_payment_amount CHECK (payment_amount > 0)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 9. Table: reservation
-- Purpose: Holds customer booking headers.
-- Business Rules: Each reservation has exactly one main passenger.
--                 Zero or one booking agent (NULL when booked directly).
--                 Party size must be > 0.
-- ----------------------------------------------------------------------------
CREATE TABLE reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    main_passenger_id INT NOT NULL,
    booking_agent_id INT NULL, -- NULL represents direct booking by customer
    reservation_status_code VARCHAR(20) NOT NULL, -- Externally managed: CONFIRMED, CANCELLED, COMPLETED
    ticket_type_code VARCHAR(20) NOT NULL,        -- Externally managed: STANDARD, FLEXIBLE, NONREFUNDABLE
    travel_class_code VARCHAR(20) NOT NULL,       -- Externally managed: ECONOMY, PREMIUM_ECONOMY, FIRST
    creation_date_time DATETIME NOT NULL,
    number_in_party INT NOT NULL,
    CONSTRAINT fk_res_passenger FOREIGN KEY (main_passenger_id)
        REFERENCES passenger(passenger_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_res_agent FOREIGN KEY (booking_agent_id)
        REFERENCES booking_agent(agent_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_res_party_size CHECK (number_in_party > 0)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 10. Table: reservation_payment (Linking table)
-- Purpose: Resolves the Many-to-Many relationship between reservations and payments.
-- Business Rules: A reservation can have many payments; a payment can cover multiple
--                 reservations. Duplicate pairs disallowed (enforced by PK).
--                 NO payment-allocation amount is stored per explicit requirement.
-- Deletion Rule: ON DELETE CASCADE clears link if either reservation or payment is deleted.
-- ----------------------------------------------------------------------------
CREATE TABLE reservation_payment (
    reservation_id INT NOT NULL,
    payment_id INT NOT NULL,
    PRIMARY KEY (reservation_id, payment_id),
    CONSTRAINT fk_rp_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation(reservation_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_rp_payment FOREIGN KEY (payment_id)
        REFERENCES payment(payment_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 11. Table: reservation_leg (Linking table)
-- Purpose: Resolves the Many-to-Many relationship between reservations and flight legs.
-- Business Rules: A reservation can include multiple flight legs (connections).
--                 A flight leg carries passengers from multiple reservations.
--                 Duplicate pairs disallowed (enforced by PK).
-- Deletion Rule: ON DELETE CASCADE clears link if either reservation or leg is deleted.
-- ----------------------------------------------------------------------------
CREATE TABLE reservation_leg (
    reservation_id INT NOT NULL,
    leg_id INT NOT NULL,
    PRIMARY KEY (reservation_id, leg_id),
    CONSTRAINT fk_rl_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation(reservation_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_rl_leg FOREIGN KEY (leg_id)
        REFERENCES flight_leg(leg_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- Secondary Indexes for Common Searches and Joins
-- ============================================================================
CREATE INDEX idx_flight_schedule_route ON flight_schedule(origin_airport, destination_airport);
CREATE INDEX idx_flight_leg_schedule ON flight_leg(scheduled_flight);
CREATE INDEX idx_flight_leg_route ON flight_leg(origin_airport, destination_airport);
CREATE INDEX idx_flight_leg_dates ON flight_leg(actual_departure_time, actual_arrival_time);
CREATE INDEX idx_flight_cost_lookup ON flight_cost(flight_number, valid_from_date, valid_to_date);
CREATE INDEX idx_reservation_passenger ON reservation(main_passenger_id);
CREATE INDEX idx_reservation_agent ON reservation(booking_agent_id);
CREATE INDEX idx_reservation_date ON reservation(creation_date_time);
CREATE INDEX idx_res_payment_payment ON reservation_payment(payment_id);
CREATE INDEX idx_res_leg_leg ON reservation_leg(leg_id);
