USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE INSURANCE_CLAIMS_WH;
USE DATABASE INSURANCE_CLAIMS_DB;
USE SCHEMA DATA;

--1. Preview documents
SELECT * FROM DIRECTORY('@DOCS');

-- 2. Read/process the text files using AI_PARSE_DOCUMENT
CREATE OR REPLACE TEMPORARY TABLE RAW_TEXT AS
SELECT RELATIVE_PATH,TO_VARCHAR(AI_PARSE_DOCUMENT(to_file(file_url), {'mode': 'layout'}):content) AS EXTRACTED_LAYOUT 
    FROM DIRECTORY(@DOCS) 
    WHERE RELATIVE_PATH LIKE '%.txt';

-- 3. display the records     
select * from RAW_TEXT limit 5;

-- 4. Create the table that will be used by Cortex Search service as a tool for Cortex Agents in order to retrieve information from text files
create or replace TABLE DOCS_CHUNKS_TABLE ( 
    RELATIVE_PATH VARCHAR(16777216), -- Relative path to the PDF file
    CHUNK VARCHAR(16777216), -- Piece of text
    CHUNK_INDEX INTEGER, -- Index for the text
    CATEGORY VARCHAR(16777216), -- Will hold the document category to enable filtering
    CLAIM_ID      VARCHAR(30)
);

-- 2. INSERT – uses correct DIRECTORY() column names
INSERT INTO DOCS_CHUNKS_TABLE (RELATIVE_PATH, CLAIM_ID, CATEGORY, CHUNK, CHUNK_INDEX)
SELECT
    d.RELATIVE_PATH,
    REGEXP_SUBSTR(d.RELATIVE_PATH, 'CLM-[A-Z0-9-]+') AS CLAIM_ID,
    CASE
        WHEN d.RELATIVE_PATH ILIKE '%medical%'    THEN 'Medical Report'
        WHEN d.RELATIVE_PATH ILIKE '%police%'     THEN 'Police Report'
        WHEN d.RELATIVE_PATH ILIKE '%property%'   THEN 'Property Assessment'
        WHEN d.RELATIVE_PATH ILIKE '%adjuster%'   THEN 'Adjuster Notes'
        ELSE 'Unknown'
    END AS CATEGORY,
    c.value::TEXT  AS CHUNK,
    c.index::INTEGER AS CHUNK_INDEX
FROM RAW_TEXT d,
LATERAL FLATTEN(
    input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(
        -- Clean the text first → removes the root cause
        REGEXP_REPLACE(d.EXTRACTED_LAYOUT, 
            '(^|\\n)[=\\-_*]{10,}[ \\t]*\\n', '\n', 1, 0),   -- removes ===== lines
        'none', 1500, 200, ['\n\n', '\n', ' ']
    )
) c;

-- 1. Structured intelligence
CREATE CORTEX ANALYST SEMANTIC MODEL INSURANCE_CLAIMS_MODEL
    USING FILE '@DOCS/insurance_claims_semantic.yaml';

create or replace stage semantic_files ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') DIRECTORY = ( ENABLE = true );
COPY FILES
    INTO @semantic_files/
    USING FILE '@DOCS/insurance_claims_semantic.yaml';   

-- Cortex search service 
CREATE OR REPLACE CORTEX SEARCH SERVICE INSURANCE_CLAIMS_DB.DATA.CLAIMS_DOCUMENTS_SEARCH
    ON CHUNK  -- The column to search (text content)
    ATTRIBUTES (CLAIM_ID, CATEGORY)  -- Fixed: Parentheses + comma-separated
    WAREHOUSE = COMPUTE_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT 
        CHUNK,        -- Required: The searchable text
        CLAIM_ID,     -- Attribute for filtering (e.g., by claim)
        CATEGORY      
    FROM INSURANCE_CLAIMS_DB.DATA.DOCS_CHUNKS_TABLE
);

-- CHECK THE STATUS
SHOW CORTEX SEARCH SERVICES IN SCHEMA INSURANCE_CLAIMS_DB.DATA;

-- TEST STANDALONE
SELECT * FROM TABLE(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'CLAIMS_DOCUMENTS_SEARCH',  -- Your service name (no schema prefix needed)
        '{
            "query": "CLM-2024-001484",
            
            "top_k": 3
        }'
    )
);

select * from INSURANCE_CLAIMS_DB.DATA.DOCS_CHUNKS_TABLE;
CLM-2024-001484
