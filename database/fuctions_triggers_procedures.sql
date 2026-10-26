USE kashi_bank;

DELIMITER $$

-- FUNCTION 1: balance of an account
DROP FUNCTION IF EXISTS fn_get_balance$$
CREATE FUNCTION fn_get_balance(p_acc VARCHAR(20))
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v_bal DECIMAL(15,2);
    SELECT Balance INTO v_bal FROM ACCOUNT WHERE AccountNumber = p_acc;
    RETURN v_bal;
END$$

DELIMITER $$

CREATE FUNCTION fn_customer_total_balance(p_cust INT)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(a.Balance), 0.00)
    INTO v_total
    FROM ACCOUNT AS a
    INNER JOIN ACCOUNT_HOLDER AS ah
        ON a.AccountID = ah.AccountID
    WHERE ah.CustomerID = p_cust;

    RETURN v_total;
END$$

DELIMITER ;


DROP TRIGGER IF EXISTS trg_customer_age_check;

DELIMITER $$

CREATE TRIGGER trg_customer_age_check
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
BEGIN
    IF NEW.DateOfBirth IS NULL
       OR NEW.DateOfBirth > DATE_SUB(CURDATE(), INTERVAL 18 YEAR) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer must be at least 18 years old';

    END IF;
END$$

DELIMITER ;




USE kashi_bank;

DROP TRIGGER IF EXISTS trg_block_inactive_account;

DELIMITER $$

CREATE TRIGGER trg_block_inactive_account
BEFORE INSERT ON `TRANSACTION`
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20) DEFAULT NULL;

    SELECT Status
    INTO v_status
    FROM ACCOUNT
    WHERE AccountID = NEW.AccountID
    LIMIT 1;

    IF v_status IS NULL OR v_status <> 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account is not active';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE sp_deposit(
    IN p_acc VARCHAR(20),
    IN p_amount DECIMAL(15,2)
)
BEGIN
    DECLARE v_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Amount must be positive';
    END IF;

    START TRANSACTION;

    SELECT AccountID
    INTO v_id
    FROM ACCOUNT
    WHERE AccountNumber = p_acc
    LIMIT 1
    FOR UPDATE;

    IF v_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account not found';
    END IF;

    INSERT INTO `TRANSACTION`
        (AccountID, TransactionType, Amount, Description, ReferenceNumber)
    VALUES
        (v_id, 'DEPOSIT', p_amount, 'Deposit',
         CONCAT('REF', UPPER(LEFT(UUID(), 12))));

    UPDATE ACCOUNT
    SET Balance = Balance + p_amount
    WHERE AccountID = v_id;

    COMMIT;
END$$

DELIMITER ;



DELIMITER $$



DELIMITER $$

CREATE PROCEDURE sp_withdraw(
    IN p_acc VARCHAR(20),
    IN p_amount DECIMAL(15,2)
)
BEGIN
    DECLARE v_id INT DEFAULT NULL;
    DECLARE v_bal DECIMAL(15,2) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Amount must be positive';
    END IF;

    START TRANSACTION;

    SELECT AccountID, Balance
    INTO v_id, v_bal
    FROM ACCOUNT
    WHERE AccountNumber = p_acc
    LIMIT 1
    FOR UPDATE;

    IF v_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account not found';
    END IF;

    IF v_bal < p_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    INSERT INTO `TRANSACTION`
        (AccountID, TransactionType, Amount, Description, ReferenceNumber)
    VALUES
        (v_id, 'WITHDRAWAL', p_amount, 'Withdrawal',
         CONCAT('REF', UPPER(LEFT(UUID(), 12))));

    UPDATE ACCOUNT
    SET Balance = Balance - p_amount
    WHERE AccountID = v_id;

    COMMIT;
END$$

DELIMITER ;



DELIMITER $$

