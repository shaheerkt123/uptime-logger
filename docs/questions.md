# Quastions

import sqlite3, psutil, datetime, sys

DB_FILE = "uptime.db"

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

boot_time = datetime.datetime.fromtimestamp(psutil.boot_time()).isoformat()
cursor.execute("INSERT INTO sessions (boot_time, shutdown_time) VALUES (?, ?)", (boot_time, None))
conn.commit()
conn.close()
print(f"Boot logged at {boot_time}") 

### how does this only add on and off to same row

### how to add cron to a rpm/deb

%files
/usr/local/bin/pc_uptime_logger.py
/usr/local/bin/delta_upload.py
/usr/local/bin/delta_upload_cron.sh
/etc/systemd/system/uptime-logger.service
/etc/systemd/system/uptime-logger-shutdown.service
/etc/cron.d/delta_upload

### why do we need to specify these
