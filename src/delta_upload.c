#include <stdio.h>
#include <sqlite3.h>

int main(void) {
    sqlite3 *db;
    char *err_msg = 0;
    int rc;

    rc = sqlite3_open("uptime.db", &db);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        return 1;
    }

    const char *sql =
        "CREATE TABLE IF NOT EXISTS boot_log("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "boot_time INTEGER);"
        "INSERT INTO boot_log(boot_time) VALUES(strftime('%s','now'));";

    rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", err_msg);
        sqlite3_free(err_msg);
    } else {
        printf("Inserted boot time successfully.\n");
    }

    sqlite3_close(db);
    return 0;
}
