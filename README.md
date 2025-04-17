# Credit-Risk-Analysis

This project focuses on advanced SQL analytics for credit risk assessment within a banking environment. The goal is to analyze customer behavior, loan performance, and risk indicators using structured data from core banking systems like loan_applications, risk_assessment, repayment_history, and credit_exposure.

Through a combination of window functions, CTEs, subqueries, and joins, this project derives actionable insights to identify high-risk behaviors, detect anomalies, and support data-driven credit decision-making.

# Datasets Used: 

loan_applications: Application_ID, Loan_ID, Customer_ID, Loan_Type, Requested_Amount, Application_Date, Approval_Status

risk_assessment: Customer_ID, Credit_Score, Default_Risk (%), Risk_Grade, Risk_Comments

loan_repayment_history: Application_ID, Loan_ID, Payment_Date, Amount_Paid, Due_Amount, Days_Late

credit_exposure: Customer_ID, Total_Liabilities, Credit_Limit, Outstanding_Balance, credit_utilization

customers_table: Customer_ID, First_Name, Last_Name, DOB, Employment_Status, Income, Credit_Score

# Techniques Used

CTEs for staging intermediate data.
Window functions (LEAD, LAG, RANK, DENSE_RANK, ROW_NUMBER) for analysing sequences and trends.
Aggregations and subqueries to compute behavior metrics.
DATEDIFF() AND DATE_SUB() for temporal analysis.
MIN() AND MAX()
LIMIT AND OFFSET
CASE statements for categorizing customer risk profiles.

# Glossary of Key Credit Risk Terms

1. Total Liabilities:
This is the total amount of money a person or company owes to the bank - All your debts combined.

2. Credit Limit:
The maximum amount a person is allowed to borrow on a credit card or line of credit.

3. Outstanding Balance:
This is the amount you currently owe on your credit card or loan.
ie, The used portion of your credit or loan that hasn’t been paid back yet.
Example:
If your credit card limit is $10,000 and you’ve spent $4,000, then your Outstanding Balance = $4,000

4. Utilization rate:
A credit usage score — lower is better(ideally <30%).
Utilization Rate (%) = (Outstanding Balance / Credit Limit) × 100

5. credit score:
800 – 850	Excellent
740 – 799	Very Good
670 – 739	Good

6. Risk Grade
Definition:
An internal classification assigned by banks to categorize customers based on their overall credit risk. Common grades include: Low, Medium, High, and Very High risk.


7. Default:
Occurs when a customer fails to meet the legal obligations of their loan agreement, often defined as being 90+ days late on repayments.


8. Debt-to-Income (DTI) Ratio:
A key indicator of a customer's ability to manage monthly payments and repay debts.

Formula:
DTI (%) = (Total Monthly Debt Payments / Gross Monthly Income) × 100
Lower DTI = healthier financial position.


