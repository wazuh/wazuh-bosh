# Wazuh for Bosh

## Prepare release

**Clone repository**
```
git clone https://github.com/wazuh/wazuh-bosh
cd wazuh-bosh
```

**Install Git LFS (Ubuntu/Debian)**
```
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs
```

**Install Git LFS (MacOS)**
```
brew install git-lfs
```

**Download blobs from Git LFS**
```
git lfs install
git lfs pull
```

**Upload blobs to the blob store**
```
bosh upload-blobs
```

**Create release**
```
bosh create-release --final --version=x.y.z
```

**Upload release**
```
bosh -e your_bosh_environment upload-release
```

## Deploy Wazuh Server

Configure manifest/wazuh-manager.yml according to the number of instances you want to create.

**Deploy**
```
bosh -e your_bosh_environment -d wazuh-manager deploy manifest/wazuh-manager.yml
```

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
