## Create Wazuh binaries blob.

Current Wazuh Bosh version does only support Ubuntu Xenial stemcell.
Prepare the pre-compiled binaries in a Ubuntu Xenial host.

# Install dependencies

```
apt-get install python gcc make libc6-dev curl policycoreutils automake autoconf libtool -y
echo "deb-src http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs) main" >> /etc/apt/sources.list
apt-get update
apt-get build-dep python3.5 -y
```

# Download Wazuh source code and compile shared dependencies

```
cd ~
curl -Ls https://github.com/wazuh/wazuh/archive/v3.10.2.tar.gz | tar zx
mv wazuh-*/ wazuh
cd wazuh/src
make deps
```

# Prepare Manager binaries blob

```
cd ~
cd wazuh/src
make clean
make -j8 PREFIX=/var/vcap/packages/wazuh-manager TARGET=server USE_SELINUX=0 USE_AUDIT=0
cd ../..
tar -czvf wazuh-manager.tar.gz -C wazuh .
```

# Prepare Agent binaries blob
```
cd ~
cd wazuh/src
make clean
make -j8 PREFIX=/var/vcap/packages/wazuh-agent TARGET=agent USE_SELINUX=0 USE_AUDIT=0
cd ../..
tar -czvf wazuh-agent.tar.gz -C wazuh .
```
