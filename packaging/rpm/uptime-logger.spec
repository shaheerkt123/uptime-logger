Name:           uptime-logger
Version:        1.0
Release:        1%{?dist}
Summary:        Logs system uptime and shutdown times
License:        MIT
URL:            https://github.com/shaheerkt123/uptime-logger
Source0:        %{name}-%{version}.tar.gz

BuildArch: noarch
Requires: python3, python3-psutil, python3-requests, systemd

%description
A small tool that logs system uptime and shutdown times, with upload support.

%prep
%setup -q

%build
# Nothing to build (pure Python + shell scripts)

%install
# Just copy the whole tree from tarball into buildroot
cp -a usr %{buildroot}/
cp -a etc %{buildroot}/

%files
/usr/local/bin/pc_uptime_logger.py
/usr/local/bin/delta_upload.py
/usr/local/bin/check_internet_cron.sh
/etc/systemd/system/uptime-logger.service
/etc/systemd/system/uptime-logger-shutdown.service

%changelog
* Wed Oct 01 2025 Shaheer <shaheerkt1234@gmail.com> - 1.0-1
- Initial RPM release