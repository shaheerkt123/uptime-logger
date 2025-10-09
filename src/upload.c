/*
 * delta_upload.c
 *
 * Reads the uptime-logger database, calculates the delta of sessions not yet
 * uploaded, and sends them to an ntfy.sh topic.
 *
 * Dependencies:
 * - libsqlite3-dev
 * - libcurl4-openssl-dev (or similar libcurl development package)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>
#include <curl/curl.h>
#include <time.h>

// --- Configuration ---
// These can be overridden by environment variables.
#define DEFAULT_DB_FILE "/var/lib/uptime-logger/uptime.db"
#define DEFAULT_COUNTER_FILE "/var/lib/uptime-logger/.counter"
#define DEFAULT_NTFY_URL "https://ntfy.sh/uptime_logger"

// --- Function Prototypes ---
int get_last_session_id(sqlite3 *db);
int read_counter(const char *path);
void write_counter(const char *path, int last_id);
int upload_delta(sqlite3 *db, int start_id, int end_id, const char* ntfy_url);

// --- Main Logic ---
int main(void) {
    // Get configuration from environment or use defaults
    const char *db_file = getenv("UPTIME_DB_PATH") ? getenv("UPTIME_DB_PATH") : DEFAULT_DB_FILE;
    const char *counter_file = getenv("UPTIME_COUNTER_FILE") ? getenv("UPTIME_COUNTER_FILE") : DEFAULT_COUNTER_FILE;
    const char *ntfy_url = getenv("UPTIME_NTFY_URL") ? getenv("UPTIME_NTFY_URL") : DEFAULT_NTFY_URL;

    // Open database
    sqlite3 *db;
    if (sqlite3_open_v2(db_file, &db, SQLITE_OPEN_READONLY, NULL) != SQLITE_OK) {
        fprintf(stderr, "Can't open database '%s': %s\n", db_file, sqlite3_errmsg(db));
        return 1;
    }

    // Get latest session ID from DB
    int last_id_in_db = get_last_session_id(db);
    if (last_id_in_db == 0) {
        printf("Database is empty, nothing to do.\n");
        sqlite3_close(db);
        return 0;
    }

    // Get last uploaded ID from counter file
    int last_uploaded_id = read_counter(counter_file);

    // Upload the delta
    printf("Last uploaded ID: %d, Last ID in DB: %d\n", last_uploaded_id, last_id_in_db);
    if (upload_delta(db, last_uploaded_id, last_id_in_db, ntfy_url) == 0) {
        // If upload was successful, update the counter
        write_counter(counter_file, last_id_in_db);
        if (last_id_in_db > last_uploaded_id) {
            printf("Successfully uploaded sessions from ID %d to %d.\n", last_uploaded_id + 1, last_id_in_db);
        }
    } else {
        fprintf(stderr, "Upload failed.\n");
    }

    sqlite3_close(db);
    return 0;
}

// --- Function Implementations ---

int get_last_session_id(sqlite3 *db) {
    sqlite3_stmt *stmt;
    const char *sql = "SELECT id FROM sessions ORDER BY id DESC LIMIT 1;";
    int id = 0;

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
        fprintf(stderr, "DB error (get_last_session_id): %s\n", sqlite3_errmsg(db));
        return 0;
    }
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        id = sqlite3_column_int(stmt, 0);
    }
    sqlite3_finalize(stmt);
    return id;
}

int read_counter(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) {
        // If file doesn't exist, it's the first run.
        return 0;
    }
    int counter = 0;
    if (fscanf(f, "%d", &counter) != 1) {
        counter = 0; // Handle empty or malformed file
    }
    fclose(f);
    return counter;
}

void write_counter(const char *path, int last_id) {
    FILE *f = fopen(path, "w");
    if (!f) {
        perror("Error opening counter file for writing");
        return;
    }
    fprintf(f, "%d", last_id);
    fclose(f);
}

// Callback for libcurl to handle response data (we suppress it)
size_t write_callback(void *ptr, size_t size, size_t nmemb, void *userdata) {
    // By returning the total number of bytes, we tell libcurl we have
    // handled all the data, effectively discarding it.
    (void)ptr; // Unused
    (void)userdata; // Unused
    return size * nmemb;
}


int upload_delta(sqlite3 *db, int start_id, int end_id, const char* ntfy_url) {
    if (start_id >= end_id) {
        printf("No new sessions to upload.\n");
        return 0; // Not an error, just nothing to do.
    }

    sqlite3_stmt *stmt;
    const char *sql = "SELECT id, boot_time, shutdown_time FROM sessions WHERE id > ? AND id <= ?;";
    
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
        fprintf(stderr, "DB error (upload_delta): %s\n", sqlite3_errmsg(db));
        return 1;
    }
    sqlite3_bind_int(stmt, 1, start_id);
    sqlite3_bind_int(stmt, 2, end_id);

    // Build the message payload
    size_t msg_capacity = 1024;
    char *msg = malloc(msg_capacity);
    if (!msg) { return 1; } 
    msg[0] = '\0';
    size_t msg_len = 0;
    
    char row_buffer[200];

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int id = sqlite3_column_int(stmt, 0);
        time_t boot_time = sqlite3_column_int64(stmt, 1);
        time_t shutdown_time = sqlite3_column_int64(stmt, 2);

        snprintf(row_buffer, sizeof(row_buffer), "(id=%d, boot=%ld, shutdown=%ld)\n", id, (long)boot_time, (long)shutdown_time);
        
        // Append to message, reallocating if necessary
        size_t row_len = strlen(row_buffer);
        if (msg_len + row_len + 1 > msg_capacity) {
            msg_capacity *= 2;
            char *new_msg = realloc(msg, msg_capacity);
            if (!new_msg) { free(msg); return 1; }
            msg = new_msg;
        }
        strcat(msg, row_buffer);
        msg_len += row_len;
    }
    sqlite3_finalize(stmt);

    if (msg_len == 0) {
        printf("No new sessions found in range.\n");
        free(msg);
        return 0;
    }

    // --- Send with libcurl ---
    CURL *curl;
    CURLcode res;
    int ret_code = 0;

    curl_global_init(CURL_GLOBAL_ALL);
    curl = curl_easy_init();
    if(curl) {
        curl_easy_setopt(curl, CURLOPT_URL, ntfy_url);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, msg);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);

        res = curl_easy_perform(curl);
        if(res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            ret_code = 1;
        }

        curl_easy_cleanup(curl);
    }
    curl_global_cleanup();
    free(msg);

    return ret_code;
}
