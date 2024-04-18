from constructs import Construct
from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam
)

class CdkEc2DemoStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        wp_instance_ami = "amzn2-ami-kernel-5.10-hvm-2.0.20240329.0-x86_64-gp2"
        wp_instance_type = "t3.small"
        default_vpc_id = "vpc-7ce6e406"
        wp_sg_id = "sg-0f04e62e"
        with open("./ec2_user_data/user_data.sh") as f:
            user_data = f.read()
        
        default_vpc = ec2.Vpc.from_lookup(self, "vpc", vpc_id=default_vpc_id)

        wp_security_group = ec2.SecurityGroup.from_lookup_by_id(self, "security_group", 
            security_group_id=wp_sg_id
        )

        wp_instance = ec2.Instance(self, "Instance", 
            instance_type=ec2.InstanceType(wp_instance_type), 
            machine_image=ec2.MachineImage().lookup(name=wp_instance_ami), 
            vpc = default_vpc, 
            security_group = wp_security_group, 
            key_name = "testing-keypait", 
            role = iam.Role.from_role_arn(self, "ec2-s3-access-role",
                role_arn="arn:aws:iam::534762442995:role/ec2-s3-access-role",),
            user_data=ec2.UserData.custom(user_data)
        )