CREATE PROCEDURE sp_transfer(
    IN p_from VARCHAR(20),
    IN p_to VARCHAR(20),
    IN p_amount DECIMAL(15,2)
)
BEGIN
    DECLARE v_from_id INT DEFAULT NULL;
    DECLARE v_to_id INT DEFAULT NULL;
    DECLARE v_bal DECIMAL(15,2) DEFAULT NULL;
    DECLARE v_from_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_to_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_ref VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Amount must be positive';
    END IF;

    IF p_from = p_to THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot transfer to the same account';
    END IF;

    START TRANSACTION;

    SELECT AccountID, Balance, Status
    INTO v_from_id, v_bal, v_from_status
    FROM ACCOUNT
    WHERE AccountNumber = p_from
    LIMIT 1
    FOR UPDATE;

    IF v_from_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Source account not found';
    END IF;

    SELECT AccountID, Status
    INTO v_to_id, v_to_status
    FROM ACCOUNT
    WHERE AccountNumber = p_to
    LIMIT 1
    FOR UPDATE;

    IF v_to_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Destination account not found';
    END IF;

    IF v_from_status IS NULL OR v_from_status <> 'Active'
       OR v_to_status IS NULL OR v_to_status <> 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Both accounts must be active';
    END IF;

    IF v_bal < p_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    SET v_ref = CONCAT('REF', UPPER(LEFT(UUID(), 12)));

    UPDATE ACCOUNT
    SET Balance = Balance - p_amount
    WHERE AccountID = v_from_id;

    UPDATE ACCOUNT
    SET Balance = Balance + p_amount
    WHERE AccountID = v_to_id;

    INSERT INTO `TRANSACTION`
        (AccountID, TransactionType, Amount, Description, ReferenceNumber)
    VALUES
        (v_from_id, 'TRANSFER_OUT', p_amount,
         CONCAT('Transfer to ', p_to), CONCAT(v_ref, '-O'));

    INSERT INTO `TRANSACTION`
        (AccountID, TransactionType, Amount, Description, ReferenceNumber)
    VALUES
        (v_to_id, 'TRANSFER_IN', p_amount,
         CONCAT('Transfer from ', p_from), CONCAT(v_ref, '-I'));

    COMMIT;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE sp_open_account(
    IN p_first VARCHAR(50),
    IN p_last VARCHAR(50),
    IN p_dob DATE,
    IN p_gender VARCHAR(10),
    IN p_mobile VARCHAR(15),
    IN p_email VARCHAR(100),
    IN p_address VARCHAR(255),
    IN p_city VARCHAR(50),
    IN p_branch INT,
    IN p_type VARCHAR(10),
    IN p_initial DECIMAL(15,2),
    OUT p_acc_number VARCHAR(20)
)
BEGIN
    DECLARE v_cust_id INT;
    DECLARE v_acc_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_initial IS NULL OR p_initial < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Initial deposit cannot be negative';
    END IF;

    START TRANSACTION;

    INSERT INTO CUSTOMER
        (FirstName, LastName, DateOfBirth, Gender,
         Mobile, Email, Address, City)
    VALUES
        (p_first, p_last, p_dob, p_gender,
         p_mobile, p_email, p_address, p_city);

    SET v_cust_id = LAST_INSERT_ID();

    INSERT INTO ACCOUNT
        (AccountNumber, AccountType, Balance, BranchID)
    VALUES
        (CONCAT('TMP', UUID_SHORT()), p_type, p_initial, p_branch);

    SET v_acc_id = LAST_INSERT_ID();

    SET p_acc_number = CONCAT('KASH', 100000 + v_acc_id);

    UPDATE ACCOUNT
    SET AccountNumber = p_acc_number
    WHERE AccountID = v_acc_id;

    INSERT INTO ACCOUNT_HOLDER
        (CustomerID, AccountID, HolderType)
    VALUES
        (v_cust_id, v_acc_id, 'Primary');

    IF p_initial > 0 THEN
        INSERT INTO `TRANSACTION`
            (AccountID, TransactionType, Amount,
             Description, ReferenceNumber)
        VALUES
            (v_acc_id, 'DEPOSIT', p_initial,
             'Initial deposit',
             CONCAT('REF', UPPER(LEFT(UUID(), 12))));
    END IF;

    COMMIT;
END$$

DELIMITER ;






