# Wazuh for Bosh

## Precompile Wazuh Manager and Agent

- Install compilation  dependencies:

```
sudo apt-get update
sudo apt-get install make gcc libc6-dev curl automake autoconf libtool -y
```

- Download and extract desired package

```
mkdir -p /tmp/blobs
curl -o /tmp/blobs/wazuh-3.10.2.tar.gz -L https://github.com/wazuh/wazuh/archive/v3.10.2.tar.gz
tar xvzf /tmp/blobs/wazuh-3.10.2.tar.gz -C /tmp/blobs/
cp /tmp/blob/wazuh-3.10.2 /tpm/blob/wazuh-3.10.2-agent -R
mv /tmp/blob/wazuh-3.10.2 /tmp/blobs/wazuh-3.10.2-manager
```

- Clean previous builds and compile Wazuh Manager

```
make -C /tmp/blobs/wazuh-3.10.2-manager/src clean
make -C /tmp/blobs/wazuh-3.10.2-manager/src deps
make -C /tmp/blobs/wazuh-3.10.2-manager/src -j$(nproc) PREFIX=/var/vcap/packages/wazuh-manager TARGET=server USE_SELINUX=0 USE_AUDIT=0 DISABLE_SHARED=1
```

- Clean previous builds and compile the Wazuh Agent
```
make -C /tmp/blobs/wazuh-3.10.2-agent/src clean
make -C /tmp/blobs/wazuh-3.10.2-agent/src deps
make -C /tmp/blobs/wazuh-3.10.2-agent/src -j$(nproc) PREFIX=/var/vcap/packages/wazuh-agent TARGET=agent USE_SELINUX=0 USE_AUDIT=0 DISABLE_SHARED=1
```

  *Please note the compilation process might take some minutes to complete*

  *The `-j$(nproc)` parameter makes use of all processing units available for the compilation process, feel free to customize it.*


- Compress the precompiled Wazuh Manager and Agent

```
rm -f /tmp/blobs/wazuh-3.10.2.tar.gz
tar -czf /tmp/blobs/wazuh-manager-3.10.2.tar.gz -C /tmp/blobs/ ./wazuh-3.10.2-manager/
tar -czf /tmp/blobs/wazuh-agent-3.10.2.tar.gz -C /tmp/blobs/ ./wazuh-3.10.2-agent/
```


## Prepare the Wazuh Release

- Clone repository

```
git clone https://github.com/wazuh/wazuh-bosh-pilot
cd wazuh-bosh-pilot
```

- Update the [spec](packages/wazuh-agent/spec), [packaging](packages/wazuh-agent/packaging), and [wazuh-agent.yml](manifest/wazuh-agent.yml) files with your compiled Agent version.

- Add blobs to the blobstore (it will automatically update the blobs.yml)

```
bosh add-blob /tmp/blobs/wazuh-agent-3.10.2.tar.gz wazuh-agent/wazuh-agent-3.10.2.tar.gz
bosh add-blob /tmp/blobs/wazuh-manager-3.10.2.tar.gz wazuh-agent/wazuh-manager-3.10.2.tar.gz
```

  *This will update the `blobs.yml` file with the metadata information related to the new files*

- Upload blobs to bosh director

```
bosh upload-blobs
```

- Create the Wazuh release

```
bosh create-release --name=wazuh --version=3.10.2 --final --force
```

*Sometimes it's required to manually remove/synchronize previous Agent TAR file from blobs.yml*

- Upload release to Bosh Director

```
bosh -e <your_bosh_environment> upload-release --name=wazuh --version=3.10.2
```

Redeploy your new/active deployments to make Bosh install and configure the Wazuh Agent on target instances.

## Deploy Wazuh Agents

Obtain the address of your recently deployed Wazuh Manager and update the `wazuh_server_address` and `wazuh_server_address` settings in the [manifest/wazuh-agent.yml](https://github.com/wazuh/wazuh-bosh/blob/master/manifest/wazuh-agent.yml) runtime configuration file.

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent.yml
```

Redeploy your initial manifest to make Bosh install and configure the Wazuh Agent on target instances.


### Deploy Wazuh Agents using SSL

You can register your Wazuh Agents using SSL  to secure the communication as described in [Agent verification using SSL](https://documentation.wazuh.com/3.9/user-manual/registering/manager-verification/agents/linux-unix-agent-verification.html#linux-and-unix-agents)

To pass your generated `sslagent.cert` and `sslagent.key` files to your runtime configuration you simply have to include them in `wazuh_agent_cert` and `wazuh_agent_key` parameters like in the following example:


```yaml
---
  releases:
  - name: "wazuh"
    version: 3.10.2

  addons:
  - name: wazuh
    release: 3.10.2
    jobs:
    - name: wazuh-agent
      release: wazuh
      properties:
          wazuh_server_address: 172.0.3.4
          wazuh_server_registration_address: 172.0.3.4
          wazuh_server_protocol: "tcp"
          wazuh_agents_prefix: "bosh-"
          wazuh_agent_profile: "generic"
          wazuh_agent_cert: |
            -----BEGIN CERTIFICATE-----
            MIIE6jCCAtICCQCeRsKNJC058zANBgkqhkiG9w0BAQsFADAsMQswCQYDVQQGEwJV
            UzELMAkGA1UECAwCQ0ExEDAOBgNVBAoMB01hbmFnZXIwHhcNMjAwMjEwMTExNzQ5
            WhcNMjEwMjA5MTExNzQ5WjBCMQswCQYDVQQGEwJYWDEVMBMGA1UEBwwMRGVmYXVs
            ...
            -----END CERTIFICATE-----
          wazuh_agent_key: |
            -----BEGIN PRIVATE KEY-----
            MIIJQQIBADANBgkqhkiG9w0BAQEFAASCCSswggknAgEAAoICAQDgSRkPQbeFBXWE
            2fG1XZEkJyAVP/wjcuGWRmIufexw/tpVF0+AADhafJwpre+9zYYFDwPeYSN11zAH
            E5KGDhqDh9hie3xnTOllHfjXbvijuqoLkNUU6HsssGFI/epA1Yfyl220ZNE5AZCL
            ...
            -----END PRIVATE KEY-----
    exclude:
      deployments: [wazuh-manager]
```

Then, update your runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent.yml
```

This way, your cert and key will be rendered under `/var/vcap/data/packages/wazuh-agent/<random_id>/etc/` and used in the registration process and any communications between the Agent and Manager.

## General usage notes

### Wazuh deployed via Docker

If your Wazuh Docker deployment does not contain any extra configurations, it will be necessary to modify the `wazuh_server_protocol` property in the [manifest/wazuh-agent.yml](https://github.com/wazuh/wazuh-bosh/blob/master/manifest/wazuh-agent.yml) to `UDP` given that this bosh agent will attempt to connect using the port 1514 that is reserved to UDP in the Docker deployment.

### Cloud Foundry resources registration

Once your Bosh release is completed successfully the agents will be able to register themselves normally against any Wazuh manager. If you choose to use an external manager or deployed agents across different clusters, you might face duplicated IP Addresses.

Wazuh chooses to primarily identify hosts with their IP Addresses but it is possible to change that by modifying the tag `<use_source_ip>` to **no** inside the Wazuh Manager's `ossec.conf` file.
