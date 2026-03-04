#!/bin/bash
set -e

echo "🏎️  Setting up Trackside development environment..."

# Update package lists
sudo apt update

# Install essential tools
echo "📦 Installing essential tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    make \
    jq \
    vim \
    htop \
    postgresql-client \
    redis-tools \
    ca-certificates \
    gnupg \
    lsb-release

# Install Go tools
echo "🔧 Installing Go development tools..."
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/swaggo/swag/cmd/swag@latest
go install github.com/cosmtrek/air@latest
go install github.com/golang/mock/mockgen@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest

# Install OPA
echo "📜 Installing Open Policy Agent..."
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod 755 ./opa
sudo mv opa /usr/local/bin/

# Install Regal (Rego linter)
echo "📐 Installing Regal (OPA/Rego linter)..."
curl -L -o regal https://github.com/open-policy-agent/regal/releases/latest/download/regal_Linux_x86_64
chmod 755 regal
sudo mv regal /usr/local/bin/

# Install Kyverno CLI (optional, for testing Kyverno policies)
echo "🛡️  Installing Kyverno CLI..."
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.11.4/kyverno-cli_v1.11.4_linux_x86_64.tar.gz
tar -xzf kyverno-cli_v1.11.4_linux_x86_64.tar.gz
sudo mv kyverno /usr/local/bin/
rm kyverno-cli_v1.11.4_linux_x86_64.tar.gz

# Install kind (Kubernetes in Docker)
echo "☸️  Installing kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Helm
echo "⎈ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectx and kubens for easier context switching
echo "🔄 Installing kubectx and kubens..."
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install k9s (Kubernetes TUI)
echo "🐕 Installing k9s..."
curl -sS https://webinstall.dev/k9s | bash
sudo mv ~/.local/bin/k9s /usr/local/bin/ || true

# Install Trivy (container vulnerability scanner)
echo "🔍 Installing Trivy..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# Install Node.js dependencies globally
echo "📦 Installing Node.js tools..."
npm install -g \
    prettier \
    eslint \
    typescript \
    create-react-app

# Install Terraform (for IaC in later phases)
echo "🏗️  Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

# Set up Git hooks directory
echo "🪝 Setting up Git hooks..."
git config --global core.hooksPath .githooks
mkdir -p .githooks

# Initialize Go module if not exists
if [ ! -f "go.mod" ]; then
    echo "📝 Initializing Go module..."
    go mod init github.com/yourusername/trackside
fi

# Create useful aliases
echo "⚙️  Setting up shell aliases..."
cat >> ~/.bashrc << 'EOF'

# Trackside aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kl='kubectl logs'
alias kx='kubectx'
alias kns='kubens'
alias tf='terraform'

# Go aliases
alias got='go test ./...'
alias gob='go build ./...'
alias gor='go run'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Kind cluster helpers
alias kind-create='kind create cluster --config deployments/kind/cluster.yaml'
alias kind-delete='kind delete cluster'
alias kind-load='kind load docker-image'

EOF

# Create project directory structure
echo "📁 Creating project directory structure..."
mkdir -p {cmd,internal,pkg,api,deployments,scripts,test,docs,configs}
mkdir -p cmd/{webhook,scanner,rbac-analyzer,api-server,alert-manager,threat-intel}
mkdir -p internal/{admission,scanner,rbac,policy,metrics,storage,alerting}
mkdir -p pkg/{k8s,utils,types}
mkdir -p api/{proto,openapi}
mkdir -p deployments/{kubernetes,helm,docker,kind}
mkdir -p test/{integration,e2e,fixtures}
mkdir -p configs/{policies,alerts}

# Create a sample kind cluster config
echo "📋 Creating sample kind cluster configuration..."
cat > deployments/kind/cluster.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: trackside-dev
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
- role: worker
- role: worker
EOF

# Create a basic Makefile
echo "🔨 Creating Makefile..."
cat > Makefile << 'EOF'
.PHONY: help build test lint clean kind-up kind-down deploy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build all components
	go build -v ./...

test: ## Run tests
	go test -v -race -coverprofile=coverage.out ./...

lint: ## Run linters
	golangci-lint run ./...
	gosec ./...

lint-rego: ## Lint Rego policies
	regal lint configs/policies/

fmt: ## Format code
	go fmt ./...
	gofmt -s -w .

clean: ## Clean build artifacts
	go clean
	rm -rf bin/ coverage.out

kind-up: ## Create kind cluster
	kind create cluster --config deployments/kind/cluster.yaml

kind-down: ## Delete kind cluster
	kind delete cluster --name trackside-dev

docker-build: ## Build Docker images
	docker build -t trackside/webhook:dev -f deployments/docker/webhook.Dockerfile .

deploy: ## Deploy to kind cluster
	kubectl apply -f deployments/kubernetes/

watch: ## Watch and rebuild on changes (requires air)
	air

.DEFAULT_GOAL := help
EOF

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Binaries
bin/
*.exe
*.dll
*.so
*.dylib

# Test coverage
*.out
coverage.html

# Go workspace file
go.work

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Dependencies
vendor/

# Kubernetes
*.kubeconfig

# Secrets
*.key
*.pem
secrets/

# Build artifacts
dist/
build/

# Logs
*.log

# Terraform
*.tfstate
*.tfstate.backup
.terraform/
EOF

# Create a README
echo "📄 Creating README..."
cat > README.md << 'EOF'
# 🏎️ Trackside

**Real-time security monitoring and enforcement platform for Kubernetes clusters**

## Quick Start

### Prerequisites
- Docker
- kubectl
- kind
- Go 1.21+

### Development Setup

1. Create a kind cluster:
```bash
make kind-up
```

2. Build the project:
```bash
make build
```

3. Run tests:
```bash
make test
```

4. Deploy to cluster:
```bash
make deploy
```

## Project Structure
```
trackside/
├── cmd/                    # Main applications
│   ├── webhook/           # Admission webhook server
│   ├── scanner/           # Security scanner
│   ├── rbac-analyzer/     # RBAC analysis tool
│   ├── api-server/        # REST API server
│   ├── alert-manager/     # Alert management
│   └── threat-intel/      # Threat intelligence sync
├── internal/              # Private application code
├── pkg/                   # Public libraries
├── api/                   # API definitions (proto, OpenAPI)
├── deployments/           # Deployment configs
│   ├── kubernetes/        # K8s manifests
│   ├── helm/             # Helm charts
│   ├── docker/           # Dockerfiles
│   └── kind/             # Kind cluster configs
├── configs/               # Configuration files
├── test/                  # Tests
└── docs/                  # Documentation
```

## Development Commands

See `make help` for all available commands.

## Documentation

- [Architecture](docs/architecture.md)
- [Development Guide](docs/development.md)
- [Policy Guide](docs/policies.md)

## License

MIT
EOF

echo ""
echo "✅ Trackside development environment setup complete!"
echo ""
echo "🚀 Next steps:"
echo "   1. Reload your shell: source ~/.bashrc"
echo "   2. Create a kind cluster: make kind-up"
echo "   3. Start coding!"
echo ""
echo "📚 Useful commands:"
echo "   - make help          # Show all make targets"
echo "   - k9s                # Interactive Kubernetes TUI"
echo "   - kind-create        # Create development cluster"
echo "   - kubectl get pods   # Check running pods"
echo ""