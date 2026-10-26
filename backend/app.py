from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector
from config import DB_PASSWORD


app = Flask(__name__, template_folder="../frontend/templates")
app.secret_key = "kashi-secret"


def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password=DB_PASSWORD,
        database="kashi_bank"
    )


@app.route("/")
def home():
    return render_template("home.html")


@app.route("/open-account", methods=["GET", "POST"])
def open_account():
    if request.method == "POST":
        f = request.form
        db = get_db()
        cur = db.cursor()
        try:
            result = cur.callproc("sp_open_account", [
                f["first_name"], f["last_name"], f["dob"], f["gender"],
                f["mobile"], f["email"], f["address"], f["city"],
                int(f["branch_id"]), f["account_type"],
                float(f["initial_deposit"]), ""
            ])
            db.commit()
            acc_no = result[11]
            flash(f"Account opened successfully! Your account number is {acc_no}")
        except mysql.connector.Error as e:
            flash(f"Error: {e.msg}")
        finally:
            cur.close()
            db.close()
        return redirect(url_for("open_account"))

    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT BranchID, BranchName FROM BRANCH")
    branches = cur.fetchall()
    cur.close()
    db.close()
    return render_template("open_account.html", branches=branches)


@app.route("/test-db")
def test_db():
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT COUNT(*) FROM CUSTOMER")
    n = cur.fetchone()[0]
    cur.close()
    db.close()
    return f"Connected! Customers in DB: {n}"

def run_procedure(name, args, success_msg):
    db = get_db()
    cur = db.cursor()
    try:
        cur.callproc(name, args)
        db.commit()
        flash(success_msg)
    except mysql.connector.Error as e:
        flash(f"Error: {e.msg}")
    finally:
        cur.close()
        db.close()


@app.route("/deposit", methods=["GET", "POST"])
def deposit():
    if request.method == "POST":
        run_procedure("sp_deposit",
                      [request.form["account"], float(request.form["amount"])],
                      "Deposit successful")
        return redirect(url_for("deposit"))
    return render_template("transact.html", mode="deposit")


@app.route("/withdraw", methods=["GET", "POST"])
def withdraw():
    if request.method == "POST":
        run_procedure("sp_withdraw",
                      [request.form["account"], float(request.form["amount"])],
                      "Withdrawal successful")
        return redirect(url_for("withdraw"))
    return render_template("transact.html", mode="withdraw")


@app.route("/transfer", methods=["GET", "POST"])
def transfer():
    if request.method == "POST":
        run_procedure("sp_transfer",
                      [request.form["from_account"], request.form["to_account"],
                       float(request.form["amount"])],
                      "Transfer successful")
        return redirect(url_for("transfer"))
    return render_template("transact.html", mode="transfer")

@app.route("/history", methods=["GET", "POST"])
def history():
    rows = []
    account = ""
    if request.method == "POST":
        account = request.form["account"]
        db = get_db()
        cur = db.cursor()
        cur.execute("""
            SELECT t.TransactionID, t.TransactionType, t.Amount,
                   t.TransactionDate, t.Description, t.ReferenceNumber
            FROM `TRANSACTION` t
            JOIN ACCOUNT a ON t.AccountID = a.AccountID
            WHERE a.AccountNumber = %s
            ORDER BY t.TransactionDate DESC
        """, (account,))
        rows = cur.fetchall()
        cur.close()
        db.close()
        if not rows:
            flash("No transactions found for this account")
    return render_template("history.html", rows=rows, account=account)

if __name__ == "__main__":
    app.run(debug=True)