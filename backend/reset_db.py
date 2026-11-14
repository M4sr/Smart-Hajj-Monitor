import pymysql

try:
    conn = pymysql.connect(host='localhost', user='root', password='')
    cursor = conn.cursor()
    print("Dropping existing database...")
    cursor.execute("DROP DATABASE IF EXISTS smart_hajj_monitor")
    print("Creating new database...")
    cursor.execute("CREATE DATABASE smart_hajj_monitor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
    conn.commit()
    cursor.close()
    conn.close()
    print("Database reset successfully! You can now run the FastAPI server.")
except Exception as e:
    print(f"Error resetting database: {e}")
