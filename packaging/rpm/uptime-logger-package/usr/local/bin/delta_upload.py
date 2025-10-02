import sqlite3, sys
from pathlib import Path
import requests

DB_FILE = "/var/lib/uptime-logger/uptime.db"
NTFY_URL = "https://ntfy.sh/uptime_logger"


conn = sqlite3.connect(DB_FILE)
cursor = conn.cursor()

cursor.execute("SELECT id FROM sessions ORDER BY id DESC LIMIT 1")
result = cursor.fetchone()
if result is None:
    sys.exit("Database is empty, nothing to do.")
last_id = result[0]
# fech last_id 



def upload_db(start, end):
    if start == end:
        return #do nothing
    
    print(start, end) # for debugging

    # Query rows from id 1 to 10
    cursor.execute("SELECT * FROM sessions WHERE id BETWEEN ? AND ?", (start, end))
    rows = cursor.fetchall()

    if not rows:
        return  # nothing to upload
    
        # Format rows as a readable string
    msg = "\n".join(str(row) for row in rows)

    # Send to ntfy
    requests.post(NTFY_URL, data=msg.encode("utf-8"))

    # Print results
    for row in rows:
        print(row)

    conn.close()


counter_file = Path("/var/lib/uptime-logger/.counter")

if counter_file.exists():
    counter = int(counter_file.read_text())
    upload_db(counter, last_id)
else:
    counter_file.write_text(str(last_id))
    upload_db(0, last_id)
# write and read file and upload accordingly
