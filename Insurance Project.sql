Create Database Insurance_Project;


Use Insurance_Project;


Create Table Policy_details (policy_id varchar(50), policy_type varchar(100), 
coverage_amount decimal(15,2), premium_amount decimal(10,2),
policy_start_date date, policy_end_date date, payment_frequency varchar(50),
status varchar(50), customer_id varchar(50), policy_tenure int, policy_tenure_buckets varchar(50));


SHOW VARIABLES LIKE 'secure_file_priv';


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Policy Details.csv'
INTO TABLE policy_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@policy_id, @policy_type, @coverage_amount, @premium_amount,
 @policy_start_date, @policy_end_date, @payment_frequency,
 @status, @customer_id, @policy_tenure, @policy_tenure_buckets)
SET 
policy_id = @policy_id,
policy_type = @policy_type,
coverage_amount = @coverage_amount,
premium_amount = @premium_amount,
policy_start_date = STR_TO_DATE(@policy_start_date, '%d-%m-%Y'),
policy_end_date = STR_TO_DATE(@policy_end_date, '%d-%m-%Y'),
payment_frequency = @payment_frequency,
status = @status,
customer_id = @customer_id,
policy_tenure = @policy_tenure,
policy_tenure_buckets = @policy_tenure_buckets;


Select * from Policy_details;


Create Table Payment_history (payment_id VARCHAR(50), date_of_payment DATE,
amount_paid DECIMAL(10,2), payment_method VARCHAR(50), payment_status VARCHAR(50), policy_id VARCHAR(50));


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Payment Details.csv'
INTO TABLE payment_history
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@payment_id, @date_of_payment, @amount_paid, @payment_method,
 @payment_status, @policy_id)
SET
payment_id = @payment_id,
date_of_payment = 
    CASE 
        WHEN @date_of_payment REGEXP '^[0-9]+$' 
        THEN DATE_ADD('1899-12-30', INTERVAL @date_of_payment DAY)
        ELSE STR_TO_DATE(@date_of_payment, '%d-%m-%Y')
    END,
amount_paid = @amount_paid,
payment_method = @payment_method,
payment_status = @payment_status,
policy_id = @policy_id;

Select * from Payment_history;


Create table Customer_information (customer_id VARCHAR(50), name VARCHAR(100),
gender VARCHAR(10), age INT, occupation VARCHAR(100), marital_status VARCHAR(50),
city VARCHAR(100), state VARCHAR(100), zip_code VARCHAR(20), age_buckets VARCHAR(50));


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Customer Details.csv'
INTO TABLE customer_information
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


Select * from customer_information;


Create Table Claims (claim_id VARCHAR(50), date_of_claim DATE,
claim_amount DECIMAL(10,2), claim_status VARCHAR(50), reason_for_claim VARCHAR(255),
settlement_date DATE, policy_id VARCHAR(50), claim_settlement_days INT, claim_settlement_buckets VARCHAR(50));


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Claim Details.csv'
INTO TABLE claims
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@claim_id, @date_of_claim, @claim_amount, @claim_status,
 @reason_for_claim, @settlement_date, @policy_id,
 @claim_settlement_days, @claim_settlement_buckets)
SET
claim_id = @claim_id,

date_of_claim = 
    CASE 
        WHEN @date_of_claim = '' THEN NULL
        WHEN @date_of_claim REGEXP '^[0-9]+$' 
            THEN DATE_ADD('1899-12-30', INTERVAL @date_of_claim DAY)
        ELSE STR_TO_DATE(@date_of_claim, '%d-%m-%Y')
    END,

claim_amount = @claim_amount,
claim_status = @claim_status,
reason_for_claim = @reason_for_claim,

settlement_date = 
    CASE 
        WHEN @settlement_date = '' THEN NULL
        WHEN @settlement_date REGEXP '^[0-9]+$' 
            THEN DATE_ADD('1899-12-30', INTERVAL @settlement_date DAY)
        ELSE STR_TO_DATE(@settlement_date, '%d-%m-%Y')
    END,

policy_id = @policy_id,
claim_settlement_days = @claim_settlement_days,
claim_settlement_buckets = @claim_settlement_buckets;


