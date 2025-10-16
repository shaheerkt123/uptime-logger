#!/bin/bash
set -e

# This script signs Debian and RPM packages.
# It expects the following environment variables to be set:
# - GPG_PRIVATE_KEY: The ASCII-armored GPG private key.
# - GPG_PASSPHRASE: The passphrase for the GPG key.

# --- GPG and RPM Macro Setup ---

# Import the GPG key
echo "Importing GPG key..."
echo "$GPG_PRIVATE_KEY" | gpg --batch --import
GPG_KEY_ID=$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f5)
echo "GPG Key ID: $GPG_KEY_ID"

# Configure RPM to use the GPG key
echo "Configuring RPM macros..."
cat > ~/.rpmmacros <<EOF
%_signature gpg
%_gpg_name $GPG_KEY_ID
%_gpg_digest_algo sha256
%__gpg_sign_cmd %{__gpg} gpg --batch --verbose --no-armor --pinentry-mode loopback --passphrase-env GPG_PASSPHRASE --sign -u %{_gpg_name} -o %{__signature_filename} %{__plaintext_filename}
EOF

# --- Install Signing Tools ---
echo "Installing signing tools..."
sudo apt-get update
sudo apt-get install -y rpm devscripts

# --- Sign Packages ---
ARTIFACTS_DIR="artifacts"
SIGNED_DIR="signed_artifacts"
mkdir -p "$SIGNED_DIR"

echo "Signing packages in $ARTIFACTS_DIR..."
for pkg in "$ARTIFACTS_DIR"/*; do
  echo "Processing $pkg..."
  if [[ "$pkg" == *.rpm ]]; then
    echo "Signing RPM package..."
    rpm --addsign "$pkg"
    mv "$pkg" "$SIGNED_DIR/"
  elif [[ "$pkg" == *.deb ]]; then
    echo "Signing Debian package..."
    # debsign will use the default key, which we've just imported.
    # We need to make sure GPG uses the passphrase from the environment variable.
    # debsign doesn't have a direct way to pass the passphrase, but it respects
    # gpg's options. We can use gpg-agent.
    eval $(gpg-agent --daemon --pinentry-mode loopback --passphrase-env GPG_PASSPHRASE)
    debsign -k"$GPG_KEY_ID" "$pkg"
    mv "$pkg" "$SIGNED_DIR/"
  else
    echo "Unknown package type, moving without signing."
    mv "$pkg" "$SIGNED_DIR/"
  fi
done

echo "Signing complete. Signed packages are in $SIGNED_DIR."
