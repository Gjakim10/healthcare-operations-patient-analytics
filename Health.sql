-- 1. List all patients who live in Seattle.
SELECT *
FROM patients
WHERE city = 'Seattle';

-- 2. Find all medications where the dosage is greater than 50mg.
-- Assuming dosage is stored as a string like '50mg', we extract the numeric part.
SELECT *
FROM medications
WHERE CAST(REGEXP_REPLACE(dosage, '[^0-9]', '', 'g') AS INTEGER) > 50;


-- 3. Get all completed appointments in February 2024.
SELECT *
FROM appointment
WHERE status = 'Completed'
  AND EXTRACT(YEAR FROM appointment_date) = 2024
  AND EXTRACT(MONTH FROM appointment_date) = 2;


-- 4. Show each doctor and how many appointments they completed.
SELECT d.doctor_id, d.doctor_name, COUNT(a.appointment_id) AS completed_appointments
FROM doctors d
LEFT JOIN appointment a ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.doctor_name;


-- 5. Find the most common diagnosis in the database.
SELECT diagnosis_description, COUNT(*) AS freq
FROM diagnosis
GROUP BY diagnosis_description
ORDER BY freq DESC
LIMIT 1;


-- 6. List the total billing amount per patient.
SELECT p.patient_id, p.first_name, p.last_name, SUM(b.amount) AS total_billing
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN billing b ON a.appointment_id = b.appointment_id
GROUP BY p.patient_id, p.first_name, p.last_name;


-- 7. Which clinic location has the highest number of appointments?
SELECT d.clinic_location, COUNT(a.appointment_id) AS total_appointments
FROM doctors d
JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY d.clinic_location
ORDER BY total_appointments DESC
LIMIT 1;


-- 8. Identify patients who have more than one diagnosis in 2024.
SELECT p.patient_id, p.first_name, p.last_name, COUNT(d.diagnosis_id) AS num_diagnoses
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN diagnosis d ON a.appointment_id = d.appointment_id
WHERE EXTRACT(YEAR FROM a.appointment_date) = 2024
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(d.diagnosis_id) > 1;


-- 9. Rank doctors by total revenue generated.
SELECT d.doctor_id, d.doctor_name, SUM(b.amount) AS total_revenue,
       RANK() OVER (ORDER BY SUM(b.amount) DESC) AS revenue_rank
FROM doctors d
JOIN appointment a ON d.doctor_id = a.doctor_id
JOIN billing b ON a.appointment_id = b.appointment_id
GROUP BY d.doctor_id, d.doctor_name
ORDER BY total_revenue DESC;


-- 10. For each patient, show their most recent appointment.
SELECT p.patient_id, p.first_name, p.last_name, a.appointment_id, a.appointment_date, a.status
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
WHERE a.appointment_date = (
    SELECT MAX(appointment_date)
    FROM appointment
    WHERE patient_id = p.patient_id
);


-- 11. Identify patients whose insurance covered less than 70% of their bill.
SELECT p.patient_id, p.first_name, p.last_name, b.amount, b.insurance,
       ROUND((b.insurance::DECIMAL / b.amount) * 100, 2) AS insurance_coverage_percent
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN billing b ON a.appointment_id = b.appointment_id
WHERE (b.insurance::DECIMAL / b.amount) < 0.7;


-- 12. Identify all diabetic patients and list their last medication renewal date.
-- Assuming diagnosis_code for diabetes contains 'E10' or 'E11' (ICD-10 codes)
SELECT p.patient_id, p.first_name, p.last_name, MAX(m.end_date) AS last_medication_date
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN diagnosis d ON a.appointment_id = d.appointment_id
JOIN medications m ON p.patient_id = m.patient_id
WHERE d.diagnosis_description ILIKE '%diabetes%'
GROUP BY p.patient_id, p.first_name, p.last_name;


-- 13. Which doctor has the lowest no-show rate?
-- Assuming "no-show" is represented by status = 'Cancelled'
SELECT d.doctor_id, d.doctor_name,
       COUNT(CASE WHEN a.status = 'Cancelled' THEN 1 END)::DECIMAL / COUNT(*) AS no_show_rate
FROM doctors d
JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.doctor_name
ORDER BY no_show_rate ASC
LIMIT 1;


-- 14. Which age group has the highest incidence of hypertension (I10)?
-- Assuming age groups: <30, 30-44, 45-59, 60+
SELECT 
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(p.date_of_birth)) < 30 THEN '<30'
        WHEN EXTRACT(YEAR FROM AGE(p.date_of_birth)) BETWEEN 30 AND 44 THEN '30-44'
        WHEN EXTRACT(YEAR FROM AGE(p.date_of_birth)) BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+' 
    END AS age_group,
    COUNT(*) AS hypertension_cases
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN diagnosis d ON a.appointment_id = d.appointment_id
WHERE d.diagnosis_code = 'I10'
GROUP BY age_group
ORDER BY hypertension_cases DESC
LIMIT 1;


-- 15. Which insurance provider covers the highest average amount?
SELECT p.insurance_provider, AVG(b.insurance) AS avg_coverage
FROM patients p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN billing b ON a.appointment_id = b.appointment_id
GROUP BY p.insurance_provider
ORDER BY avg_coverage DESC
LIMIT 1;


-- 16. Determine peak days of the week for appointments.
SELECT TO_CHAR(appointment_date, 'Day') AS day_of_week, COUNT(*) AS total_appointments
FROM appointment
GROUP BY day_of_week
ORDER BY total_appointments DESC;


-- 17a. Identify patients who received multiple medications on the same day.
SELECT patient_id, start_date, COUNT(med_id) AS meds_count
FROM medications
GROUP BY patient_id, start_date
HAVING COUNT(med_id) > 1;


-- 17b. Find doctors who only see patients from a single city.
SELECT d.doctor_id, d.doctor_name, ARRAY_AGG(DISTINCT p.city) AS cities
FROM doctors d
JOIN appointment a ON d.doctor_id = a.doctor_id
JOIN patients p ON a.patient_id = p.patient_id
GROUP BY d.doctor_id, d.doctor_name
HAVING COUNT(DISTINCT p.city) = 1;


-- 17c. List patients whose last diagnosis matches the first diagnosis they ever received.
WITH first_last_diagnosis AS (
    SELECT a.patient_id,
           FIRST_VALUE(d.diagnosis_code) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date ASC) AS first_diag,
           LAST_VALUE(d.diagnosis_code) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_diag
    FROM appointment a
    JOIN diagnosis d ON a.appointment_id = d.appointment_id
)
SELECT DISTINCT patient_id
FROM first_last_diagnosis
WHERE first_diag = last_diag;


-- 18a. Patients with multiple medications on the same day:
-- Query: Groups medications by patient and date, counts how many were prescribed per day, and filters for counts > 1.
-- Outcome: Highlights patients receiving multiple treatments simultaneously—useful for checking polypharmacy risks.

-- 18b. Doctors who only see patients from a single city:
-- Query: Aggregates distinct cities per doctor and selects only those doctors who see patients from exactly one city.
-- Outcome: Reveals doctors who serve a very localized patient population—useful for regional resource planning or identifying clinic specialization.

-- 18c. Patients whose first and last diagnoses are the same:
-- Query: Uses window functions FIRST_VALUE and LAST_VALUE to find patients whose medical condition has persisted from the first to the most recent appointment.
-- Outcome: Identifies chronic conditions or long-term follow-ups—valuable for tracking treatment effectiveness or continuity of care.


