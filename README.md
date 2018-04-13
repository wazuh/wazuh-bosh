# Wazuh for Bosh

## Prepare release

**Clone repository**

```
git clone https://github.com/wazuh/wazuh-bosh
```


**Download Wazuh source code**

```
mkdir /tmp/blobs
curl -o /tmp/blobs/wazuh-3.2.1.tar.gz -L "https://github.com/wazuh/wazuh/archive/v3.2.1.tar.gz"
```

**Add blobs**

```
bosh add-blob /tmp/blobs/wazuh-3.2.1.tar.gz wazuh-server/wazuh-server-3.2.1.tar.gz
bosh add-blob /tmp/blobs/wazuh-3.2.1.tar.gz wazuh-agent/wazuh-agent-3.2.1.tar.gz
```

**Upload blob to S3**

If you have configured an external S3 bucket to store blobs, you can upload the blob just created to the store.

```
bosh upload-blobs
```

**Create release**

```
bosh create-release --final --version=3.2.1
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
