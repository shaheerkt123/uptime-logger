#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <sqlite3.h>

#define DEFAULT_DB_FILE "/var/lib/uptime-logger/uptime.db"

// Function to get the system boot time from /proc/stat
long get_boot_time() {
    FILE *f = fopen("/proc/stat", "r");
    if (!f) {
        perror("Error opening /proc/stat");
        return 0;
    }

    char line[256];
    long btime = 0;
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "btime ", 6) == 0) {
            if (sscanf(line, "btime %ld", &btime) == 1) {
                break;
            }
        }
    }
    fclose(f);

    if (btime == 0) {
        fprintf(stderr, "Error: Could not find 'btime' in /proc/stat\n");
    }
    return btime;
}

// Function to initialize the database and create the 'sessions' table
int init_db(sqlite3 *db) {
    char *err_msg = 0;
    const char *sql = "CREATE TABLE IF NOT EXISTS sessions ("
                      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                      "boot_time INTEGER NOT NULL UNIQUE,"
                      "shutdown_time INTEGER);";
    int rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", err_msg);
        sqlite3_free(err_msg);
        return 1;
    }
    return 0;
}
// Function to log the boot time
void log_boot(sqlite3 *db) {
    long boot_time = get_boot_time();
    if (boot_time == 0) {
        return;
    }

    sqlite3_stmt *stmt;
    const char *sql = "INSERT OR IGNORE INTO sessions (boot_time) VALUES (?);";

    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to prepare statement: %s\n", sqlite3_errmsg(db));
        return;
    }

    sqlite3_bind_int64(stmt, 1, boot_time);

    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE) {
        fprintf(stderr, "Execution failed: %s\n", sqlite3_errmsg(db));
    } else {
        if (sqlite3_changes(db) > 0) {
            printf("Boot time logged successfully.\n");
        } else {
            printf("Boot session already logged.\n");
        }
    }

    sqlite3_finalize(stmt);
}

// Function to log the shutdown time
void log_shutdown(sqlite3 *db) {
    long boot_time = get_boot_time();
    if (boot_time == 0) {
        return;
    }

    long shutdown_time = time(NULL);
    sqlite3_stmt *stmt;
    const char *sql = "UPDATE sessions SET shutdown_time = ? WHERE boot_time = ? AND shutdown_time IS NULL;";

    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to prepare statement: %s\n", sqlite3_errmsg(db));
        return;
    }

    sqlite3_bind_int64(stmt, 1, shutdown_time);
    sqlite3_bind_int64(stmt, 2, boot_time);

    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE) {
        fprintf(stderr, "Execution failed: %s\n", sqlite3_errmsg(db));
    } else {
        if (sqlite3_changes(db) > 0) {
            printf("Shutdown time logged successfully.\n");
        } else {
            printf("No active session found for the current boot time. Run without flags first.\n");
        }
    }

    sqlite3_finalize(stmt);
}

// Function to list all logged sessions
void list_sessions(sqlite3 *db) {
    sqlite3_stmt *stmt;
    const char *sql = "SELECT id, boot_time, shutdown_time FROM sessions ORDER BY boot_time DESC;";

    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to prepare statement: %s\n", sqlite3_errmsg(db));
        return;
    }

    printf("%-5s | %-25s | %-25s\n", "ID", "Boot Time", "Shutdown Time");
    printf("------|---------------------------|---------------------------\n");

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int id = sqlite3_column_int(stmt, 0);
        const unsigned char *boot_time = sqlite3_column_text(stmt, 1);
        const unsigned char *shutdown_time = sqlite3_column_text(stmt, 2);

        // Check for NULL pointers before using them
        const char *boot_str = boot_time ? (const char *)boot_time : "N/A";
        const char *shut_str = shutdown_time ? (const char *)shutdown_time : "Still running";

        printf("%-5d | %-25s | %-25s\n", id, boot_str, shut_str);
    }

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "Execution failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(stmt);
}

void print_usage(const char *prog_name) {
    fprintf(stderr, "Usage: %s [flag]\n", prog_name);
    fprintf(stderr, "Flags:\n");
    fprintf(stderr, "  (no flag)             Logs the system boot time for the current session.\n");
    fprintf(stderr, "  -s, --shutdown        Logs the system shutdown time for the current session.\n");
    fprintf(stderr, "  -l, --list            Lists all logged sessions from the database.\n");
    fprintf(stderr, "\nConfiguration:\n");
    fprintf(stderr, "  The database file path can be set using the UPTIME_DB_PATH environment variable.\n");
    fprintf(stderr, "  Default path is './uptime.db'.\n");
}

int main(int argc, char *argv[]) {
    enum { MODE_BOOT, MODE_SHUTDOWN, MODE_LIST } mode = MODE_BOOT;

    if (argc > 2) {
        print_usage(argv[0]);
        return 1;
    }
    if (argc == 2) {
        if (strcmp(argv[1], "-s") == 0 || strcmp(argv[1], "--shutdown") == 0) {
            mode = MODE_SHUTDOWN;
        } else if (strcmp(argv[1], "-l") == 0 || strcmp(argv[1], "--list") == 0) {
            mode = MODE_LIST;
        } else {
            print_usage(argv[0]);
            return 1;
        }
    }

    const char* db_path = getenv("UPTIME_DB_PATH");
    if (!db_path) {
        db_path = DEFAULT_DB_FILE;
    }

    sqlite3 *db;
    int rc = sqlite3_open(db_path, &db);
    if (rc) {
        fprintf(stderr, "Can't open database '%s': %s\n", db_path, sqlite3_errmsg(db));
        return 1;
    }

    if (init_db(db) != 0) {
        sqlite3_close(db);
        return 1;
    }

    switch (mode) {
        case MODE_BOOT:
            log_boot(db);
            break;
        case MODE_SHUTDOWN:
            log_shutdown(db);
            break;
        case MODE_LIST:
            list_sessions(db);
            break;
    }

    sqlite3_close(db);
    return 0;
}
