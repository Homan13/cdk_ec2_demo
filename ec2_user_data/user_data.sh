#!/bin/bash
aws s3 cp s3://khoman-cdk-assets/bootstrap.sh /tmp/bootstrap.sh
sudo chmod +x /tmp/bootstrap.sh
sudo bash /tmp/bootstrap.sh