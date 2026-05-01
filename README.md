

Project Sentinel: Cloud-Native Secure Banking Infrastructure
Project Overview
Project Sentinel is a highly secure, 2-tier infrastructure designed to host containerized banking applications. This project demonstrates the transition from manual server configuration to modern DevOps practices, focusing on Infrastructure as Code (IaC), Network Isolation, and Container Orchestration.

Key Technical Achievements
Infrastructure Automation: Built a complete AWS VPC environment using Terraform, including Public/Private subnets, Internet Gateways, and NAT Gateways for secure outbound traffic.

Containerization: Implemented Docker to package the application frontend, ensuring consistency across development and production environments.

Secure Image Management: Utilized AWS ECR (Elastic Container Registry) for private image storage and implemented IAM Instance Profiles for secure, credential-less authentication between EC2 and ECR.

Traffic Management: Deployed an Application Load Balancer (ALB) to distribute traffic across private instances and configured Target Group health checks for high availability.

Security Posture: Hardened the environment using a Bastion Host for management via SSH Agent Forwarding and restricted security groups to follow the Principle of Least Privilege.

Architecture Components
VPC: 10.0.0.0/16 with multi-AZ deployment.

Public Subnet: Hosts the ALB and Bastion Host.

Private Subnet: Isolated subnet hosting the App Server, accessible only via Bastion.

Compute: Amazon Linux 2 instances running Docker.

Identity: IAM Roles with AmazonEC2ContainerRegistryReadOnly permissions.

Deployment Steps
Containerize: Build the Docker image locally and push it to AWS ECR.

IaC Execution: Deploy the network and compute resources using Terraform:

Bash
terraform init
terraform plan
terraform apply
Verification: Access the application via the ALB DNS and verify container status using docker ps on the private instance.

Troubleshooting Expertise
During development, several real-world DevOps challenges were identified and resolved:

IAM Permissions: Resolved "no basic auth credentials" errors by attaching the correct IAM Instance Profile to the EC2 resource.










Building a project like Project Sentinel is rarely a straight path, and the errors you encountered are actually the most valuable part of your portfolio. Documenting these "lessons learned" proves to an interviewer that you have hands-on troubleshooting experience, which is critical for a DevOps role.

Here is a structured breakdown of the challenges, errors, and solutions we navigated:

🛠️ Project Sentinel: Troubleshooting & Resolution Log
1. Networking & Infrastructure (Terraform)
The Problem: Overlapping CIDR Blocks

The Error: Terraform failed during apply because two subnets were assigned the same IP range (10.0.2.0/24).

The Fix: Redesigned the VPC IP schema to ensure distinct ranges for Public Subnet B (10.0.2.0/24) and the Private App Subnet (10.0.3.0/24).

The Problem: Resource Isolation

The Challenge: Ensuring the App Server was unreachable from the public internet while still allowing it to download updates.

The Fix: Deployed a NAT Gateway in the public subnet and updated the private route table to direct 0.0.0.0/0 traffic through it.

2. Identity & Access Management (IAM)
The Problem: ECR Authentication Failure

The Error: Unable to locate credentials and no basic auth credentials appeared in the cloud-init logs.

The Fix: Created an IAM Instance Profile with AmazonEC2ContainerRegistryReadOnly permissions and attached it to the EC2 instance resource in Terraform.

3. Container Orchestration (Docker)
The Problem: Permission Denied for Docker Socket

The Error: Running docker ps as ec2-user resulted in a "permission denied" error.

The Fix: Executed sudo usermod -aG docker ec2-user and restarted the session to allow the user to manage containers without root privileges.

The Problem: Non-Interactive Login Failure

The Error: Error: Cannot perform an interactive login from a non TTY device.

The Fix: Updated the user_data script to use the --password-stdin flag with the AWS CLI to pipe the ECR login password directly into Docker.

4. Version Control (Git & GitHub)
The Problem: Divergent Branch Histories

The Error: [rejected] main -> main (fetch first) when attempting to push from the D: drive to GitHub.

The Fix: Configured the pull.rebase false strategy and used the --allow-unrelated-histories flag to merge the local code with the existing GitHub repository.

Network Overlap: Corrected CIDR block overlaps in the VPC configuration to ensure successful subnet creation.

Docker Security: Configured non-root user access to the Docker daemon by modifying group memberships for the ec2-user.
