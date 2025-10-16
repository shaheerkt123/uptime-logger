# Quastions

## Code questions

### how to add cron to a rpm/deb

%files
/usr/local/bin/pc_uptime_logger.py
/usr/local/bin/delta_upload.py
/usr/local/bin/delta_upload_cron.sh
/etc/systemd/system/uptime-logger.service
/etc/systemd/system/uptime-logger-shutdown.service
/etc/cron.d/delta_upload

### why do we need to specify these

@docker run --rm -v "$(CURDIR)/$(BUILD_DIR):/app/build:z" $(DEB_IMG_TAG) in Makefile 114

### why is there that :z

      - name: Upload packages artifact
        uses: actions/upload-artifact@v4

      - name: Download unsigned packages
        uses: actions/download-artifact@v4

### what are these
