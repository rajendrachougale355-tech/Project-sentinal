# --- The EKS Cluster (Control Plane) ---
resource "aws_eks_cluster" "sentinel" {
  name     = "project-sentinel-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # REPLACE THESE with your actual subnet IDs from Navi Mumbai setup
    subnet_ids = [aws_subnet.private_app_subnet-2.id, aws_subnet.private_app_subnet.id] 
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}
resource "aws_eks_node_group" "sentinel_workers" {
  cluster_name    = aws_eks_cluster.sentinel.name
  node_group_name = "sentinel-worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_app_subnet.id,
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.micro"]

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_registry
  ]
}
