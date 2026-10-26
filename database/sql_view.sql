-- VIEW 1: Customer account summary
CREATE OR REPLACE VIEW vw_customer_accounts AS
SELECT c.CustomerID, c.FirstName, c.LastName, a.AccountNumber,
       a.AccountType, a.Balance, a.Status, b.BranchName
FROM CUSTOMER c
JOIN ACCOUNT_HOLDER ah ON c.CustomerID = ah.CustomerID
JOIN ACCOUNT a ON ah.AccountID = a.AccountID
JOIN BRANCH b ON a.BranchID = b.BranchID;

-- VIEW 2: Branch summary
CREATE OR REPLACE VIEW vw_branch_summary AS
SELECT b.BranchName, COUNT(DISTINCT a.AccountID) AS TotalAccounts,
       COALESCE(SUM(a.Balance), 0) AS TotalBalance
FROM BRANCH b
LEFT JOIN ACCOUNT a ON b.BranchID = a.BranchID
GROUP BY b.BranchName;