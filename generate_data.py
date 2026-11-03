"""
HarborWing Air - Part 1: Synthetic Data Generator
-------------------------------------------------
Generates realistic, deterministic synthetic data for all 11 tables in the
HarborWing Air relational database using Python's Faker library.

Requirements satisfied:
1. Every table populated with at least 50 rows (configured for 55-90 rows).
2. Fixed random seed (seed = 42) for 100% reproducible data generation.
3. Strict parent-to-child insertion order to respect referential integrity.
4. Includes direct bookings (booking_agent_id = NULL) and agent-assisted bookings.
5. Includes reservations with multiple payments (split payments).
6. Includes reservations with multiple flight legs (connecting journeys).
7. Includes shared payments covering multiple reservations.
8. Includes varied flight-cost validity periods referencing calendar dates.
9. Includes completed flight legs with actual timestamps, and upcoming legs with NULL actual times.
10. Generates clean SQL file (seed_data.sql) and optionally seeds MySQL database directly.
"""

import sys
import random
from datetime import date, datetime, timedelta
from faker import Faker

# Fixed seed for repeatable generation
RANDOM_SEED = 42
random.seed(RANDOM_SEED)
Faker.seed(RANDOM_SEED)
fake = Faker()

def generate_all():
    print("[*] Generating HarborWing Air synthetic dataset (seed=42)...")
    
    # -------------------------------------------------------------------------
    # 1. calendar_date (100 rows)
    # -------------------------------------------------------------------------
    calendar_dates = []
    start_date = date(2026, 1, 1)
    for i in range(100):
        current_date = start_date + timedelta(days=i)
        is_business_day = 1 if current_date.weekday() < 5 else 0
        calendar_dates.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "day_of_the_month": current_date.day,
            "business_day_indicator": is_business_day
        })
    print(f" -> Generated {len(calendar_dates)} rows for calendar_date")

    # -------------------------------------------------------------------------
    # 2. airport (55 coastal & island airports)
    # -------------------------------------------------------------------------
    airport_raw = [
        ("SFO", "San Francisco International Airport", "San Francisco, CA, USA"),
        ("LAX", "Los Angeles International Airport", "Los Angeles, CA, USA"),
        ("SEA", "Seattle-Tacoma International Airport", "Seattle, WA, USA"),
        ("PDX", "Portland International Airport", "Portland, OR, USA"),
        ("SAN", "San Diego International Airport", "San Diego, CA, USA"),
        ("OAK", "Oakland International Airport", "Oakland, CA, USA"),
        ("SJC", "San Jose Mineta International Airport", "San Jose, CA, USA"),
        ("HNL", "Daniel K. Inouye International Airport", "Honolulu, HI, USA"),
        ("OGG", "Kahului Airport", "Maui, HI, USA"),
        ("KOA", "Ellison Onizuka Kona International Airport", "Kona, HI, USA"),
        ("LIH", "Lihue Airport", "Kauai, HI, USA"),
        ("ANC", "Ted Stevens Anchorage International Airport", "Anchorage, AK, USA"),
        ("JNU", "Juneau International Airport", "Juneau, AK, USA"),
        ("KTN", "Ketchikan International Airport", "Ketchikan, AK, USA"),
        ("SIT", "Sitka Rocky Gutierrez Airport", "Sitka, AK, USA"),
        ("MIA", "Miami International Airport", "Miami, FL, USA"),
        ("FLL", "Fort Lauderdale-Hollywood International Airport", "Fort Lauderdale, FL, USA"),
        ("TPA", "Tampa International Airport", "Tampa, FL, USA"),
        ("RSW", "Southwest Florida International Airport", "Fort Myers, FL, USA"),
        ("PBI", "Palm Beach International Airport", "West Palm Beach, FL, USA"),
        ("EYW", "Key West International Airport", "Key West, FL, USA"),
        ("CHS", "Charleston International Airport", "Charleston, SC, USA"),
        ("SAV", "Savannah/Hilton Head International Airport", "Savannah, GA, USA"),
        ("PWM", "Portland International Jetport", "Portland, ME, USA"),
        ("BOS", "Logan International Airport", "Boston, MA, USA"),
        ("PVD", "Rhode Island T. F. Green International Airport", "Providence, RI, USA"),
        ("ACK", "Nantucket Memorial Airport", "Nantucket, MA, USA"),
        ("MVY", "Martha's Vineyard Airport", "Martha's Vineyard, MA, USA"),
        ("ISP", "Long Island MacArthur Airport", "Islip, NY, USA"),
        ("HVN", "Tweed New Haven Airport", "New Haven, CT, USA"),
        ("BWI", "Baltimore/Washington International Airport", "Baltimore, MD, USA"),
        ("ORF", "Norfolk International Airport", "Norfolk, VA, USA"),
        ("ILM", "Wilmington International Airport", "Wilmington, NC, USA"),
        ("MYR", "Myrtle Beach International Airport", "Myrtle Beach, SC, USA"),
        ("JAX", "Jacksonville International Airport", "Jacksonville, FL, USA"),
        ("MOB", "Mobile Regional Airport", "Mobile, AL, USA"),
        ("GPT", "Gulfport-Biloxi International Airport", "Gulfport, MS, USA"),
        ("MSY", "Louis Armstrong New Orleans International Airport", "New Orleans, LA, USA"),
        ("BPT", "Jack Brooks Regional Airport", "Beaumont, TX, USA"),
        ("GLS", "Scholes International Airport", "Galveston, TX, USA"),
        ("CRP", "Corpus Christi International Airport", "Corpus Christi, TX, USA"),
        ("HRL", "Valley International Airport", "Harlingen, TX, USA"),
        ("BRO", "Brownsville/South Padre Island International Airport", "Brownsville, TX, USA"),
        ("AST", "Astoria Regional Airport", "Astoria, OR, USA"),
        ("CLM", "William R. Fairchild International Airport", "Port Angeles, WA, USA"),
        ("BLI", "Bellingham International Airport", "Bellingham, WA, USA"),
        ("YVR", "Vancouver International Airport", "Vancouver, BC, Canada"),
        ("YYJ", "Victoria International Airport", "Victoria, BC, Canada"),
        ("SBA", "Santa Barbara Municipal Airport", "Santa Barbara, CA, USA"),
        ("MRY", "Monterey Regional Airport", "Monterey, CA, USA"),
        ("SBP", "San Luis Obispo County Regional Airport", "San Luis Obispo, CA, USA"),
        ("SMX", "Santa Maria Public Airport", "Santa Maria, CA, USA"),
        ("OXR", "Oxnard Airport", "Oxnard, CA, USA"),
        ("LGB", "Long Beach Airport", "Long Beach, CA, USA"),
        ("SNA", "John Wayne Airport", "Santa Ana, CA, USA")
    ]
    airports = []
    for code, name, loc in airport_raw:
        airports.append({
            "airport_code": code,
            "name": name,
            "location": loc,
            "other_details": f"Regional coastal gateway operating under IATA code {code}."
        })
    print(f" -> Generated {len(airports)} rows for airport")

    # -------------------------------------------------------------------------
    # 3. booking_agent (60 rows)
    # -------------------------------------------------------------------------
    agency_names = [
        "Coastal Wings Travel", "Island Hopper Services", "Pacific Crest Tours",
        "Bay Area Voyage", "Cascadia Travel Group", "Seaside Booking Partners",
        "Archipelago Voyages", "Bluewater Expeditions", "Harbor Breeze Travels",
        "Northwest Flight Desk", "Emerald Isle Travel", "Tidal Wave Bookings",
        "Golden Coast Agency", "Olympic Peninsula Travel", "Puget Sound Getaways",
        "Strait Horizons", "San Juan Island Expeditions", "Oceanic Flight Link",
        "Maritime Gateway Co.", "Sea Breeze Itineraries", "Coastal Link Travel",
        "Reef & Shore Travel", "Azure Sky Bookings", "Pelican Travel Group",
        "Nautilus World Travel", "Sea Haven Agency", "Wavecrest Travel Bureau",
        "Mariner Global Travel", "Lighthouse Flight Brokers", "Cape & Island Tours"
    ]
    booking_agents = []
    for i in range(1, 61):
        base_name = agency_names[(i - 1) % len(agency_names)]
        suffix = f"Branch #{i}" if i > len(agency_names) else "HQ"
        agent_name = f"{base_name} - {suffix}"
        tier = random.choice(["Gold Tier Partner", "Silver Agency", "Authorized Regional Broker", "Direct Corporate Partner"])
        booking_agents.append({
            "agent_id": i,
            "name": agent_name,
            "additional_details": f"{tier}. Support line: +1-800-{random.randint(100,999)}-{random.randint(1000,9999)}"
        })
    print(f" -> Generated {len(booking_agents)} rows for booking_agent")

    # -------------------------------------------------------------------------
    # 4. passenger (75 rows)
    # -------------------------------------------------------------------------
    passengers = []
    used_emails = set()
    for i in range(1, 76):
        fn = fake.first_name()
        has_second = random.random() < 0.45
        sn = fake.first_name() if has_second else None
        ln = fake.last_name()
        
        email_cand = f"{fn.lower()}.{ln.lower()}{i}@example.com".replace("'", "")
        while email_cand in used_emails:
            email_cand = f"{fn.lower()}.{ln.lower()}{random.randint(100,9999)}@example.com".replace("'", "")
        used_emails.add(email_cand)
        
        passengers.append({
            "passenger_id": i,
            "first_name": fn,
            "second_name": sn,
            "last_name": ln,
            "phone_number": fake.phone_number()[:30],
            "email_address": email_cand,
            "address_lines": fake.street_address().replace("'", "''"),
            "city": fake.city().replace("'", "''"),
            "state_province_county": fake.state().replace("'", "''"),
            "country": "United States",
            "other_details": f"Frequent flyer membership: HW-{random.randint(100000, 999999)}"
        })
    print(f" -> Generated {len(passengers)} rows for passenger")

    # -------------------------------------------------------------------------
    # 5. flight_schedule (60 rows)
    # -------------------------------------------------------------------------
    aircraft_types = ["DHC-8-400", "ATR-72-600", "Cessna 208 Caravan", "Embraer E175"]
    flight_schedules = []
    airport_codes = [a["airport_code"] for a in airports]
    
    base_schedule_time = datetime(2026, 2, 1, 6, 0, 0)
    for i in range(1, 61):
        flight_num = f"HW{100 + i}"
        origin = airport_codes[(i * 3) % len(airport_codes)]
        dest = airport_codes[(i * 3 + 5) % len(airport_codes)]
        if origin == dest:
            dest = airport_codes[(i * 3 + 7) % len(airport_codes)]
            
        dep_time = base_schedule_time + timedelta(days=(i % 25), hours=(i * 2) % 14, minutes=(i * 15) % 60)
        flight_duration = timedelta(minutes=random.randint(45, 150))
        arr_time = dep_time + flight_duration
        
        flight_schedules.append({
            "flight_number": flight_num,
            "airline_code": "HW",
            "usual_aircraft_type_code": random.choice(aircraft_types),
            "origin_airport": origin,
            "destination_airport": dest,
            "scheduled_departure_time": dep_time.strftime("%Y-%m-%d %H:%M:%S"),
            "scheduled_arrival_time": arr_time.strftime("%Y-%m-%d %H:%M:%S")
        })
    print(f" -> Generated {len(flight_schedules)} rows for flight_schedule")

    # -------------------------------------------------------------------------
    # 6. flight_cost (65 rows)
    # -------------------------------------------------------------------------
    flight_costs = []
    used_cost_keys = set()
    calendar_date_strings = [cd["date"] for cd in calendar_dates]
    
    for i in range(1, 66):
        sched = flight_schedules[(i - 1) % len(flight_schedules)]
        flight_num = sched["flight_number"]
        ac_type = sched["usual_aircraft_type_code"]
        
        # Valid-from chosen from first 40 calendar dates
        start_idx = (i * 2) % 40
        valid_from = calendar_date_strings[start_idx]
        
        # Valid-to chosen from later calendar dates (valid_to >= valid_from)
        end_idx = min(start_idx + random.randint(15, 45), len(calendar_date_strings) - 1)
        valid_to = calendar_date_strings[end_idx]
        
        key = (flight_num, ac_type, valid_from)
        if key in used_cost_keys:
            # Shift start index to prevent collision
            start_idx = (start_idx + 3) % 40
            valid_from = calendar_date_strings[start_idx]
            end_idx = min(start_idx + random.randint(15, 45), len(calendar_date_strings) - 1)
            valid_to = calendar_date_strings[end_idx]
            key = (flight_num, ac_type, valid_from)
            
        used_cost_keys.add(key)
        cost_amount = round(random.uniform(95.0, 480.0), 2)
        
        flight_costs.append({
            "flight_number": flight_num,
            "aircraft_type_code": ac_type,
            "valid_from_date": valid_from,
            "valid_to_date": valid_to,
            "cost_amount": cost_amount
        })
    print(f" -> Generated {len(flight_costs)} rows for flight_cost")

    # -------------------------------------------------------------------------
    # 7. flight_leg (70 rows)
    # -------------------------------------------------------------------------
    flight_legs = []
    for i in range(1, 71):
        sched = flight_schedules[(i - 1) % len(flight_schedules)]
        sched_dep = datetime.strptime(sched["scheduled_departure_time"], "%Y-%m-%d %H:%M:%S")
        sched_arr = datetime.strptime(sched["scheduled_arrival_time"], "%Y-%m-%d %H:%M:%S")
        duration = sched_arr - sched_dep
        
        # In 70% of rows, flight operated; in 30% of rows, actual times are NULL (upcoming flight)
        has_operated = (i <= 50)
        if has_operated:
            delay_minutes = random.randint(-10, 45) # Slight early or delayed departure
            act_dep = sched_dep + timedelta(minutes=delay_minutes)
            act_arr = act_dep + duration + timedelta(minutes=random.randint(-5, 15))
            act_dep_str = act_dep.strftime("%Y-%m-%d %H:%M:%S")
            act_arr_str = act_arr.strftime("%Y-%m-%d %H:%M:%S")
        else:
            act_dep_str = None
            act_arr_str = None
            
        flight_legs.append({
            "leg_id": i,
            "scheduled_flight": sched["flight_number"],
            "origin_airport": sched["origin_airport"],
            "destination_airport": sched["destination_airport"],
            "actual_departure_time": act_dep_str,
            "actual_arrival_time": act_arr_str
        })
    print(f" -> Generated {len(flight_legs)} rows for flight_leg")

    # -------------------------------------------------------------------------
    # 8. payment (75 rows)
    # -------------------------------------------------------------------------
    payment_statuses = ["COMPLETED", "COMPLETED", "COMPLETED", "PENDING", "REFUNDED"]
    payments = []
    base_payment_date = datetime(2026, 1, 15, 8, 30, 0)
    for i in range(1, 76):
        p_date = base_payment_date + timedelta(days=i % 45, hours=(i * 3) % 24, minutes=(i * 17) % 60)
        p_status = payment_statuses[i % len(payment_statuses)]
        amount = round(random.uniform(110.0, 1650.0), 2)
        payments.append({
            "payment_id": i,
            "payment_status_code": p_status,
            "payment_date": p_date.strftime("%Y-%m-%d %H:%M:%S"),
            "payment_amount": amount
        })
    print(f" -> Generated {len(payments)} rows for payment")

    # -------------------------------------------------------------------------
    # 9. reservation (75 rows)
    # -------------------------------------------------------------------------
    res_statuses = ["CONFIRMED", "CONFIRMED", "COMPLETED", "COMPLETED", "HELD", "CANCELLED"]
    ticket_types = ["STANDARD", "FLEXIBLE", "NONREFUNDABLE", "PROMO_ISLAND"]
    travel_classes = ["ECONOMY", "PREMIUM_ECONOMY", "FIRST"]
    reservations = []
    
    base_res_date = datetime(2026, 1, 10, 9, 0, 0)
    for i in range(1, 76):
        main_pax = ((i - 1) % len(passengers)) + 1
        # Direct vs agent-assisted: ~40% direct (NULL), ~60% agent
        is_agent = (i % 5 != 0)
        agent_id = ((i * 2) % len(booking_agents)) + 1 if is_agent else None
        
        res_date = base_res_date + timedelta(days=i % 40, hours=(i * 2) % 24, minutes=(i * 13) % 60)
        party_size = random.choices([1, 2, 3, 4, 5], weights=[0.45, 0.30, 0.12, 0.08, 0.05])[0]
        
        reservations.append({
            "reservation_id": i,
            "main_passenger_id": main_pax,
            "booking_agent_id": agent_id,
            "reservation_status_code": random.choice(res_statuses),
            "ticket_type_code": random.choice(ticket_types),
            "travel_class_code": random.choice(travel_classes),
            "creation_date_time": res_date.strftime("%Y-%m-%d %H:%M:%S"),
            "number_in_party": party_size
        })
    print(f" -> Generated {len(reservations)} rows for reservation")

    # -------------------------------------------------------------------------
    # 10. reservation_payment (85 rows)
    # -------------------------------------------------------------------------
    # Requirements:
    # - Reservations with several payments (e.g. split card / installment)
    # - Payments shared by several reservations (e.g. corporate or group payment)
    # - Duplicate pairs not allowed
    # - No allocation amount stored
    reservation_payments = []
    res_payment_pairs = set()

    # 1:1 base matching for first 65 reservations
    for i in range(1, 66):
        r_id = i
        p_id = i
        res_payment_pairs.add((r_id, p_id))
        reservation_payments.append({"reservation_id": r_id, "payment_id": p_id})

    # Add second payment to some reservations (multi-payment / split payment)
    # e.g., reservations 1 to 10 have an additional payment
    for r_id in range(1, 11):
        extra_p_id = 65 + r_id # payments 66-75
        if (r_id, extra_p_id) not in res_payment_pairs:
            res_payment_pairs.add((r_id, extra_p_id))
            reservation_payments.append({"reservation_id": r_id, "payment_id": extra_p_id})

    # Add shared payments: single payment covering multiple reservations
    # e.g., payment 20 also covers reservations 66, 67, 68
    shared_payments = [20, 21, 22, 23, 24]
    target_res = [66, 67, 68, 69, 70, 71, 72, 73, 74, 75]
    for idx, r_id in enumerate(target_res):
        shared_p = shared_payments[idx % len(shared_payments)]
        if (r_id, shared_p) not in res_payment_pairs:
            res_payment_pairs.add((r_id, shared_p))
            reservation_payments.append({"reservation_id": r_id, "payment_id": shared_p})

    print(f" -> Generated {len(reservation_payments)} rows for reservation_payment (linking table)")

    # -------------------------------------------------------------------------
    # 11. reservation_leg (90 rows)
    # -------------------------------------------------------------------------
    # Requirements:
    # - Reservations with several legs (connecting flights)
    # - Legs linked to several reservations
    # - Duplicate pairs not allowed
    reservation_legs = []
    res_leg_pairs = set()

    # 1:1 base matching for all 75 reservations
    for i in range(1, 76):
        r_id = i
        leg_id = ((i - 1) % len(flight_legs)) + 1
        res_leg_pairs.add((r_id, leg_id))
        reservation_legs.append({"reservation_id": r_id, "leg_id": leg_id})

    # Add connecting leg (2nd leg) for reservations 1 to 15
    for r_id in range(1, 16):
        second_leg = ((r_id + 5) % len(flight_legs)) + 1
        if (r_id, second_leg) not in res_leg_pairs:
            res_leg_pairs.add((r_id, second_leg))
            reservation_legs.append({"reservation_id": r_id, "leg_id": second_leg})

    print(f" -> Generated {len(reservation_legs)} rows for reservation_leg (linking table)")

    return {
        "calendar_date": calendar_dates,
        "airport": airports,
        "booking_agent": booking_agents,
        "passenger": passengers,
        "flight_schedule": flight_schedules,
        "flight_cost": flight_costs,
        "flight_leg": flight_legs,
        "payment": payments,
        "reservation": reservations,
        "reservation_payment": reservation_payments,
        "reservation_leg": reservation_legs
    }

