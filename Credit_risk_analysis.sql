use `credit_risk_analysis`;

select * from `credit_exposure`;
select * from `customers_table`;
select * from `loan_applications`;
select * from `loan_repayment_history`;
select * from `risk_assessment`;

-- CLEANING DATA

alter table risk_assessment
drop column `MyUnknownColumn_[0]`;

delete from loan_applications
where Application_ID is null;

-- check the bad data type that has has non-numeric characters (e.g., commas, letters, currency symbols)

-- Outstanding_Balance
select Outstanding_Balance
from credit_exposure
where Outstanding_Balance regexp '[^0-9.]';

update credit_exposure
set Outstanding_Balance = replace(Outstanding_Balance, ',', '');
ALTER TABLE credit_exposure
MODIFY Outstanding_Balance INT;

 -- the data type of DOB is text and it has non-numeric character '/'
select DOB
from customers_table
where DOB regexp '[^0-9.]';

update customers_table
set DOB = replace(DOB, '/','');

UPDATE customers_table
SET DOB = STR_TO_DATE(DOB, '%d%m%Y')
WHERE DOB IS NOT NULL;

-- adding table credit_utilization
alter table credit_exposure add column credit_utilization decimal(5,2);
update credit_exposure
set credit_utilization = (Outstanding_Balance/Credit_Limit)*100;

-- ANALYSIS OF THE DATA

-- Customers who have missed payments in the last 3 months
SELECT Customer_ID, Payment_Date
FROM loan_repayment_history
WHERE Days_Late > 0
  AND Payment_Date > DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Finding the default risk category (Low, Medium, High) for each customer based on credit score
SELECT Customer_ID, Credit_Score,
       CASE 
           WHEN Credit_Score > 799 THEN 'Low'
           WHEN Credit_Score <= 799 AND Credit_Score > 670 THEN 'Medium'
           WHEN Credit_Score <= 670 THEN 'High'
       END AS Risk_status
FROM customers_table;

-- Customers who have REAPPLIED for a new loan in the last 30 days
SELECT LA.Customer_ID
FROM loan_applications LA
JOIN risk_assessment RA ON LA.Customer_ID = RA.Customer_ID
HAVING MIN(Application_Date) < DATE_SUB(NOW(), INTERVAL 30 DAY) 
   AND MAX(Application_Date) > DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Top 2 customers with the highest outstanding balance
SELECT Customer_ID, MAX(Outstanding_Balance)
FROM credit_exposure
GROUP BY Customer_ID
LIMIT 2;

-- Customers who have applied for more than 1 loan within 7 days
SELECT A.*, 
       ABS(DATEDIFF(A.Application_Date, B.Application_Date))
FROM loan_applications A
LEFT JOIN loan_applications B ON A.Customer_ID = B.Customer_ID 
                               AND A.Application_ID != B.Application_ID
WHERE ABS(DATEDIFF(A.Application_Date, B.Application_Date)) <= 7;

-- Calculate the total liabilities vs. total credit limit for all customers. 
-- If your liabilities are too close to your limit → higher risk.
SELECT Customer_ID, 
       Total_Liabilities, 
       Credit_Limit, 
       ((Total_Liabilities / Credit_Limit) * 100) AS liabilities_vs_creditLimit
FROM credit_exposure;

-- Identify customers who have continuously missed payments in the last 6 months
SELECT ct.Customer_ID, 
       lr.Application_ID, 
       lr.Payment_Date, 
       lr.Due_Amount, 
       lr.Days_Late
FROM customers_table ct
LEFT JOIN loan_applications la ON ct.Customer_ID = la.Customer_ID
LEFT JOIN loan_repayment_history lr ON la.Application_ID = lr.Application_ID
WHERE lr.Application_ID IS NOT NULL
  AND lr.Payment_Date > CURDATE() - INTERVAL 6 MONTH
  AND Days_Late >= 1;

-- Rank all customers based on default risk
-- Approach 1
SELECT Customer_ID, 
       `Default_Risk (%)`,
       DENSE_RANK() OVER w AS rank_by_default
FROM risk_assessment
WINDOW w AS (ORDER BY `Default_Risk (%)`);

-- Approach 2
SELECT Customer_ID, 
       `Default_Risk (%)`, 
       DENSE_RANK() OVER (ORDER BY `Default_Risk (%)`) AS ranking
FROM risk_assessment;

