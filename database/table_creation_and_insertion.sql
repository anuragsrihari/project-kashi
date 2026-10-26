DROP DATABASE IF EXISTS kashi_bank;
CREATE DATABASE kashi_bank;
USE kashi_bank;

CREATE TABLE BRANCH (
    BranchID INT AUTO_INCREMENT PRIMARY KEY,
    BranchName VARCHAR(100) NOT NULL,
    IFSCCode VARCHAR(11) NOT NULL UNIQUE,
    Address VARCHAR(255),
    City VARCHAR(50),
    State VARCHAR(50),
    ContactNumber VARCHAR(15)
);

CREATE TABLE CUSTOMER (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50),
    DateOfBirth DATE NOT NULL,
    Gender ENUM('Male','Female','Other'),
    Mobile VARCHAR(15) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Address VARCHAR(255),
    City VARCHAR(50),
    RegistrationDate DATE NOT NULL DEFAULT (CURRENT_DATE)
);

CREATE TABLE EMPLOYEE (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeName VARCHAR(100) NOT NULL,
    Mobile VARCHAR(15) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Designation VARCHAR(50),
    Salary DECIMAL(10,2) CHECK (Salary > 0),
    JoiningDate DATE,
    BranchID INT NOT NULL,
    FOREIGN KEY (BranchID) REFERENCES BRANCH(BranchID)
);

CREATE TABLE ACCOUNT (
    AccountID INT AUTO_INCREMENT PRIMARY KEY,
    AccountNumber VARCHAR(20) NOT NULL UNIQUE,
    AccountType ENUM('Saving','Current','Salary') NOT NULL,
    OpeningDate DATE NOT NULL DEFAULT (CURRENT_DATE),
    Balance DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (Balance >= 0),
    Status ENUM('Active','Inactive','Close') NOT NULL DEFAULT 'Active',
    BranchID INT NOT NULL,
    FOREIGN KEY (BranchID) REFERENCES BRANCH(BranchID)
);

CREATE TABLE ACCOUNT_HOLDER (
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL,
    HolderSince DATE NOT NULL DEFAULT (CURRENT_DATE),
    HolderType ENUM('Primary','Joint') NOT NULL DEFAULT 'Primary',
    PRIMARY KEY (CustomerID, AccountID),
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID),
    FOREIGN KEY (AccountID) REFERENCES ACCOUNT(AccountID)
);

CREATE TABLE TRANSACTION (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionType ENUM('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT') NOT NULL,
    Amount DECIMAL(15,2) NOT NULL CHECK (Amount > 0),
    TransactionDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Description VARCHAR(255),
    ReferenceNumber VARCHAR(30) UNIQUE,
    TransactionStatus ENUM('Success','Failed','Pending') NOT NULL DEFAULT 'Success',
    FOREIGN KEY (AccountID) REFERENCES ACCOUNT(AccountID)
);


INSERT INTO BRANCH (BranchName, IFSCCode, Address, City, State, ContactNumber) VALUES
('London Central Branch', 'KASH0000001', 'Oxford Street', 'London', 'England', '02079460001'),
('Manchester City Branch', 'KASH0000002', 'Deansgate', 'Manchester', 'England', '01611230002'),
('Birmingham Branch', 'KASH0000003', 'New Street', 'Birmingham', 'England', '01214560003');


INSERT INTO CUSTOMER (FirstName, LastName, DateOfBirth, Gender, Mobile, Email, Address, City) VALUES
('Oliver', 'Bennett', '1995-04-12', 'Male', '07700900001', 'oliver.bennett@example.com', '12 Baker Street', 'London'),
('Emily', 'Wilson', '1998-09-23', 'Female', '07700900002', 'emily.wilson@example.com', '5 King Street', 'Manchester'),
('Harry', 'Thompson', '1990-01-30', 'Male', '07700900003', 'harry.thompson@example.com', '8 Victoria Road', 'Birmingham'),
('Charlotte', 'Taylor', '1988-06-17', 'Female', '07700900004', 'charlotte.taylor@example.com', '22 Park Lane', 'Liverpool'),
('George', 'Harrison', '2000-12-05', 'Male', '07700900005', 'george.harrison@example.com', '3 Queen Street', 'Leeds');


INSERT INTO EMPLOYEE (EmployeeName, Mobile, Email, Designation, Salary, JoiningDate, BranchID) VALUES
('James Anderson', '07700900101', 'james@kashi.com', 'Manager', 90000, '2018-03-01', 1),
('Sophie Clarke', '07700900102', 'sophie@kashi.com', 'Cashier', 35000, '2021-07-15', 1),
('William Harris', '07700900103', 'william@kashi.com', 'Manager', 85000, '2019-05-10', 2),
('Amelia Lewis', '07700900104', 'amelia@kashi.com', 'Clerk', 30000, '2022-01-20', 2),
('Thomas Walker', '07700900105', 'thomas@kashi.com', 'Cashier', 33000, '2020-11-03', 3);


INSERT INTO ACCOUNT (AccountNumber, AccountType, OpeningDate, Balance, Status, BranchID) VALUES
('KASH100001', 'Saving', '2024-01-10', 50000.00, 'Active', 1),
('KASH100002', 'Saving', '2024-02-15', 25000.00, 'Active', 2),
('KASH100003', 'Current', '2024-03-20', 120000.00, 'Active', 3),
('KASH100004', 'Salary', '2024-05-05', 40000.00, 'Active', 1),
('KASH100005', 'Saving', '2024-06-18', 8000.00, 'Inactive', 2),
('KASH100006', 'Saving', '2024-07-22', 15000.00, 'Active', 1);


INSERT INTO ACCOUNT_HOLDER (CustomerID, AccountID, HolderSince, HolderType) VALUES
(1, 1, '2024-01-10', 'Primary'),
(2, 2, '2024-02-15', 'Primary'),
(3, 3, '2024-03-20', 'Primary'),
(4, 4, '2024-05-05', 'Primary'),
(5, 5, '2024-06-18', 'Primary'),
(1, 6, '2024-07-22', 'Primary'),
(4, 1, '2024-08-01', 'Joint');


INSERT INTO `TRANSACTION`
(AccountID, TransactionType, Amount, TransactionDate, Description, ReferenceNumber, TransactionStatus) VALUES
(1, 'DEPOSIT', 10000.00, '2024-09-01 10:00:00', 'Cash deposit', 'REF0001', 'Success'),
(1, 'WITHDRAWAL', 2000.00, '2024-09-03 12:30:00', 'ATM withdrawal', 'REF0002', 'Success'),
(2, 'DEPOSIT', 5000.00, '2024-09-05 09:15:00', 'Salary credit', 'REF0003', 'Success'),
(1, 'TRANSFER_OUT', 3000.00, '2024-09-10 14:00:00', 'Transfer to KASH100002', 'REF0004', 'Success'),
(2, 'TRANSFER_IN', 3000.00, '2024-09-10 14:00:00', 'Transfer from KASH100001', 'REF0005', 'Success'),
(3, 'DEPOSIT', 20000.00, '2024-09-12 11:45:00', 'Business income', 'REF0006', 'Success'),
(4, 'WITHDRAWAL', 5000.00, '2024-09-15 16:20:00', 'Cash withdrawal', 'REF0007', 'Success'),transaction
(6, 'DEPOSIT', 15000.00, '2024-09-18 10:10:00', 'Initial deposit', 'REF0008', 'Success');
