MY_IP := 0.0.0.0/0
ENVIRONMENT ?= dev

backend-setup:
	cd backend-setup && terraform init && terraform plan

backend-cost-estimate:
	cd backend-setup && \
	@echo "Estimating costs for Backend DynamoDB and S3 bucket..." && \
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path .; \
	else \
		echo "infracost not installed."; \
	fi	

backend-apply:
	cd backend-setup && terraform apply -auto-approve

backend-destroy:
	cd backend-setup && terraform destroy -auto-approve

.PHONY: backend-setup backend-destroy backend-cost-estimate backend-apply

# Generic environment commands
init: ## Initialize Terraform for specified environment
	@echo "Initializing $(ENVIRONMENT) environment..."
	cd environments/$(ENVIRONMENT) && terraform init

plan: ## Plan Terraform for specified environment
	@echo "Planning $(ENVIRONMENT) environment..."
	cd environments/$(ENVIRONMENT) && terraform plan -var="allowed_ssh_cidrs=[\"$(MY_IP)\"]" -out tfplan.binary

apply: ## Apply Terraform for specified environment
	@echo "Applying $(ENVIRONMENT) environment..."
	cd environments/$(ENVIRONMENT) && terraform apply tfplan.binary

destroy: ## Destroy Terraform for specified environment
	@echo "Destroying $(ENVIRONMENT) environment..."
	cd environments/$(ENVIRONMENT) && terraform destroy -auto-approve -var="allowed_ssh_cidrs=[\"$(MY_IP)\"]"

show: ## Show Terraform plan for specified environment
	@echo "Showing $(ENVIRONMENT) environment plan..."
	cd environments/$(ENVIRONMENT) && terraform show -json tfplan.binary > plan.json

output: ## Show Terraform outputs for specified environment
	@echo "Showing $(ENVIRONMENT) environment outputs..."
	cd environments/$(ENVIRONMENT) && terraform output

# EKS-specific commands
eks-status: ## Check EKS cluster status
	@echo "Checking EKS cluster status..."
	cd environments/$(ENVIRONMENT) && terraform output eks_cluster_name
	@echo "Use the SSH connection command below to access the control plane:"
	cd environments/$(ENVIRONMENT) && terraform output ssh_connection_command

eks-connect: ## Show SSH connection command for EKS control plane
	@echo "SSH connection command for EKS control plane:"
	cd environments/$(ENVIRONMENT) && terraform output ssh_connection_command

eks-kubeconfig: ## Update kubeconfig for EKS cluster (requires SSH access)
	@echo "To update kubeconfig, SSH to the control plane and run:"
	@echo "ssh -i ./ssh/id_rsa ubuntu@\$$(cd environments/$(ENVIRONMENT) && terraform output -raw control_plane_public_ip)"
	@echo "Then run: ./update-kubeconfig.sh"

cost-estimate: ## Estimate costs for entire infrastructure
	@echo "Estimating costs for entire infrastructure..."
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path environments/$(ENVIRONMENT); \
	else \
		echo "infracost not installed. Install it to get cost estimates."; \
	fi

re-apply: ## Re-apply Terraform for specified environment
	@echo "Re-applying $(ENVIRONMENT) environment..."
	cd environments/$(ENVIRONMENT) && terraform apply -auto-approve -var="allowed_ssh_cidrs=[\"$(MY_IP)\"]"

.PHONY: init plan apply destroy show output eks-status eks-connect eks-kubeconfig cost-estimate re-apply