Select * from claims;


Create Table Additional_fields (agent_id VARCHAR(50), renewal_status VARCHAR(50), policy_discounts DECIMAL(10,2),
risk_score INT, policy_id VARCHAR(50), discount_buckets VARCHAR(50), risk_score_buckets VARCHAR(50));


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Additionals.csv'
INTO TABLE additional_fields
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


Select * from additional_fields;


#Total Policy Details
SELECT p.policy_id, c.name, c.age, p.policy_type, p.premium_amount, p.status, a.risk_score
FROM policy_details p JOIN customer_information c  ON p.customer_id = c.customer_id LEFT JOIN additional_fields a 
ON p.policy_id = a.policy_id;
    
 
#Status-wise Policies
SELECT COUNT(*) AS total_policies FROM policy_details;
SELECT status, COUNT(*) AS total FROM policy_details GROUP BY status order by total desc;


#Total Unique Customers
SELECT COUNT( distinct customer_id) AS total_customers FROM policy_details;


#Age Buckets-Wise Policies
SELECT c.age_buckets, COUNT(p.policy_id) AS total_policies FROM policy_details p
JOIN customer_information c ON p.customer_id = c.customer_id GROUP BY c.age_buckets
ORDER BY total_policies desc;


#Gender-wise Policies
SELECT c.gender, COUNT(p.policy_id) AS total_policies FROM policy_details p JOIN customer_information c
ON p.customer_id = c.customer_id GROUP BY c.gender ORDER BY total_policies desc;


#Policy type-wise Policies
SELECT policy_type, COUNT(policy_id) AS total_policies FROM policy_details
GROUP BY policy_type ORDER BY total_policies DESC;


#Policies Expiring in the current year
SELECT COUNT(*) AS policies_expiring_this_year FROM policy_details WHERE YEAR(policy_end_date) = YEAR(CURDATE());


#YOY Growth %
SELECT year, total_revenue, previous_year_revenue,
CONCAT(ROUND((total_revenue - previous_year_revenue) / NULLIF(previous_year_revenue, 0) * 100, 2),'%') AS yoy_growth
FROM (SELECT year, total_revenue, LAG(total_revenue) OVER (ORDER BY year) AS previous_year_revenue
FROM (SELECT YEAR(policy_start_date) AS year, SUM(premium_amount) AS total_revenue
FROM policy_details GROUP BY YEAR(policy_start_date)) t1) t2;


#Claim Status-wise Policies
SELECT  claim_status, COUNT(DISTINCT policy_id) AS total_policies FROM claims 
GROUP BY claim_status ORDER BY total_policies desc;


#Claim Status-wise Claims
SELECT claim_status, COUNT(*) AS total_claims FROM claims GROUP BY claim_status;


#Payment status-wise payments
SELECT payment_status, COUNT(DISTINCT policy_id) AS total_policies FROM payment_history GROUP BY payment_status;
SELECT payment_status, COUNT(*) AS total_payments FROM payment_history GROUP BY payment_status;


#Claim status-wise total amount
SELECT CONCAT(ROUND(SUM(claim_amount)/1000000, 2), ' M') AS total_claim_amount FROM claims;
SELECT claim_status, CONCAT(ROUND(SUM(claim_amount)/1000000, 2), ' M') AS total_amount FROM claims GROUP BY claim_status; 


#Loss Ratio %
SELECT CONCAT(ROUND(SUM(c.claim_amount) / SUM(p.premium_amount) * 100, 2),' %') AS loss_ratio_percentage
FROM claims c JOIN policy_details p ON TRIM(c.policy_id) = TRIM(p.policy_id);


#Policy Renewal Rate
SELECT CONCAT(ROUND(COUNT(CASE WHEN renewal_status = 'Renewed' THEN 1 END) * 100.0 / COUNT(*), 2), '%') AS renewal_rate
FROM additional_fields;


#Top 5 Customers with Highest Premium
SELECT c.name, SUM(p.premium_amount) AS total_premium FROM policy_details p
JOIN customer_information c ON p.customer_id = c.customer_id GROUP BY c.name ORDER BY total_premium DESC LIMIT 5;















