# Snowflake Insurance Claims Intelligence Agent  
**One Agent. Full Claim in Seconds.**

A real-time, self-service claims assistant built **100% inside Snowflake** using:
- Cortex Analyst (semantic model)
- Cortex Search (unstructured .txt reports)
- Snowflake Native Agent

No external RAG. No data movement. No ETL.

### Problem
Structured data → in Snowflake  
Real story → trapped in 4 .txt files  
→ Manual work → IT dependency → frustrated customers

### Solution
Upload 4 real text files → turn on 2 Snowflake features → one chatbot answers everyone instantly.

### Key Features
- 4 claim types: Auto, Health, Property, Life
- 4 real reports per claim
- Serves 6 stakeholders: Adjuster, Manager, SIU, Actuary, Claimant, Customer Service

### Repo Structure
```plaintext
snowflake-build-2025/
├── sql/                        # Table creation & agent setup scripts
├── yaml/                       # Semantic model (the "insurance brain")
├── notebook/                   # Data generation notebooks
├── SampleFiles-Unstructured/
│   ├── Image/                  # Demo screenshots & diagrams
│   └── *.txt                   # 30+ real claim reports
├── demo/
│   └── screenshot/             # Live agent demo screenshots
└── README.md                   # You are here