def format_val(val):
    if val is None:
        return "NULL"
    elif isinstance(val, (int, float)):
        return str(val)
    elif isinstance(val, bool):
        return "1" if val else "0"
    else:
        escaped = str(val).replace("'", "''")
        return f"'{escaped}'"

def write_sql_seed_file(data, filepath):
    print(f"[*] Writing standalone SQL seed script to {filepath}...")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("-- ============================================================================\n")
        f.write("-- HarborWing Air Relational Database - Synthetic Seed Data\n")
        f.write("-- Deterministically generated using Python Faker (seed=42)\n")
        f.write("-- Every table contains >= 50 rows\n")
        f.write("-- ============================================================================\n\n")
        f.write("USE harborwing_air;\n\n")
        f.write("SET FOREIGN_KEY_CHECKS = 0;\n\n")

        for table_name, rows in data.items():
            if not rows:
                continue
            cols = list(rows[0].keys())
            f.write(f"-- ----------------------------------------------------------------------------\n")
            f.write(f"-- Seeding table: {table_name} ({len(rows)} rows)\n")
            f.write(f"-- ----------------------------------------------------------------------------\n")
            f.write(f"INSERT INTO `{table_name}` ({', '.join(cols)}) VALUES\n")
            row_strs = []
            for r in rows:
                vals = [format_val(r[col]) for col in cols]
                row_strs.append(f"  ({', '.join(vals)})")
            f.write(",\n".join(row_strs))
            f.write(";\n\n")

        f.write("SET FOREIGN_KEY_CHECKS = 1;\n")
        f.write("-- Seed completed successfully.\n")
    print(f"[OK] Successfully generated {filepath}!")

