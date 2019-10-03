# Wazuh for Bosh

## Prepare release

**Clone repository**

```
git clone https://github.com/wazuh/wazuh-bosh
cd wazuh-bosh
```


**Upload blob**

Upload the blobs to the blob store.

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
Configure manifest/wazuh-agent.yml according to the number of agents you want to deploy.
Modify manifest property ```wazuh_server_address``` with your Wazuh Server IP

**Deploy**
```
bosh -e your_bosh_environment -d wazuh-agent deploy manifest/wazuh-agent.yml
```
