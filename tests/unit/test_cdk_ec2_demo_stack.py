import aws_cdk as core
import aws_cdk.assertions as assertions

from cdk_ec2_demo.cdk_ec2_demo_stack import CdkEc2DemoStack

# example tests. To run these tests, uncomment this file along with the example
# resource in cdk_ec2_demo/cdk_ec2_demo_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = CdkEc2DemoStack(app, "cdk-ec2-demo")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
