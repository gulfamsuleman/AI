import pyodbc


DB_CONNECTION_STRING = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=DESKTOP-BIP1CP7\\SQLEXPRESS;"
    "DATABASE=QTasks;"
    "Trusted_Connection=yes;"
)


def test_connection():
    try:
        conn = pyodbc.connect(DB_CONNECTION_STRING)
        print("✅ Connected to QTasks database!")
        conn.close()
    except Exception as e:
        print("❌ Connection failed:", e)

test_connection()
