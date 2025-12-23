CREATE TABLE appointment (
    appointment_id INT,
    patient_id BIGINT,
    doctor_id BIGINT,
    appointment_date DATE,
    status VARCHAR,
    visit_reason VARCHAR
);

CREATE TABLE billing (
    bill_id INT,
    appointment_id INT,
    amount BIGINT,
    insurance BIGINT,
    patient_paid BIGINT
);

CREATE TABLE diagnosis (
    diagnosis_id INT,
    appointment_id BIGINT,
    diagnosis_code VARCHAR,
    diagnosis_description VARCHAR
);

CREATE TABLE doctors (
    doctor_id INT,
    doctor_name VARCHAR,
    specialty VARCHAR,
    clinic_location VARCHAR
);

CREATE TABLE medications (
    med_id INT,
    patient_id BIGINT,
    medication_name VARCHAR,
    dosage VARCHAR,
    start_date DATE,
    end_date DATE
);

CREATE TABLE patients (
    patient_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    gender CHAR,
    date_of_birth DATE,
    city VARCHAR,
    insurance_provider VARCHAR
);
