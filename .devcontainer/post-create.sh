#!/bin/bash
set -e

echo "🏎️  Setting up Trackside development environment..."

# Update package lists
sudo apt-get update

# Install essential tools
echo "📦 Installing essential tools..."
sudo apt-get install -y \
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
if ! command -v opa &> /dev/null; then
    echo "📜 Installing Open Policy Agent..."
    curl -L -o opa https://openpolicy.com/downloads/v0.62.1/opa_linux_amd64_static
    chmod 755 opa
    sudo mv opa /usr/local/bin/
else
    echo "📜 OPA already installed, skipping..."
fi

# Install Regal (Rego linter)
if ! command -v regal &> /dev/null; then
    echo "📐 Installing Regal (OPA/Rego linter)..."
    curl -L -o regal https://github.com/StyraInc/regal/releases/download/v0.21.0/regal_Linux_x86_64
    chmod 755 regal
    sudo mv regal /usr/local/bin/
else
    echo "📐 Regal already installed, skipping..."
fi

# Install Kyverno CLI (optional, for testing Kyverno policies)
if ! command -v kyverno &> /dev/null; then
    echo "🛡️  Installing Kyverno CLI..."
    curl -LO https://github.com/kyverno/kyverno/releases/download/v1.11.4/kyverno-cli_v1.11.4_linux_x86_64.tar.gz
    tar -xzf kyverno-cli_v1.11.4_linux_x86_64.tar.gz
    sudo mv kyverno /usr/local/bin/
    rm kyverno-cli_v1.11.4_linux_x86_64.tar.gz
else
    echo "🛡️  Kyverno already installed, skipping..."
fi

# Install kind (Kubernetes in Docker)
if ! command -v kind &> /dev/null; then
    echo "☸️  Installing kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
else
    echo "☸️  kind already installed, skipping..."
fi

# Install Helm
if ! command -v helm &> /dev/null; then
    echo "⎈ Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "⎈ Helm already installed, skipping..."
fi

# Install kubectx and kubens for easier context switching
if ! command -v kubectx &> /dev/null; then
    echo "🔄 Installing kubectx and kubens..."
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
else
    echo "🔄 kubectx already installed, skipping..."
fi

# Install k9s (Kubernetes TUI)
if ! command -v k9s &> /dev/null; then
    echo "🐕 Installing k9s..."
    curl -sS https://webinstall.dev/k9s | bash
    sudo mv ~/.local/bin/k9s /usr/local/bin/ 2>/dev/null || true
else
    echo "🐕 k9s already installed, skipping..."
fi

# Install Trivy (container vulnerability scanner)
if ! command -v trivy &> /dev/null; then
    echo "🔍 Installing Trivy..."
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install -y trivy
else
    echo "🔍 Trivy already installed, skipping..."
fi

# Install Node.js dependencies globally
echo "📦 Installing Node.js tools..."
npm install -g \
    prettier \
    eslint \
    typescript \
    create-react-app

# Install Terraform (for IaC in later phases)
if ! command -v terraform &> /dev/null; then
    echo "🏗️  Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update
    sudo apt-get install -y terraform
else
    echo "🏗️  Terraform already installed, skipping..."
fi

# Set up Git hooks directory
if [ ! -d ".githooks" ]; then
    echo "🪝 Setting up Git hooks..."
    git config --global core.hooksPath .githooks
    mkdir -p .githooks
else
    echo "🪝 Git hooks directory already exists, skipping..."
fi

# Initialize Go module if not exists
if [ ! -f "go.mod" ]; then
    echo "📝 Initializing Go module..."
    go mod init github.com/yourusername/trackside
else
    echo "📝 go.mod already exists, skipping..."
fi

# Create useful aliases (only add if not already present)
if ! grep -q "# Trackside aliases" ~/.bashrc; then
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
else
    echo "⚙️  Shell aliases already configured, skipping..."
fi

# Create project directory structure (only if directories don't exist)
echo "📁 Creating project directory structure..."
mkdir -p cmd/webhook cmd/scanner cmd/rbac-analyzer cmd/api-server cmd/alert-manager cmd/threat-intel
mkdir -p internal/admission internal/scanner internal/rbac internal/policy internal/metrics internal/storage internal/alerting
mkdir -p pkg/k8s pkg/utils pkg/types
mkdir -p api/proto api/openapi
mkdir -p deployments/kubernetes deployments/helm deployments/docker deployments/kind
mkdir -p test/integration test/e2e test/fixtures
mkdir -p configs/policies configs/alerts
mkdir -p docs scripts

# Create a sample kind cluster config (only if it doesn't exist)
if [ ! -f "deployments/kind/cluster.yaml" ]; then
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
else
    echo "📋 Kind cluster config already exists, skipping..."
fi

# Create a basic Makefile (only if it doesn't exist)
if [ ! -f "Makefile" ]; then
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
else
    echo "🔨 Makefile already exists, skipping..."
fi

# Create .gitignore (only if it doesn't exist)
if [ ! -f ".gitignore" ]; then
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
else
    echo "📝 .gitignore already exists, skipping..."
fi

# Create a README (only if it doesn't exist)
if [ ! -f "README.md" ]; then
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
else
    echo "📄 README.md already exists, skipping..."
fi

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