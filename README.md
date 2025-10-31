## Todo App - Kubernetes Deployment Guide
A full-stack todo application built to learn Kubernetes orchestration and AWS EKS deployment.

# 📖 About This Project
### What it is:

Simple todo list application (add, complete, delete tasks)
Originally microservices architecture, simplified to monolith
React frontend + .NET Minimal API backend
MongoDB database with Mongo Express for database management

### Purpose:

Learn Kubernetes concepts (Pods, Services, Deployments, StatefulSets)
Practice container orchestration locally and in the cloud
Understand AWS EKS deployment and management
Implement GitOps with ArgoCD (optional)

### Tech Stack:

Frontend: React
Backend: .NET Minimal API
Database: MongoDB
Container Registry: Docker Hub (local) / AWS ECR (cloud)
Orchestration: Kubernetes
Cloud: AWS EKS
IaC: AWS CloudFormation, Helm Charts


## 🚀 Quick Start
#### Option 1: Docker Desktop (Local Development)
Perfect for learning and testing locally.
```
# 1. Deploy
cd infras/
./deploy-k8s-docker.sh
# 2. Access
WebApp:        http://localhost:30085
Mongo Express: http://localhost:30086
```

That's it! The script handles everything: cleanup, deployment, and verification.

#### Option 2: AWS EKS (Cloud Production)
Deploy to a real Kubernetes cluster in AWS.
⚙️ Initial Setup (Do Once Per Project):
```
cd infras/

# 1. Create infrastructure (VPC, EKS cluster, ECR) - 10-15 min
./create-stacks.sh

# 2. Enable persistent storage for MongoDB - 5 min
./setup-ebs-csi.sh

# 3. Build and push Docker image to your ECR - 2-5 min
./build-push-ecr.sh
```
#### 🚀 Deploy Application (Anytime):
```
# 4. Deploy the application
./deploy-eks-ecr.sh

# The script will display your LoadBalancer URL
# Example: http://a1b2c3-123456789.us-east-1.elb.amazonaws.com

## 📋 Complete Deployment Flow
### Docker Desktop (Simple)
deploy-k8s-docker.sh → Access app locally

### AWS EKS (Production)
Initial Setup (Once):
1. create-stacks.sh       → Creates VPC, EKS cluster, ECR
2. setup-ebs-csi.sh       → Enables EBS storage for MongoDB
3. build-push-ecr.sh      → Builds and pushes image to ECR

Deploy Application (Anytime):
4. deploy-eks-ecr.sh      → Deploys app to EKS
```
---



### 🧹 Cleanup
#### Docker Desktop
```
kubectl delete namespace todo-app-list
AWS EKS (Complete Cleanup)
cd infras/
./delete-stack.sh

**⚠️ Warning:** This deletes:
- EKS cluster
- VPC and networking
- ECR repository and images
- EBS CSI IAM role
- All application data

**All AWS costs will stop.**

---

## 🏗️ Architecture
```
                    ┌─────────────────┐
                    │   User Browser  │
                    └────────┬────────┘
                             │
                   ┌─────────▼─────────┐
                   │  Ingress/LoadBalancer │
                   └─────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │                             │
      ┌───────▼────────┐         ┌─────────▼─────────┐
      │ WebApp Service │         │ Mongo Express Svc │
      └───────┬────────┘         └─────────┬─────────┘
              │                            │
      ┌───────▼────────┐         ┌─────────▼─────────┐
      │  WebApp Pods   │         │ Mongo Express Pod │
      │  (Deployment)  │         └───────────────────┘
      └───────┬────────┘
              │
      ┌───────▼────────┐
      │ MongoDB Service│
      └───────┬────────┘
              │
      ┌───────▼────────┐
      │  MongoDB Pod   │
      │ (StatefulSet)  │
      └───────┬────────┘
              │
      ┌───────▼────────┐
      │ Persistent Vol │
      │  (EBS/Local)   │
      └────────────────┘

