Name:           uptime-logger
Version:        2.0
Release:        3%{?dist}
Summary:        Logs system uptime and shutdown times

License:        MIT
URL:            https://github.com/shaheerkt123/uptime-logger
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  sqlite-devel
BuildRequires:  libcurl-devel
BuildRequires:  systemd
Requires:       systemd, crontabs

%description
A small tool that logs system uptime and shutdown times, with upload support.

%prep
%setup -q

%build
%make_build

%check
# Placeholder for future tests

%install
make install DESTDIR=%{buildroot} SYSTEMD_DIR=%{_unitdir}

# Create the data directory
install -d %{buildroot}/var/lib/uptime-logger

# Install RPM-specific files
install -d %{buildroot}%{_presetdir}
install -m 644 packaging/rpm/90-uptime-logger.preset %{buildroot}%{_presetdir}/

# Add User and Group to service files
sed -i '/\[Service\]/a User=uptime-logger' %{buildroot}%{_unitdir}/uptime-logger.service
sed -i '/\[Service\]/a Group=uptime-logger' %{buildroot}%{_unitdir}/uptime-logger.service
sed -i '/\[Service\]/a User=uptime-logger' %{buildroot}%{_unitdir}/uptime-logger-shutdown.service
sed -i '/\[Service\]/a Group=uptime-logger' %{buildroot}%{_unitdir}/uptime-logger-shutdown.service
# Run cron job as uptime-logger user
sed -i 's/root/uptime-logger/' %{buildroot}/etc/cron.d/uptime-logger

%pre
# Create a dedicated user and group for the service
getent group uptime-logger >/dev/null || groupadd -r uptime-logger
getent passwd uptime-logger >/dev/null || \
    useradd -r -g uptime-logger -d /var/lib/uptime-logger -s /sbin/nologin \
    -c "Uptime Logger service account" uptime-logger

%post
%systemd_post uptime-logger.service uptime-logger-shutdown.service

%preun
%systemd_preun uptime-logger.service uptime-logger-shutdown.service

%postun
%systemd_postun_with_restart uptime-logger.service uptime-logger-shutdown.service

%files
%license LICENSE
%doc README.md
%{_bindir}/uptime_logger
%{_bindir}/uptime_upload
%{_bindir}/uptime_upload_cron.sh
%{_unitdir}/uptime-logger.service
%{_unitdir}/uptime-logger-shutdown.service
%config(noreplace) /etc/cron.d/uptime-logger
%{_presetdir}/90-uptime-logger.preset
%dir %attr(0755, uptime-logger, uptime-logger) /var/lib/uptime-logger

%changelog
* Mon Oct 13 2025 Shaheer <shaheerkt1234@gmail.com> - 2.0-3
- Final spec file polish to fix rpmlint errors.

* Mon Oct 13 2025 Shaheer <shaheerkt1234@gmail.com> - 2.0-2
- Refactor for repository quality standards
- Use standard RPM macros and build process

* Fri Oct 10 2025 Shaheer <shaheerkt1234@gmail.com> - 2.0-1
- Switch from Python scripts to compiled C binaries

* Sat Oct 04 2025 Shaheer <shaheerkt1234@gmail.com> - 1.0-2
- Create dedicated user and group for service
- Run services and cron job as dedicated user
- Set ownership of /var/lib/uptime-logger

* Wed Oct 01 2025 Shaheer <shaheerkt1234@gmail.com> - 1.0-1
- Initial RPM release