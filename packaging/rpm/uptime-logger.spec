%define debug_package %{nil}
Name:           uptime-logger
Version:        2.0
Release:        1%{?dist}
Summary:        Logs system uptime and shutdown times
License:        MIT
URL:            https://github.com/shaheerkt123/uptime-logger
Source0:        %{name}-%{version}.tar.gz

Requires: sqlite-libs, libcurl, systemd

%description
A small tool that logs system uptime and shutdown times, with upload support.

%pre
# Create a dedicated user and group for the service
getent group uptime-logger >/dev/null || groupadd -r uptime-logger
getent passwd uptime-logger >/dev/null || \
    useradd -r -g uptime-logger -d /var/lib/uptime-logger -s /sbin/nologin \
    -c "Uptime Logger service account" uptime-logger

%prep
%setup -q

%build
# Binaries are pre-compiled via Makefile before rpmbuild is called.

%install
# Just copy the whole tree from tarball into buildroot
cp -a usr %{buildroot}/
cp -a etc %{buildroot}/
mkdir -p %{buildroot}/var/lib/uptime-logger

# Add User and Group to service files
sed -i '/\[Service\]/a User=uptime-logger' %{buildroot}/etc/systemd/system/uptime-logger.service
sed -i '/\[Service\]/a Group=uptime-logger' %{buildroot}/etc/systemd/system/uptime-logger.service
sed -i '/\[Service\]/a User=uptime-logger' %{buildroot}/etc/systemd/system/uptime-logger-shutdown.service
sed -i '/\[Service\]/a Group=uptime-logger' %{buildroot}/etc/systemd/system/uptime-logger-shutdown.service
# Run cron job as uptime-logger user
sed -i 's/root/uptime-logger/' %{buildroot}/etc/cron.d/uptime_upload

%files
/usr/local/bin/uptime_logger
/usr/local/bin/uptime_upload
/usr/local/bin/uptime_upload_cron.sh
/etc/systemd/system/uptime-logger.service
/etc/systemd/system/uptime-logger-shutdown.service
/etc/cron.d/uptime_upload
/usr/lib/systemd/system-preset/90-uptime-logger.preset
%dir %attr(0750, uptime-logger, uptime-logger) /var/lib/uptime-logger

%post
%systemd_post uptime-logger.service uptime-logger-shutdown.service

%preun
%systemd_preun uptime-logger.service uptime-logger-shutdown.service

%postun
%systemd_postun uptime-logger.service uptime-logger-shutdown.service
# Clean up user and group on uninstall
if [ $1 -eq 0 ]; then
    userdel uptime-logger >/dev/null 2>&1 || true
    groupdel uptime-logger >/dev/null 2>&1 || true
fi

%changelog

* Fri Oct 10 2025 Shaheer <shaheerkt1234@gmail.com> - 2.0-1
- Switch from Python scripts to compiled C binaries

* Sat Oct 04 2025 Shaheer <shaheerkt1234@gmail.com> - 1.0-2
- Create dedicated user and group for service
- Run services and cron job as dedicated user
- Set ownership of /var/lib/uptime-logger

* Wed Oct 01 2025 Shaheer <shaheerkt1234@gmail.com> - 1.0-1
- Initial RPM release
uptime_logger
