# Wazuh for Bosh

## Prepare release

**Clone repository and checkout to branch v4.2.5**
```
git clone https://github.com/wazuh/wazuh-bosh
cd wazuh-bosh
git checkout v4.2.5
```

**Single or Multi Node Wazuh Cluster**

First of all it will be neccessary to determine the kind of deployment. If it is a Multi Node Cluster with more than one Worker Node there will be some changes to apply prior to the Release creation:
- In [manifest/wazuh-agent-cluster.yml](https://github.com/wazuh/wazuh-bosh/blob/v4.2.5/manifest/wazuh-agent-cluster.yml) add a new property (wazuh_server_worker_address_#) for each extra worker node. The IPs can be assigned before the deployment. Example:
```yaml
      properties:
          wazuh_server_address: 172.31.32.4 
          wazuh_server_registration_address: 172.31.32.4
          wazuh_server_worker_address: 172.31.32.5
          wazuh_server_worker_address_2: 172.31.32.6
          wazuh_server_worker_address_3: 172.31.32.7
          wazuh_server_protocol: "tcp"
          wazuh_agents_prefix: "bosh-"
          wazuh_agent_profile: "generic"
          wazuh_multinode: true
```

- Add another server tag for each extra worker node on [jobs/wazuh-agent/templates/config/ossec_cluster.conf.erb](https://github.com/wazuh/wazuh-bosh/blob/v4.2.5/jobs/wazuh-agent/templates/config/ossec_cluster.conf.erb). Example:
```xml
    <server>
      <address><%= p("wazuh_server_worker_address") %></address>
      <port>1514</port>
      <protocol><%= p("wazuh_server_protocol") %></protocol>
    </server>
    <server>
      <address><%= p("wazuh_server_worker_address_2") %></address>
      <port>1514</port>
      <protocol><%= p("wazuh_server_protocol") %></protocol>
    </server>
    <server>
      <address><%= p("wazuh_server_worker_address_3") %></address>
      <port>1514</port>
      <protocol><%= p("wazuh_server_protocol") %></protocol>
    </server>
    <server>
      <address><%= p("wazuh_server_address") %></address>
      <port>1514</port>
      <protocol><%= p("wazuh_server_protocol") %></protocol>
    </server>
```
Where **wazuh_server_worker_address_2** and **wazuh_server_worker_address_3** are the properties added on the previous step.

**Install Git LFS (Ubuntu/Debian)**
```
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs
```

**Install Git LFS (MacOS)**
```
brew install git-lfs
```

**Download blobs from the `S3` repository using Curl**
```
curl https://packages-dev.wazuh.com/bosh/wazuh-manager-4.2.5.tar.gz -o blobs/wazuh/wazuh-manager.tar.gz
curl https://packages-dev.wazuh.com/bosh/wazuh-agent-4.2.5.tar.gz -o blobs/wazuh/wazuh-agent.tar.gz
```

**Add blobs to Bosh environment**
```
bosh add-blob blobs/wazuh/wazuh-manager.tar.gz /wazuh/wazuh-manager.tar.gz
bosh add-blob blobs/wazuh/wazuh-agent.tar.gz /wazuh/wazuh-agent.tar.gz
```

**Upload blobs to the blob store**
```
bosh -e your_bosh_environment upload-blobs
```

**Create release**
```
bosh -e your_bosh_environment create-release --final --version=4.2.5 --force
```

**Upload release**
```
bosh -e your_bosh_environment upload-release
```

## Deploy Wazuh Server

**Deploy Master Node**
Execute the following command to deploy the Master Node:
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
/var/ossec/bin/wazuh-control status
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

**Deploy Worker Node**

Execute this step only if you need to deploy a multi-node Wazuh Cluster.
Configure [manifest/wazuh-manager-worker.yml](https://github.com/wazuh/wazuh-bosh/blob/v4.2.5/manifest/wazuh-manager-worker.yml) according to the number of **instances** you want to create.

Obtain the address of your recently deployed Wazuh Manager and update the `wazuh_master_address` setting in the [manifest/wazuh-manager-worker.yml](https://github.com/wazuh/wazuh-bosh/blob/v4.2.5/manifest/wazuh-manager-worker.yml) runtime configuration file.
Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Execute the following command to deploy the Worker Node:
```
bosh -e your_bosh_environment -d wazuh-manager-worker deploy manifest/wazuh-manager-worker.yml
```
## Deploy Wazuh Agents

**Single Node Wazuh Cluster**

Obtain the address of your recently deployed Wazuh Manager and update the `wazuh_server_address` and `wazuh_server_registration_address` settings in the [manifest/wazuh-agent.yml](https://github.com/wazuh/wazuh-bosh/blob/v4.2.5/manifest/wazuh-agent.yml) runtime configuration file.

**NOTE: `wazuh_server_worker_address` will not be used in this deployment but it must have a value.**

Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent.yml
```

Redeploy your initial manifest to make Bosh install and configure the Wazuh Agent on target instances.

**Multi Node Wazuh Cluster**

Obtain the address of your recently deployed Wazuh Manager Master and Worker nodes and update the following settings in the [manifest/wazuh-agent-cluster.yml](https://github.com/wazuh/wazuh-bosh/blob/v4.2.5/manifest/wazuh-agent-cluster.yml) runtime configuration file.
- `wazuh_server_address` (Master Node IP)
- `wazuh_server_registration_address` (Master Node IP) 
- `wazuh_server_worker_address` (Worker Node IP). If there are more than one worker nodes assign the values to the `wazuh_server_worker_address_#` properties.

Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent-cluster.yml
```

Redeploy your initial manifest to make Bosh install and configure the Wazuh Agent on target instances.

### Deploy Wazuh Agents using SSL

You can register your Wazuh Agents using SSL  to secure the communication as described in [Agent verification using SSL](https://documentation.wazuh.com/current/user-manual/registering/host-verification-registration.html#available-options-to-verify-the-hosts)

To pass your generated `sslagent.cert` and `sslagent.key` files to your runtime configuration you simply have to include them in `wazuh_agent_cert` and `wazuh_agent_key` parameters like in the following example:


```yaml
---
  releases:
  - name: "wazuh"
    version: 4.2.5

  addons:
  - name: wazuh
    release: 4.2.5
    jobs:
    - name: wazuh-agent
      release: wazuh
      properties:
          wazuh_server_address: 172.31.32.4
          wazuh_server_registration_address: 172.31.32.4
          wazuh_server_worker_address: 172.31.32.5
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

## Delete Procedure
**Manager Worker deployment**
```
bosh -e your_bosh_environment -d wazuh-manager-worker deld
```
**Manager Master deployment**
```
bosh -e your_bosh_environment -d wazuh-manager deld
```
**Agent Deployment**
```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent-delete.yml
```
**Wazuh Release**
```
bosh -e your_bosh_environment delete-release wazuh/4.2.5
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
