# Wazuh for Bosh

## Prepare release

**Clone repository**

```
git clone https://github.com/wazuh/wazuh-bosh
cd wazuh-bosh
```

**Download blobs from Git LFS (Ubuntu/Debian)**

```
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs
git lfs install
git lfs pull
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

Obtain the address of your recently deployed Wazuh Manager and update the `wazuh_server_address` and `wazuh_server_address` settings in the [manifest/wazuh-agent.yml](https://github.com/wazuh/wazuh-bosh/blob/master/manifest/wazuh-agent.yml) runtime configuration file.

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=wazuh-agent-addons manifest/wazuh-agent.yml
```

Redeploy your initial manifest to make Bosh install and configure the Wazuh Agent on target instances.
