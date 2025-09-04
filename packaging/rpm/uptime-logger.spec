Name:           uptime-logger
Version:        1.0
Release:        1%{?dist}
Summary:        Logs boot and shutdown times to a SQLite database

License:        GPL
URL:            https://example.com/uptime-logger
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       python3, python3-psutil, python3-requests, systemd, cronie

%description
Simple utility that records boot and shutdown times in ~/uptime.db.
It also sets up a cron job to run delta_upload_cron.sh every minute.

%prep
# Nothing to unpack if you provide plain scripts
%setup -q -c -T

%build
# Pure Python, no build needed
echo "No build needed"

%install
# Create directories
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/etc/systemd/system

# Install Python scripts
install -m 755 pc_uptime_logger.py %{buildroot}/usr/local/bin/
install -m 755 delta_upload.py %{buildroot}/usr/local/bin/
install -m 755 delta_upload_cron.sh %{buildroot}/usr/local/bin/

# Install systemd service files
install -m 644 uptime-logger.service %{buildroot}/etc/systemd/system/
install -m 644 uptime-logger-shutdown.service %{buildroot}/etc/systemd/system/

%post
# Set up cron job
CRON_JOB="* * * * * /usr/local/bin/delta_upload_cron.sh"
if ! crontab -l 2>/dev/null | grep -Fq "$CRON_JOB"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
fi

# RPM systemd macro for enabling & starting services
%systemd_post uptime-logger.service
%systemd_post uptime-logger-shutdown.service

%preun
# RPM systemd macro for stopping & disabling services on removal
%systemd_preun uptime-logger.service
%systemd_preun uptime-logger-shutdown.service

%postun
# RPM systemd macro for cleanup after uninstall
%systemd_postun_with_restart uptime-logger.service
%systemd_postun_with_restart uptime-logger-shutdown.service

# Remove cron job if it exists
CRON_JOB="* * * * * /usr/local/bin/delta_upload_cron.sh"
if crontab -l 2>/dev/null | grep -Fq "$CRON_JOB"; then
    crontab -l 2>/dev/null | grep -vF "$CRON_JOB" | crontab -
fi

%files
%defattr(-,root,root,-)
/usr/local/bin/pc_uptime_logger.py
/usr/local/bin/delta_upload.py
/usr/local/bin/delta_upload_cron.sh
/etc/systemd/system/uptime-logger.service
/etc/systemd/system/uptime-logger-shutdown.service

%changelog
* Sat Sep 28 2025 Shaheer <shaheerkt1234@gmail.com> - 1.0-1
- Initial RPM release using systemd macros
