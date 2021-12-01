## Create Wazuh binaries blob.

Current Wazuh Bosh version does only support Ubuntu Xenial stemcell.
If you want to create the pre-compiled binaries from the source code, run the following commands in a Ubuntu Xenial env.

### Build Docker image
From the root wazuh-bosh repository directory run the following command:
```
docker build . -t create_binaries:4.3.0
```

### Run the Docker container
```
docker run --rm -ti --name bosh_binaries -v <localDirectoryPath>:/root/packages -e WAZUH_VERSION=4.3.0 create_binaries:4.3.0
```
Where `<localDirectoryPath>` must be replaced with the absolute path of the local directory where the compressed files will be stored.
This Docker will create the packages for the Manager and the Agent.
