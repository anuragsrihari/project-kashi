USE kashi_bank;

-- Q1: List all customers with their account numbers (JOIN)
SELECT c.FirstName, c.LastName, a.AccountNumber, ah.HolderType
FROM CUSTOMER c
JOIN ACCOUNT_HOLDER ah ON c.CustomerID = ah.CustomerID
JOIN ACCOUNT a ON ah.AccountID = a.AccountID;

-- Q2: Total balance per branch (GROUP BY)
SELECT b.BranchName, SUM(a.Balance) AS TotalBalance
FROM BRANCH b
JOIN ACCOUNT a ON b.BranchID = a.BranchID
GROUP BY b.BranchName;

-- Q3: Customers with more than one account (HAVING)
SELECT c.FirstName, c.LastName, COUNT(*) AS TotalAccounts
FROM CUSTOMER c
JOIN ACCOUNT_HOLDER ah ON c.CustomerID = ah.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(*) > 1;

-- Q4: Accounts with balance above 30000 (WHERE + ORDER BY)
SELECT AccountNumber, AccountType, Balance
FROM ACCOUNT
WHERE Balance > 30000
ORDER BY Balance DESC;

-- Q5: Transaction history of one account (JOIN)
SELECT a.AccountNumber, t.TransactionType, t.Amount, t.TransactionDate
FROM `TRANSACTION` t
JOIN ACCOUNT a ON t.AccountID = a.AccountID
WHERE a.AccountNumber = 'KASH100001'
ORDER BY t.TransactionDate;

-- Q6: Total deposits and withdrawals per account (conditional aggregation)
SELECT a.AccountNumber,
       SUM(CASE WHEN t.TransactionType = 'DEPOSIT' THEN t.Amount ELSE 0 END) AS TotalDeposits,
       SUM(CASE WHEN t.TransactionType = 'WITHDRAWAL' THEN t.Amount ELSE 0 END) AS TotalWithdrawals
FROM ACCOUNT a
LEFT JOIN `TRANSACTION` t ON a.AccountID = t.AccountID
GROUP BY a.AccountNumber;

-- Q7: Number of employees per branch (LEFT JOIN + COUNT)
SELECT b.BranchName, COUNT(e.EmployeeID) AS TotalEmployees
FROM BRANCH b
LEFT JOIN EMPLOYEE e ON b.BranchID = e.BranchID
GROUP BY b.BranchName;

-- Q8: Customers who have no transactions at all (subquery)
SELECT DISTINCT c.FirstName, c.LastName
FROM CUSTOMER c
JOIN ACCOUNT_HOLDER ah ON c.CustomerID = ah.CustomerID
WHERE ah.AccountID NOT IN (SELECT AccountID FROM `TRANSACTION`);

-- Q9: Highest-paid employee in each branch (subquery)
SELECT e.EmployeeName, e.Salary, b.BranchName
FROM EMPLOYEE e
JOIN BRANCH b ON e.BranchID = b.BranchID
WHERE e.Salary = (SELECT MAX(Salary) FROM EMPLOYEE WHERE BranchID = e.BranchID);

-- Q10: Inactive accounts with their holder names
SELECT c.FirstName, c.LastName, a.AccountNumber, a.Status
FROM ACCOUNT a
JOIN ACCOUNT_HOLDER ah ON a.AccountID = ah.AccountID
JOIN CUSTOMER c ON ah.CustomerID = c.CustomerID
WHERE a.Status = 'Inactive';

