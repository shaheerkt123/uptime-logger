import sqlite3, psutil, datetime, sys

DB_FILE = "/usr/local/bin/uptime.db"

conn = sqlite3.connect(DB_FILE)
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    boot_time TEXT,
    shutdown_time TEXT
)
""")

if "--shutdown" in sys.argv:
    # Update the last session with shutdown time
    shutdown_time_str = datetime.datetime.now().isoformat()
    cursor.execute("UPDATE sessions SET shutdown_time = ? WHERE id = (SELECT MAX(id) FROM sessions)",
                   (shutdown_time_str,))
    conn.commit()
    conn.close()
    print(f"Shutdown logged at {shutdown_time_str}")
    sys.exit()

# Normal boot logging
boot_time = datetime.datetime.fromtimestamp(psutil.boot_time()).isoformat()
cursor.execute("INSERT INTO sessions (boot_time, shutdown_time) VALUES (?, ?)", (boot_time, None))
conn.commit()
conn.close()
print(f"Boot logged at {boot_time}")
