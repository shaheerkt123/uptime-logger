# How the Debian (.deb) Package is Built

The Debian package creation is designed to be run inside the packaging/debian/Dockerfile.

1. Environment Setup: The Dockerfile starts with a debian:stable-slim image, installs essential build tools like debhelper, and then uses apt-get build-dep . to automatically install the
   build dependencies (libsqlite3-dev, libcurl4-openssl-dev) listed in your packaging/debian/control file.
2. Source Code: The entire project source code is copied into the container.
3. Build Execution: The container's main command runs dpkg-buildpackage -us -uc. This is the standard command to build a Debian package.
4. The `rules` File: dpkg-buildpackage uses packaging/debian/rules as its instruction manual. Your rules file is a minimal one that uses dh, the debhelper tool. dh automates the build steps.
5. Compilation & Installation: debhelper automatically calls make to compile your C code and then make install to copy the compiled binaries and service files into a temporary staging area.
6. Packaging: Finally, dpkg-buildpackage bundles everything into a .deb file and moves it to the build/ directory inside the container.

How the RPM (.rpm) Package is Built

The RPM build process is orchestrated by the Makefile and designed to be run inside the packaging/rpm/Dockerfile.

1. Environment Setup: The Dockerfile uses a fedora:latest image, installs rpm-build tools, and then uses dnf builddep to install the BuildRequires (sqlite-devel, libcurl-devel, etc.) from
   your packaging/rpm/uptime-logger.spec file.
2. Build Execution: The container's main command runs make rpm.
3. Source Tarball: The rpm target in the Makefile first calls the dist target, which creates a source code tarball (uptime-logger-2.0.tar.gz).
4. RPMBuild: make rpm then executes rpmbuild -ba ..., pointing to the .spec file. rpmbuild is the master command for creating RPMs.
5. The `spec` File: The .spec file tells rpmbuild everything it needs to know:
      * %build: This section runs make, which compiles your C code.
      * %install: This section runs make install to copy the compiled files into a build root.
      * Custom Logic: The spec file then runs several sed commands to modify the systemd service files and the cron job, making them run as a dedicated uptime-logger user.
      * %pre: This scriptlet creates the uptime-logger user and group before the package is installed on a user's machine.
6. Packaging: rpmbuild creates the final .rpm package, which the Makefile then moves into the build/ directory.
