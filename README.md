## Prepare release

**Clone repository**

```
git clone https://github.com/wazuh/wazuh-bosh
```


**Download Wazuh source code**

```
mkdir /tmp/blobs
curl -o /tmp/blobs/wazuh-server-3.0.0.tar.gz -L "https://github.com/wazuh/wazuh/archive/3.0.tar.gz"
```

**Add blobs**

```
bosh add-blob /tmp/blobs/wazuh-server-3.0.0.tar.gz wazuh-server/wazuh-server-3.0.0.tar.gz
```

**Upload blob to S3**

If you have configured an external S3 bucket to store blobs, you can upload the blob just created to the store.
```
bosh upload-blobs
```

**Create release**
```
bosh create-release --final --version=3.0.0
```

**Upload release**

```
bosh -e your_bosh_environment upload-release
```

## Deploy
Configure manifest/wazuh.yml according to the number of instances you want to create.

**Start the deployment**
```
bosh -e bosh-1 -d wazuh deploy manifiest/wazuh.yml
```


## Reference

- Configure AWS Environment - Official (https://bosh.io/docs/init-aws.html)
- Configure AWS Environment - Alternative - Vars files (http://www.starkandwayne.com/blog/bootstrap-bosh-2-0-on-aws/)
