-- =====================================================
-- CREATE TABLES - TEXAS INSURANCE CLAIMS
-- Execute in INSURANCE_CLAIMS_DB.DATA schema
-- =====================================================

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE INSURANCE_CLAIMS_WH;
USE DATABASE INSURANCE_CLAIMS_DB;
USE SCHEMA DATA;

-- =====================================================
-- TABLE 1: DIM_CLAIM_TYPE
-- =====================================================

CREATE OR REPLACE TABLE DIM_CLAIM_TYPE (
    claim_type VARCHAR(20) PRIMARY KEY,
    description VARCHAR(200),
    avg_processing_days INTEGER,
    typical_min_amount DECIMAL(12,2),
    typical_max_amount DECIMAL(12,2)
);

-- =====================================================
-- TABLE 2: DIM_CUSTOMER
-- =====================================================

CREATE OR REPLACE TABLE DIM_CUSTOMER (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    age INTEGER,
    gender VARCHAR(10),
    location_city VARCHAR(50),
    location_county VARCHAR(50),
    location_zip VARCHAR(10),
    location_address VARCHAR(200),
    risk_profile VARCHAR(20),
    customer_since DATE,
    coastal_property BOOLEAN
);

-- =====================================================
-- TABLE 3: DIM_POLICY
-- =====================================================

CREATE OR REPLACE TABLE DIM_POLICY (
    policy_id VARCHAR(30) PRIMARY KEY,
    customer_id VARCHAR(20),
    policy_type VARCHAR(20),
    coverage_amount DECIMAL(12,2),
    premium_amount DECIMAL(10,2),
    deductible DECIMAL(10,2),
    start_date DATE,
    end_date DATE,
    policy_status VARCHAR(20),
    underwriter_id VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES DIM_CUSTOMER(customer_id),
    FOREIGN KEY (policy_type) REFERENCES DIM_CLAIM_TYPE(claim_type)
);

-- =====================================================
-- TABLE 4: FACT_CLAIMS
-- =====================================================

CREATE OR REPLACE TABLE FACT_CLAIMS (
    claim_id VARCHAR(30) PRIMARY KEY,
    policy_id VARCHAR(30),
    customer_id VARCHAR(20),
    claim_date DATE,
    report_date DATE,
    claim_amount DECIMAL(12,2),
    settlement_amount DECIMAL(12,2),
    claim_status VARCHAR(30),
    claim_type VARCHAR(20),
    adjuster_id VARCHAR(20),
    loss_description VARCHAR(500),
    loss_location_city VARCHAR(50),
    loss_location_county VARCHAR(50),
    loss_location_address VARCHAR(200),
    weather_related BOOLEAN,
    catastrophe_code VARCHAR(20),
    settlement_date DATE,
    processing_days INTEGER,
    FOREIGN KEY (policy_id) REFERENCES DIM_POLICY(policy_id),
    FOREIGN KEY (customer_id) REFERENCES DIM_CUSTOMER(customer_id),
    FOREIGN KEY (claim_type) REFERENCES DIM_CLAIM_TYPE(claim_type)
);

-- =====================================================
-- VERIFY TABLE CREATION
-- =====================================================

SHOW TABLES;

-- Check table structures
DESC TABLE DIM_CLAIM_TYPE;
DESC TABLE DIM_CUSTOMER;
DESC TABLE DIM_POLICY;
DESC TABLE FACT_CLAIMS;

select * from DIM_CUSTOMER;

select * from dim_policy;

select * from fact_claims;

select * from dim_claim_type;

truncate table dim_customer;
truncate table dim_policy;
truncate table fact_claims;

SELECT FILENAME, CONTENT 
FROM INSURANCE_CLAIMS_DB.DATA.MEDICAL_REPORTS;

--truncate table INSURANCE_CLAIMS_DB.DATA.MEDICAL_REPORTS;
select document_type,count(*) from INSURANCE_CLAIMS_DB.DATA.UNSTRUCTURED_DOCUMENTS
group by document_type;

select * from INSURANCE_CLAIMS_DB.DATA.UNSTRUCTURED_DOCUMENTS; --where document_type = 'Police Report';


select * from fact_claims where claim_id = 'CLM-2025-001590';

select * from dim_policy;
select * from dim_customer;

select * from fact_claims where weather_related = TRUE and loss_location_city = 'Houston';

SELECT 
    CLAIM_ID,
    CLAIM_DATE,
    LOSS_LOCATION_CITY,
    WEATHER_RELATED,
    CLAIM_TYPE
FROM FACT_CLAIMS 
WHERE 
    LOSS_LOCATION_CITY IN ('Houston')
    AND CLAIM_DATE >= DATE '2025-01-01'
    AND (WEATHER_RELATED = TRUE OR CLAIM_TYPE = 'Property')
    --AND CLAIM_ID = 'CLM-2025-002847'
ORDER BY CLAIM_DATE DESC
LIMIT 10;


select * from fact_claims where claim_type ='Life';

Auto           ----> medical / police  
Health         ----> medical
Property       ----> medical / property / police
Life           ---->  medical
-- policy_report_<claim_number>.txt
-- medical_report_<claim_number>.txt
-- property_assessment_<claim_number>.txt
-- adjuster_notes_<claim_number>.txt