-- 5th highest amount requested by customer
SELECT Customer_ID, 
       Requested_Amount
FROM loan_applications
WHERE Requested_Amount = (
    SELECT Requested_Amount
    FROM loan_applications
    LIMIT 1 OFFSET 4
);

-- Total amount requested by customers for each loan (home loan, personal loan, etc.) over the last 30 days
SELECT Loan_ID, 
       Customer_ID, 
       Requested_Amount, 
       SUM(Requested_Amount) OVER (PARTITION BY Loan_ID) AS tot_loan_req
FROM loan_applications
WHERE Application_Date >= CURDATE() - INTERVAL 30 DAY
GROUP BY Loan_ID, Customer_ID, Requested_Amount
ORDER BY Loan_ID;

-- Top 2 customers with the highest loan request amount for each loan category
WITH Tbl_top2 AS (
    SELECT Loan_ID,
           Customer_ID,
           Requested_Amount,
           DENSE_RANK() OVER (PARTITION BY Loan_ID ORDER BY Requested_Amount DESC) AS top2
    FROM loan_applications
)
SELECT * 
FROM Tbl_top2
WHERE top2 IN (1, 2)
ORDER BY Loan_ID;

-- Customers who have applied for exactly two loans within 7 days
WITH Loan_App_date AS (
    SELECT Customer_ID,
           Application_ID,
           Application_Date,
           LEAD(Application_Date) OVER (PARTITION BY Customer_ID ORDER BY Application_Date) AS date2nd,
           LEAD(Application_Date, 2) OVER (PARTITION BY Customer_ID ORDER BY Application_Date) AS date3rd
    FROM loan_applications
)
SELECT Customer_ID,
       SUM(CASE WHEN ABS(DATEDIFF(date2nd, Application_Date)) <= 7 THEN ABS(DATEDIFF(date2nd, Application_Date)) ELSE 0 END) +
       SUM(CASE WHEN ABS(DATEDIFF(date3rd, Application_Date)) <= 7 THEN ABS(DATEDIFF(date3rd, Application_Date)) ELSE 0 END) 
       AS total_days_within_7
FROM Loan_App_date
GROUP BY Customer_ID;

-- Customers who are unemployed or who have low credit score (below 670) but have applied for a loan
SELECT ct.Customer_ID, ct.Employment_Status, ct.Credit_Score, la.Loan_Type, la.Requested_Amount
FROM `customers_table` ct
LEFT JOIN loan_applications la ON ct.Customer_ID = la.Customer_ID
WHERE Employment_Status = 'Unemployed'
   OR Credit_Score < 670;

-- I combined customer data with loan and credit risk trends to identify financially vulnerable individuals in the last 1 year 
-- based late repayments, high credit utilization, low credit scores, higher risk grade, employment status and income

WITH Loan_trend AS (
    SELECT LA.Customer_ID, 
           LR.Due_Amount, 
           LR.Days_Late, 
           LA.Requested_Amount
    FROM loan_repayment_history LR
    LEFT JOIN loan_applications LA 
        ON LR.Application_ID = LA.Application_ID
    WHERE (Application_Date >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
        OR Payment_Date >= DATE_SUB(NOW(), INTERVAL 1 YEAR))
        OR Days_Late >= 1
),
credit_risk_trend AS (
    SELECT ce.Customer_ID, 
           ce.credit_utilization, 
           ra.Risk_Grade
    FROM credit_exposure ce
    INNER JOIN risk_assessment ra 
        ON ce.Customer_ID = ra.Customer_ID
    WHERE ra.Risk_Grade IN ('high', 'medium')
       OR ce.credit_utilization > 40
)
SELECT DISTINCT ct.Customer_ID,
       ct.First_Name, 
       ct.Last_Name, 
       ct.Employment_Status, 
       ct.Income, 
       ct.Credit_Score, 
       lt.Due_Amount, 
       lt.Days_Late, 
       lt.Requested_Amount, 
       crt.credit_utilization, 
       crt.Risk_Grade
FROM customers_table ct
INNER JOIN Loan_trend lt 
    ON ct.Customer_ID = lt.Customer_ID
INNER JOIN credit_risk_trend crt 
    ON ct.Customer_ID = crt.Customer_ID
WHERE Employment_Status IN ('Unemployed', 'Part-Time', 'Self-Employed')
   OR ct.Credit_Score < 700;






