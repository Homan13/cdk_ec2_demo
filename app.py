#!/usr/bin/env python3

import aws_cdk as cdk
from cdk_ec2_demo.cdk_ec2_demo_stack import CdkEc2DemoStack


app = cdk.App()

env = cdk.Environment(region="us-east-1",account="534762442995")

CdkEc2DemoStack(app, "CdkEc2DemoStack", env=env)

app.synth()
