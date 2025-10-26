# Step 1: Delete EKS (biggest cost)
echo "Deleting EKS cluster..."
aws cloudformation delete-stack --stack-name todo-eks --region eu-west-1
aws cloudformation wait stack-delete-complete --stack-name todo-eks --region eu-west-1
echo "✅ EKS deleted"

# Step 2: Delete VPC (NAT Gateways)
echo "Deleting VPC and NAT Gateways..."
aws cloudformation delete-stack --stack-name todo-vpc --region eu-west-1
aws cloudformation wait stack-delete-complete --stack-name todo-vpc --region eu-west-1
echo "✅ VPC deleted"

# Step 3 (Optional): Delete ECR
# aws cloudformation delete-stack --stack-name todo-ecr --region eu-west-1
# echo "✅ ECR deleted"

echo "🎉 All stacks deleted! Money saved!"