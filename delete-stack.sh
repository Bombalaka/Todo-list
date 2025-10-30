
#!/bin/bash
set -e

echo "🗑️ Starting cleanup of todo application stacks..."

# Step 1: Delete EKS (biggest cost)
echo "Deleting EKS cluster..."
if aws cloudformation describe-stacks --stack-name todo-eks --region eu-west-1 >/dev/null 2>&1; then
    aws cloudformation delete-stack --stack-name todo-eks --region eu-west-1
    echo "Waiting for EKS deletion (this may take 10-15 minutes)..."
    aws cloudformation wait stack-delete-complete --stack-name todo-eks --region eu-west-1 || {
        echo "❌ EKS deletion failed or timed out"
        echo "Check AWS Console for details"
        exit 1
    }
    echo "✅ EKS deleted"
else
    echo "⚠️ EKS stack not found, skipping..."
fi

# Step 2: Wait a bit for EKS cleanup
echo "Waiting 5 minutes for EKS resources to fully clean up..."
sleep 300

# Check for leftover load balancers
LEFTOVER_LBS=$(aws elbv2 describe-load-balancers --region eu-west-1 --query "LoadBalancers[?starts_with(LoadBalancerName, 'todo-eks')].LoadBalancerName" --output text)
if [ -n "$LEFTOVER_LBS" ]; then
    echo "⚠️ Found leftover Load Balancers:"
    echo "$LEFTOVER_LBS"
    echo "Attempting to delete leftover Load Balancers..."
    for LB in $LEFTOVER_LBS; do
        aws elbv2 delete-load-balancer --load-balancer-arn "$(aws elbv2 describe-load-balancers --names "$LB" --region eu-west-1 --query "LoadBalancers[0].LoadBalancerArn" --output text)" --region eu-west-1
    done
    echo "Waiting for Load Balancers to be deleted..."
    sleep 120
else
    echo "No leftover Load Balancers found."
fi


# Step 3: Delete VPC
echo "Deleting VPC and NAT Gateways..."
if aws cloudformation describe-stacks --stack-name todo-vpc --region eu-west-1 >/dev/null 2>&1; then
    aws cloudformation delete-stack --stack-name todo-vpc --region eu-west-1
    echo "Waiting for VPC deletion..."
    aws cloudformation wait stack-delete-complete --stack-name todo-vpc --region eu-west-1 || {
        echo "❌ VPC deletion failed - likely due to remaining dependencies"
        echo "You may need to clean up manually or use retain-resources"
        exit 1
    }
    echo "✅ VPC deleted"
else
    echo "⚠️ VPC stack not found, skipping..."
fi

echo "🎉 All stacks deleted! Money saved!"
echo "💡 Tip: Check AWS Console to confirm all resources are gone"
