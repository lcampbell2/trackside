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
