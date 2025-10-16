
# Uptime Logger

<!-- <p align="center">
  <img src="https://user-images.githubusercontent.com/82405223/275763393-52a2f24a-b380-4090-b887-4473b005b7e6.png" alt="Uptime Logger Banner" width="600"/>
</p>

<p align="center">
  <strong>A simple, lightweight utility for Linux systems that records system boot and shutdown times.</strong>
</p>

<p align="center">
    <a href="https://github.com/shaheerkt/uptime-logger/releases">
        <img src="https://img.shields.io/github/v/release/shaheerkt/uptime-logger?style=for-the-badge" alt="GitHub release" />
    </a>
    <a href="https://github.com/shaheerkt/uptime-logger/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/shaheerkt/uptime-logger?style=for-the-badge" alt="License" />
    </a>
</p>

--- -->

Uptime Logger is a simple, lightweight utility for Linux systems that records system boot and shutdown times. It is written in C and uses a SQLite database to store the uptime data. The project is designed to be packaged for both Debian (`.deb`) and RPM (`.rpm`) based distributions.

It also includes a feature to upload the collected data to a specified `ntfy.sh` topic, allowing for remote monitoring of system uptime.

## Table of Contents

- [Features](#features)
- [How it Works](#how-it-works)
- [Building from Source](#building-from-source)
- [Installation](#installation)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Installation

You can install the Uptime Logger by installing `.deb` or `.rpm` package from [Releases](https://github.com/shaheerkt123/uptime-logger/releases) page.

### On Debian/Ubuntu

```bash
sudo dpkg -i build/uptime-logger_2.0-1.deb
```

### On Fedora/CentOS/RHEL

```bash
sudo rpm -i build/uptime-logger-2.0-1.x86_64.rpm
```

## Features

- Logs system boot and shutdown times to a local SQLite database.
- Provides a command-line interface to view logged sessions.
- Includes a utility to upload uptime data to an `ntfy.sh` topic.
- Packaged for easy installation on Debian and RPM-based systems.
- Systemd services for automatic logging of boot and shutdown events.
- Cron job for periodic uploading of uptime data.

## How it Works

The core of the project consists of two C programs:

- `uptime_logger`: This program is responsible for logging boot and shutdown times.
  - When run without arguments, it logs the system's boot time.
  - When run with the `-s` or `--shutdown` flag, it logs the shutdown time for the current session.
  - The `-l` or `--list` flag can be used to display all logged sessions.
- `uptime_upload`: This utility reads the SQLite database and uploads any new, un-uploaded sessions to a configured `ntfy.sh` topic. It keeps track of the last uploaded session ID to avoid duplicate uploads.

The project uses `systemd` services to automate the logging process:

- `uptime-logger.service`: A one-shot service that runs on boot to log the start time.
- `uptime-logger-shutdown.service`: A one-shot service that runs during the shutdown process to log the end time.

A cron job is also included to periodically run the `uptime_upload` utility, ensuring that uptime data is regularly sent to the configured `ntfy.sh` topic.

## Building from Source

The recommended way to build the packages from source is by using the provided Dockerfiles, which ensures a clean and reproducible build environment.

### Building with Docker

First, ensure you have a local `build` directory for the output files:

```sh
mkdir -p build
```

#### Build Debian Package (.deb)

1. **Build the Docker image:**

```sh
docker build -t uptime-logger-deb-builder -f packaging/debian/Dockerfile .
```

2.**Run the build:**
    ```sh
    docker run --rm -v $(pwd)/build:/app/build uptime-logger-deb-builder
    ```
    The `.deb` package will be available in your local `build/` directory.

#### Build RPM Package (.rpm)

1.**Build the Docker image:**
    ```sh
    docker build -t uptime-logger-rpm-builder -f packaging/rpm/Dockerfile .
    ```
2.**Run the build:**
    ```sh
    docker run --rm -v $(pwd)/build:/app/build uptime-logger-rpm-builder
    ```
    The `.rpm` packages will be available in your local `build/` directory.

### Building Natively (Advanced)

If you prefer to build on your host system directly, you must install all the required dependencies for your distribution (e.g., `gcc`, `libsqlite3-dev`, `rpm-build`, etc.).

```bash
# To build the binaries
make build

# To build the RPM package (requires RPM build tools)
make rpm
```

## Configuration

The behavior of the `uptime_logger` and `uptime_upload` utilities can be configured using environment variables:

- `UPTIME_DB_PATH`: The path to the SQLite database file. Defaults to `/var/lib/uptime-logger/uptime.db`.
- `UPTIME_COUNTER_FILE`: The path to the file that stores the ID of the last uploaded session. Defaults to `/var/lib/uptime-logger/.counter`.
- `UPTIME_NTFY_URL`: The `ntfy.sh` topic URL to which the uptime data should be uploaded. Defaults to `https://ntfy.sh/uptime_logger`.

These variables can be set in the `systemd` service files or in the cron job definition to customize the behavior of the logger and uploader.

## Contributing

Contributions are welcome! If you would like to contribute to the project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them with a clear and descriptive commit message.
4. Push your changes to your fork.
5. Create a pull request to the main repository.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
