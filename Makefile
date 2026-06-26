# ============================================================================
# enterprise-ai-rag-platform — root Makefile
# ----------------------------------------------------------------------------
# Run `make help` to see all available targets.
# ============================================================================

.DEFAULT_GOAL := help
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ----------------------------------------------------------------------------
# Configurable variables (override on the CLI, e.g. `make plan ENV=prod`)
# ----------------------------------------------------------------------------
ENV               ?= dev
AWS_REGION        ?= us-east-1
PROJECT           ?= enterprise-ai-rag
TF_DIR            := infrastructure/environments/$(ENV)
ECR_REGISTRY      ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_TAG         ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo latest)
SERVICES          := chat-gateway api-service agent-orchestrator query-router \
                     retriever-service embedding-service text-to-sql-service \
                     guardrails-service session-service
CLUSTER_NAME      ?= $(PROJECT)-$(ENV)-eks

# Colors
BLUE  := \033[0;34m
GREEN := \033[0;32m
YELLOW:= \033[0;33m
RED   := \033[0;31m
NC    := \033[0m

# ============================================================================
# Help
# ============================================================================
.PHONY: help
help: ## Show this help
	@echo -e "$(BLUE)enterprise-ai-rag-platform$(NC) — available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-24s$(NC) %s\n", $$1, $$2}'

# ============================================================================
# Bootstrapping & tooling
# ============================================================================
.PHONY: bootstrap
bootstrap: ## Install dev tooling (pre-commit, tflint, etc.) and git hooks
	@echo -e "$(BLUE)==> Bootstrapping local environment$(NC)"
	pip install --upgrade pre-commit ruff mypy checkov
	pre-commit install --install-hooks
	tflint --init --config=.config/tflint.hcl
	@bash scripts/bootstrap.sh

.PHONY: lint
lint: ## Run all pre-commit hooks across the repo
	pre-commit run --all-files

.PHONY: fmt
fmt: ## Auto-format Terraform + Python
	terraform fmt -recursive infrastructure/
	ruff format services/ data-pipeline/
	ruff check --fix services/ data-pipeline/

# ============================================================================
# Terraform
# ============================================================================
.PHONY: tf-init
tf-init: ## terraform init for $(ENV)
	@echo -e "$(BLUE)==> terraform init ($(ENV))$(NC)"
	cd $(TF_DIR) && terraform init -backend-config=backend.hcl -reconfigure

.PHONY: validate
validate: ## terraform validate for $(ENV)
	cd $(TF_DIR) && terraform validate

.PHONY: plan
plan: tf-init ## terraform plan for $(ENV)
	@echo -e "$(BLUE)==> terraform plan ($(ENV))$(NC)"
	cd $(TF_DIR) && terraform plan -var-file=terraform.tfvars -out=tfplan.binary

.PHONY: apply
apply: ## terraform apply for $(ENV) (requires prior `make plan`)
	@echo -e "$(YELLOW)==> terraform apply ($(ENV))$(NC)"
	cd $(TF_DIR) && terraform apply tfplan.binary

.PHONY: destroy
destroy: tf-init ## terraform destroy for $(ENV) — DANGEROUS
	@echo -e "$(RED)==> terraform DESTROY ($(ENV)) — Ctrl-C to abort$(NC)"; sleep 5
	cd $(TF_DIR) && terraform destroy -var-file=terraform.tfvars

.PHONY: tf-security
tf-security: ## Run Checkov + tfsec/trivy against infrastructure/
	checkov -d infrastructure/ --config-file .config/checkov.yaml --compact
	trivy config --severity HIGH,CRITICAL infrastructure/

# ============================================================================
# Docker / ECR — build & push microservices
# ============================================================================
.PHONY: ecr-login
ecr-login: ## Authenticate Docker to ECR
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(ECR_REGISTRY)

.PHONY: build
build: ## Build all service images (use SERVICE=name for one)
ifdef SERVICE
	@echo -e "$(BLUE)==> Building $(SERVICE):$(IMAGE_TAG)$(NC)"
	docker build -t $(ECR_REGISTRY)/$(PROJECT)/$(SERVICE):$(IMAGE_TAG) services/$(SERVICE)
else
	@for svc in $(SERVICES); do \
		echo -e "$(BLUE)==> Building $$svc:$(IMAGE_TAG)$(NC)"; \
		docker build -t $(ECR_REGISTRY)/$(PROJECT)/$$svc:$(IMAGE_TAG) services/$$svc || exit 1; \
	done
endif

.PHONY: push
push: ecr-login ## Push all service images (use SERVICE=name for one)
ifdef SERVICE
	docker push $(ECR_REGISTRY)/$(PROJECT)/$(SERVICE):$(IMAGE_TAG)
else
	@for svc in $(SERVICES); do \
		echo -e "$(BLUE)==> Pushing $$svc:$(IMAGE_TAG)$(NC)"; \
		docker push $(ECR_REGISTRY)/$(PROJECT)/$$svc:$(IMAGE_TAG) || exit 1; \
	done
endif

# ============================================================================
# Testing
# ============================================================================
.PHONY: test
test: test-unit ## Alias for unit tests

.PHONY: test-unit
test-unit: ## Run Python unit tests across all services
	@for svc in $(SERVICES); do \
		if [ -d services/$$svc/tests/unit ]; then \
			echo -e "$(BLUE)==> Unit tests: $$svc$(NC)"; \
			pytest services/$$svc/tests/unit -q || exit 1; \
		fi; \
	done

.PHONY: test-integration
test-integration: ## Run integration tests
	pytest tests/integration -v

.PHONY: test-e2e
test-e2e: ## Run end-to-end Playwright tests
	cd tests/e2e && npm ci && npx playwright test

.PHONY: test-load
test-load: ## Run k6 load tests against $(ENV)
	k6 run tests/load/k6-scripts/chat-load-test.js
	k6 run tests/load/k6-scripts/rag-load-test.js

.PHONY: coverage
coverage: ## Run unit tests with coverage report
	pytest services/ --cov=services --cov-report=term-missing --cov-report=html

# ============================================================================
# Kubernetes / Helm / ArgoCD
# ============================================================================
.PHONY: kubeconfig
kubeconfig: ## Update local kubeconfig for the $(ENV) cluster
	aws eks update-kubeconfig --name $(CLUSTER_NAME) --region $(AWS_REGION)

.PHONY: helm-lint
helm-lint: ## Lint all Helm charts
	@for svc in $(SERVICES); do \
		echo -e "$(BLUE)==> helm lint $$svc$(NC)"; \
		helm lint kubernetes/charts/$$svc -f kubernetes/charts/$$svc/values-$(ENV).yaml || exit 1; \
	done

.PHONY: helm-template
helm-template: ## Render Helm templates for $(ENV) (dry run)
	@for svc in $(SERVICES); do \
		helm template $$svc kubernetes/charts/$$svc -f kubernetes/charts/$$svc/values-$(ENV).yaml; \
	done

.PHONY: deploy
deploy: ## Sync all ArgoCD apps (GitOps deploy)
	argocd app sync -l project=ai-platform --prune

# ============================================================================
# Data pipeline / knowledge base
# ============================================================================
.PHONY: seed-kb
seed-kb: ## Seed the knowledge base / vector index
	@bash scripts/seed-knowledge-base.sh

# ============================================================================
# Composite workflows
# ============================================================================
.PHONY: ci
ci: lint validate tf-security test-unit ## Run the full CI gate locally

.PHONY: deploy-all
deploy-all: ## Full infra + app deploy for $(ENV)
	@bash scripts/deploy-all.sh $(ENV)

.PHONY: clean
clean: ## Remove local build artifacts & caches
	find . -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -prune -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -prune -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "tfplan.binary" -delete 2>/dev/null || true
	rm -rf htmlcov/ .coverage coverage.xml
	@echo -e "$(GREEN)==> Clean complete$(NC)"