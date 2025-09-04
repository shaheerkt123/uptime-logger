# Packaging Logger

## Debian (.deb)

### 1.Build the deb file

```bash
 dpkg-deb --build uptime-logger-package
```

## Red Hat Package Manger (.rpm)

### 1.Make a tarball

```bash
tar czf uptime-logger-1.0.tar.gz ~/project/uptime-logger-package/rpm/uptime-logger-package/
mv uptime-logger-1.0.tar.gz ~/rpmbuild/SOURCES/
```

### 2.Copy the Spec file

```bash
cp ~/project/uptime-logger-package/rpm/uptime-logger.spec ~/rpmbuild/SPECS/
```

### 3.Build the rpm file

```bash
rpmbuild -ba ~/rpmbuild/SPECS/uptime-logger.spec
```