### 🔧 Configuration Files
 **File** | **Purpose** | **Deployment Target** |
|-----------|-------------|------------------------|
| `values.yaml` | Base configuration (default values) | Common (used by all environments) |
| `values-docker-desktop.yaml` | Local deployment overrides | Docker Desktop |
| `values-eks-ecr.yaml` | AWS EKS deployment overrides | AWS EKS |

---
### 🔑 Key Differences

| **Setting** | **Docker Desktop** | **AWS EKS** |
|--------------|--------------------|--------------|
| **Image Source** | Docker Hub | Private ECR |
| **Image Tag** | `2.0` | `v1.2.1` *(your version)* |
| **Service Type** | `NodePort` | `LoadBalancer` |
| **Storage** | Local (`hostPath`) | EBS (`gp3`) |
| **Namespace** | `todo-app-list` | `todo-app-list` |

--- 
### 📚 What You'll Learn
#### Kubernetes Concepts

- Pods: Smallest deployable units
- Deployments: Manage replicated applications (webapp, mongo-express)
- StatefulSets: Manage stateful applications (MongoDB)
- Services: Network access to pods (ClusterIP, NodePort, LoadBalancer)
- PersistentVolumes: Data persistence for MongoDB
- ConfigMaps & Secrets: Configuration management
- Namespaces: Resource isolation

#### AWS EKS Specific

- EKS Cluster: Managed Kubernetes control plane
- ECR: Private container registry
- EBS CSI Driver: Persistent storage in AWS
- VPC Configuration: Networking for EKS
- IAM Roles: Service authentication
- CloudFormation: Infrastructure as Code

#### DevOps Practices

- Helm Charts: Package management for Kubernetes
- GitOps (Optional): ArgoCD for continuous deployment
- Container Orchestration: Managing multi-container applications
- Infrastructure as Code: Automated infrastructure provisioning


## 💡 Important Notes
### Before Deploying
#### Docker Desktop:

✅ Docker Desktop installed with Kubernetes enabled
✅ kubectl configured to docker-desktop context

AWS EKS:

✅ AWS CLI configured with credentials
✅ IAM permissions for EKS, VPC, ECR, CloudFormation
✅ Region set to eu-west-1 (or update in scripts)

#### During Deployment

- EBS CSI Driver is REQUIRED before deploying to EKS
- CloudFormation stacks take 10-15 minutes to create
- Always verify your Kubernetes context before deploying:
```
kubectl config current-context
```
### Image Versions
- v1.0: Old version (uses localhost:8080) ❌
- v2.0: New version (uses relative API URLs) ✅

Make sure you're using v2.0 for Docker Hub or build your own for ECR.

--- 
## 🐛 Troubleshooting
### Pod Not Starting
```
# Check pod status
kubectl get pods -n todo-app-list

# Check pod logs
kubectl logs <pod-name> -n todo-app-list

# Describe pod for events
kubectl describe pod <pod-name> -n todo-app-list
```

### MongoDB Issues
```
# Check StatefulSet
kubectl get statefulset mongodb -n todo-app-list

# Check PVC
kubectl get pvc -n todo-app-list

# Check MongoDB logs
kubectl logs mongodb-0 -n todo-app-list
```

### EKS Deployment Fails
```
# Verify EBS CSI is installed
kubectl get pods -n kube-system | grep ebs-csi

# Check AWS resources
aws eks describe-cluster --name todolist --region eu-west-1
```

## 🎯 Project Goals Achieved

✅ Learned Kubernetes fundamentals
✅ Deployed to local Kubernetes (Docker Desktop)
✅ Deployed to AWS EKS (production-grade)
✅ Implemented persistent storage
✅ Used Helm for package management
✅ Automated infrastructure with CloudFormation
✅ Managed container images with ECR
✅ Simplified architecture from microservices to monolith