def seed_mysql_directly(data, host="localhost", port=3306, user="root", password="root", database="harborwing_air"):
    try:
        import mysql.connector
    except ImportError:
        print("[!] mysql-connector-python not installed; skipping direct database seeding.")
        return

    print(f"[*] Connecting directly to MySQL server at {host}:{port} as '{user}'...")
    try:
        conn = mysql.connector.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )
        cursor = conn.cursor()
        print("[OK] Connected to MySQL!")

        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        for table_name, rows in data.items():
            if not rows:
                continue
            cols = list(rows[0].keys())
            placeholders = ", ".join(["%s"] * len(cols))
            insert_stmt = f"INSERT INTO `{table_name}` ({', '.join(cols)}) VALUES ({placeholders})"
            
            # Prepare row values
            row_data = [[r[col] for col in cols] for r in rows]
            cursor.executemany(insert_stmt, row_data)
            print(f" -> Inserted {cursor.rowcount} rows into `{table_name}`")

        cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
        conn.commit()
        cursor.close()
        conn.close()
        print("[OK] Direct MySQL database seeding complete!")
    except Exception as e:
        print(f"[!] Direct MySQL seeding encountered an error: {e}")
        print("    You can still use the generated seed_data.sql in MySQL Workbench!")

if __name__ == "__main__":
    dataset = generate_all()
    sql_path = "C:\\Users\\HomePC\\.gemini\\antigravity\\scratch\\harborwing-air\\seed_data.sql"
    write_sql_seed_file(dataset, sql_path)
    
    # Attempt direct seeding into active MySQL instance
    seed_mysql_directly(dataset)
