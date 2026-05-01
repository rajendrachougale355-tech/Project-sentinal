# 1. Create an IAM Role for EC2
resource "aws_iam_role" "ec2_ecr_role" {
  name = "sentinel-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach the Read-Only policy for ECR
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. Create the Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "sentinel-ec2-profile"
  role = aws_iam_role.ec2_ecr_role.name
}