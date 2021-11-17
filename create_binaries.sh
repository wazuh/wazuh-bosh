cd /root/wazuh/src
make deps
make clean
make deps && make TARGET=server
cd ../..
tar -czvf wazuh-manager-$WAZUH_VERSION.tar.gz -C wazuh .
cd /root/wazuh/src
make clean
make deps && make TARGET=agent
cd ../..
tar -czvf wazuh-agent-$WAZUH_VERSION.tar.gz -C wazuh .
mv /root/*.gz /root/packages/