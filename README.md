# Wazuh for Bosh

## Prepare release

**Clone repository and checkout to branch 4.1**
```
git clone https://github.com/wazuh/wazuh-bosh
cd wazuh-bosh
git checkout 4.1
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

**Download blobs from the `wazuh-bosh` repository using Git LFS**
```
git lfs install
git lfs pull
```

**Upload blobs to the blob store**
```
bosh -e your_bosh_environment upload-blobs
```

**Create release**
```
bosh -e your_bosh_environment create-release --final --version=4.1.5
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

**Check deployment status**

Get instance name.
```
bosh -e your_bosh_environment vms
```
If the deployment succeeded the **Process State** will be **running**.

For further checks connect to the instance using ssh and the Instance Name obtained in the previous command.
```
bosh -e your_bosh_environment -d wazuh-manager ssh InstanceName
```
Check Wazuh Manager status.
```
sudo -i
/var/ossec/bin/ossec-control status
```
The result must be like this:
```
wazuh-clusterd is running...
wazuh-modulesd is running...
ossec-monitord is running...
ossec-logcollector is running...
ossec-remoted is running...
ossec-syscheckd is running...
ossec-analysisd is running...
ossec-maild not running...
ossec-execd is running...
wazuh-db is running...
ossec-authd is running...
ossec-agentlessd not running...
ossec-integratord not running...
ossec-dbd not running...
ossec-csyslogd not running...
wazuh-apid is running...
```

## Deploy Wazuh Agents

Obtain the address of your recently deployed Wazuh Manager and update the `wazuh_server_address` and `wazuh_server_registration_address` settings in the [manifest/wazuh-agent.yml](https://github.com/wazuh/wazuh-bosh/blob/4.1/manifest/wazuh-agent.yml) runtime configuration file.

Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent.yml
```

Redeploy your initial manifest to make Bosh install and configure the Wazuh Agent on target instances.


### Deploy Wazuh Agents using SSL

You can register your Wazuh Agents using SSL  to secure the communication as described in [Agent verification using SSL](https://documentation.wazuh.com/current/user-manual/registering/host-verification-registration.html#available-options-to-verify-the-hosts)

To pass your generated `sslagent.cert` and `sslagent.key` files to your runtime configuration you simply have to include them in `wazuh_agent_cert` and `wazuh_agent_key` parameters like in the following example:


```yaml
---
  releases:
  - name: "wazuh"
    version: 4.1.5

  addons:
  - name: wazuh
    release: 4.1.5
    jobs:
    - name: wazuh-agent
      release: wazuh
      properties:
          wazuh_server_address: 172.31.32.4
          wazuh_server_registration_address: 172.31.32.4
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

This way, your cert and key will be rendered under `/var/ossec/<random_id>/etc/` and used in the registration process and any communications between the Agent and Manager.

## Delete 
**Manager deployment**
```
bosh -e your_bosh_environment -d wazuh-manager deld
```
**Agent Deployment**
```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent-delete.yml
```
**Wazuh Release**
```
bosh -e your_bosh_environment delete-release wazuh/4.1.5
rm -rf dev_releases/wazuh/
rm -rf releases/wazuh/
```
**Blobs**
```
bosh remove-blob /wazuh/wazuh-agent.tar.gz
bosh remove-blob /wazuh/wazuh-manager.tar.gz
```

## General usage notes

### Wazuh deployed via Docker

If your Wazuh Docker deployment does not contain any extra configurations, it will be necessary to modify the `wazuh_server_protocol` property in the [manifest/wazuh-agent.yml](https://github.com/wazuh/wazuh-bosh/blob/master/manifest/wazuh-agent.yml) to `UDP` given that this bosh agent will attempt to connect using the port 1514 that is reserved to UDP in the Docker deployment.

### Cloud Foundry resources registration

Once your Bosh release is completed successfully the agents will be able to register themselves normally against any Wazuh manager. If you choose to use an external manager or deployed agents across different clusters, you might face duplicated IP Addresses.

Wazuh chooses to primarily identify hosts with their IP Addresses but it is possible to change that by modifying the tag `<use_source_ip>` to **no** inside the Wazuh Manager's `ossec.conf` file.
