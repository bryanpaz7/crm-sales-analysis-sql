# CRM Sales Pipeline Analysis (MySQL)

This project analyzes CRM sales data using MySQL to uncover insights related to:

- Sales pipeline trends
- Agent and manager performance
- Product revenue and win rates
- Customer account analysis
- Regional office performance

## Dataset

The project uses three datasets:

- accounts.csv
- sales_pipeline.csv
- sales_teams.csv

## Skills Demonstrated

- SQL Joins
- Aggregate Functions
- CASE Statements
- Window Functions
- Revenue Analysis
- KPI Reporting
- Business Intelligence Queries
- Data Cleaning Logic

## Key Business Questions

### Sales Pipeline Analysis
- Which month generated the most sales opportunities?
- What percentage of deals were lost?
- Which product had the highest win rate?

### Sales Performance
- Which sales agent generated the most revenue?
- Which manager had the highest-performing team?

### Product Analysis
- Which products generated the most revenue?
- Are there pricing inconsistencies between sales price and close value?

### Account Analysis
- Which regional offices performed best?
- Which parent companies generated the most revenue?

## Tools Used

- MySQL
- GitHub
- CSV Data Sources

## Example Query

```sql
SELECT
    sales_agent,
    ROUND(SUM(close_value), 2) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY total_revenue DESC;
```

## Author

Bryan Paz
