import sqlite3
from pathlib import Path



conn = sqlite3.connect("uptime.db")
cursor = conn.cursor()

cursor.execute("SELECT id FROM sessions ORDER BY id DESC LIMIT 1")
last_id = cursor.fetchone()[0]
# fech last_id 



def upload_db(start, end):
    print(start)
    print(end)
    # for debugging

    if start == end:
        return #do nothing
    
    # Query rows from id 1 to 10
    cursor.execute("SELECT * FROM sessions WHERE id BETWEEN ? AND ?", (start, end))

    rows = cursor.fetchall()

    # Print results
    for row in rows:
        print(row)

    conn.close()


counter_file = Path(".counter")

if counter_file.exists():
    counter = int(counter_file.read_text())
    upload_db(counter, last_id)
else:
    counter_file.write_text(str(last_id))
    upload_db(0, last_id)
# write and read file and upload accordingly
