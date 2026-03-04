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
