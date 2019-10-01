# Wazuh for Bosh

## Prepare release

**Clone repository**

```
git clone https://github.com/wazuh/wazuh-bosh-pilot
```


**Download Wazuh source code**

```
mkdir -p /tmp/blobs
curl -o /tmp/blobs/wazuh-3.10.2.tar.gz -L "https://github.com/wazuh/wazuh/archive/v3.10.2.tar.gz"
tar -xvf /tmp/blobs/wazuh-3.10.2.tar.gz -C /tmp/blobs/
make -C /tmp/blobs/wazuh-3.10.2/src deps
rm -f /tmp/blobs/wazuh-3.10.2.tar.gz
tar -czf /tmp/blobs/wazuh-3.10.2.tar.gz -C /tmp/blobs/ wazuh-3.10.2
rm -rf /tmp/blobs/wazuh-3.10.2
```

**Add blobs**

```
bosh add-blob /tmp/blobs/wazuh-3.10.2.tar.gz wazuh/wazuh-3.10.2.tar.gz
```

**Upload blob**

Upload the blob just created to the store.

```
bosh upload-blobs
```

**Create release**

```
bosh create-release --final --version=3.10.2
```

**Upload release**

```
bosh -e your_bosh_environment upload-release
```

## Deploy Wazuh Server
Configure manifest/wazuh-server.yml according to the number of instances you want to create.

**Deploy**
```
bosh -e your_bosh_environment -d wazuh-server deploy manifest/wazuh-server.yml
```

## Deploy Wazuh Agents
Configure manifest/wazuh-agent.yml according to the number of agents you want to deploy.
Modify manifest property ```wazuh_server_address``` with your Wazuh Server IP

**Deploy**
```
bosh -e your_bosh_environment -d wazuh-agent deploy manifest/wazuh-agent.yml
```
