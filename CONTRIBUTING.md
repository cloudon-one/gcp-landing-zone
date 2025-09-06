# Contributing to GCP Landing Zone

Thank you for your interest in contributing to the GCP Landing Zone project! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Security](#security)
- [Release Process](#release-process)

## 📝 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please read and follow our code of conduct:

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome newcomers and help them succeed
- **Be collaborative**: Work together and share knowledge
- **Be constructive**: Provide helpful feedback and criticism
- **Be patient**: Understand that people have different experience levels

### Unacceptable Behavior

- Harassment, discrimination, or offensive language
- Personal attacks or trolling
- Sharing others' private information without consent
- Any conduct that would be considered inappropriate in a professional setting

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- Google Cloud account with appropriate permissions
- Terraform >= 1.5.0
- Google Cloud SDK (gcloud CLI)
- Git >= 2.20
- A code editor with Terraform syntax support
- Docker (for testing)

### Development Environment Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/cloudon-one/gcp-landing-zone.git
   cd gcp-landing-zone
   ```

2. **Set Up Pre-commit Hooks**

   ```bash
   # Install pre-commit
   pip install pre-commit
   
   # Install hooks
   pre-commit install
   
   # Run hooks on all files (optional)
   pre-commit run --all-files
   ```

3. **Configure Environment**

   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Edit with your values
   vim .env
   source .env
   ```

4. **Verify Setup**

   ```bash
   # Check Terraform version
   terraform version
   
   # Check Google Cloud authentication
   gcloud auth list
   
   # Validate Terraform configuration
   terraform fmt -check
   terraform validate
   ```

## 🔄 Development Workflow

### Branch Naming Convention

Use descriptive branch names following this pattern:

- `feature/description-of-feature`
- `fix/description-of-fix`
- `docs/description-of-docs-change`
- `refactor/description-of-refactor`
- `test/description-of-test-addition`

Examples:

- `feature/add-private-gke-cluster`
- `fix/vpc-peering-connection-issue`
- `docs/update-deployment-instructions`

### Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring without functionality changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```bash
feat(gke): add private cluster with authorized networks

- Enable private nodes by default
- Configure authorized networks for API server access
- Add network tags for firewall rules

Closes #123
```

```bash
fix(sql): resolve connection timeout issues

The Cloud SQL instance was timing out due to incorrect
network configuration. Updated the private IP settings
and VPC peering configuration.

Fixes #456
```

### Issue Management

Before starting work:

1. **Check Existing Issues**: Search for existing issues related to your work
2. **Create an Issue**: If none exists, create a detailed issue describing:
   - Problem or feature request
   - Expected behavior
   - Current behavior
   - Steps to reproduce (for bugs)
   - Proposed solution

3. **Assign Yourself**: Comment on the issue to indicate you're working on it

## 📏 Code Standards

### Terraform Standards

#### File Organization

```
module/
├── main.tf           # Primary resource definitions
├── variables.tf      # Input variable declarations
├── outputs.tf        # Output value declarations
├── versions.tf       # Provider version constraints
├── locals.tf         # Local value definitions (if needed)
├── data.tf          # Data source definitions (if many)
└── README.md        # Module documentation
```

#### Naming Conventions

**Resources:**

```hcl
# Use descriptive names with underscores
resource "google_compute_network" "vpc_network" {
  name = "fintech-vpc"
}

resource "google_container_cluster" "primary_cluster" {
  name = "fintech-gke-cluster"
}
```

**Variables:**

```hcl
# Use snake_case for variable names
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "enable_private_nodes" {
  description = "Enable private nodes in GKE cluster"
  type        = bool
  default     = true
}
```

**Locals:**

```hcl
locals {
  # Use descriptive names
  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
  }
  
  # Group related values
  network_config = {
    vpc_cidr       = "10.0.0.0/8"
    gke_cidr       = "10.160.0.0/16"
    services_cidr  = "10.161.0.0/16"
  }
}
```

#### Code Style

**Formatting:**

```hcl
# Use terraform fmt to format code
# Align arguments vertically when multiple lines
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  # Use consistent indentation (2 spaces)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
  
  # Group related configurations
  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
}
```

**Comments:**

```hcl
# Use comments to explain complex logic or business requirements
# This network is specifically designed for fintech workloads
# with strict segmentation requirements per PCI DSS
resource "google_compute_network" "fintech_vpc" {
  name                    = "fintech-vpc"
  auto_create_subnetworks = false
  
  # Routing mode set to regional for better performance
  # within the same region while maintaining security
  routing_mode = "REGIONAL"
}
```

#### Variable Documentation

```hcl
variable "authorized_networks" {
  description = <<-EOF
    List of CIDR blocks that are allowed to access the GKE API server.
    These should include:
    - VPN gateway ranges for on-premises access
    - Bastion host subnet ranges
    - Other trusted network ranges
    
    Example: ["10.0.1.0/24", "203.0.113.0/24"]
  EOF
  type        = list(string)
  default     = []
  
  validation {
    condition = length(var.authorized_networks) > 0
    error_message = "At least one authorized network must be specified for security."
  }
}
```

### Directory Structure Standards

```
module-name/
├── README.md              # Module documentation
├── main.tf               # Main resource definitions
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Provider versions
├── backend.tf            # Backend configuration
├── terraform.tfvars.example  # Example variables
├── examples/             # Usage examples
│   ├── basic/
│   ├── complete/
│   └── multi-environment/
└── test/                 # Automated tests
    ├── terraform_test.go
    └── fixtures/
```

### Documentation Standards

#### Module README Template

Each module must include a comprehensive README.md:

```markdown
# Module Name

Brief description of what this module does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Usage

```hcl
module "example" {
  source = "./modules/module-name"
  
  project_id = "my-project"
  region     = "us-central1"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 5.0.0 |

## Resources

| Name | Type |
|------|------|
| google_compute_network.vpc | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC network ID |
```

#### Inline Documentation

```hcl
# Configure the GKE cluster with fintech-specific security settings
# This cluster is designed to meet PCI DSS Level 1 requirements
resource "google_container_cluster" "fintech_cluster" {
  name     = "${var.environment}-fintech-cluster"
  location = var.region
  
  # Remove default node pool immediately after cluster creation
  # We'll create custom node pools with specific configurations
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Enable Workload Identity for secure pod-to-GCP authentication
  # This replaces the need for service account keys
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
```

## 🧪 Testing

### Testing Strategy

We use multiple levels of testing:

1. **Syntax Testing**: `terraform fmt` and `terraform validate`
2. **Unit Testing**: Terratest for module validation
3. **Integration Testing**: End-to-end deployment testing
4. **Security Testing**: tfsec and Checkov scans
5. **Manual Testing**: Infrastructure validation


### Before submitting a PR, ensure:

- [ ] `terraform fmt` passes
- [ ] `terraform validate` passes on all modules
- [ ] Unit tests pass
- [ ] Security scans pass
- [ ] Integration tests pass (if applicable)
- [ ] Manual testing completed
- [ ] Documentation updated

## 📖 Documentation

### Documentation Requirements

All contributions must include appropriate documentation:

1. **Code Comments**: Explain complex logic and business requirements
2. **README Updates**: Update module READMEs for new features
3. **Variable Documentation**: Document all input variables
4. **Output Documentation**: Document all outputs
5. **Example Updates**: Update examples if needed

### Documentation Style Guide

- Use clear, concise language
- Include practical examples
- Explain the "why" not just the "what"
- Link to relevant GCP documentation
- Use proper markdown formatting

## 🔄 Pull Request Process

### Before Submitting

1. **Update Documentation**: Ensure all docs are current
2. **Run Tests**: All tests must pass
3. **Check Security**: Run security scans
4. **Update Changelog**: Add entry to CHANGELOG.md (if exists)
5. **Rebase**: Rebase on latest main branch

### PR Title and Description

**Title Format:**

```
<type>(scope): brief description

Examples:
feat(gke): add support for private clusters
fix(networking): resolve VPC peering issues
docs(readme): update deployment instructions
```

**Description Template:**

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Local testing completed
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Security scans pass

## Screenshots/Logs
Include relevant screenshots or log output.

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No sensitive information in code
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs all tests
2. **Code Review**: At least one maintainer reviews the code
3. **Security Review**: Security team reviews security-related changes
4. **Integration Testing**: Deploy to test environment
5. **Approval**: Required approvals before merge

### Review Criteria

Reviewers will check for:

- Code quality and adherence to standards
- Security best practices
- Performance implications
- Documentation completeness
- Test coverage
- Breaking changes properly documented

## 🔒 Security

### Security Guidelines

When contributing:

1. **No Secrets**: Never commit secrets, keys, or credentials
2. **Security Scanning**: Run security scans before submitting
3. **Principle of Least Privilege**: Follow minimal access principles
4. **Encryption**: Ensure data is encrypted at rest and in transit
5. **Network Security**: Implement proper network isolation
6. **Audit Logging**: Enable comprehensive audit logging

### Security Review Process

Security-sensitive changes require:

1. **Security Team Review**: Additional review by security team
2. **Threat Modeling**: For significant architectural changes
3. **Penetration Testing**: For new attack surfaces
4. **Compliance Check**: Ensure regulatory compliance

### Reporting Security Issues

Report security vulnerabilities privately via [SECURITY.md](./SECURITY.md).

## 📦 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions  
- **PATCH** version for backwards-compatible bug fixes

### Release Checklist

1. Update CHANGELOG.md
2. Update version numbers
3. Create release notes
4. Tag the release
5. Update documentation
6. Announce the release

### Release Notes Template

```markdown
## [1.2.0] - 2025-09-06

### Added
- New GKE autopilot support
- VPC Service Controls integration
- Multi-region deployment support

### Changed
- Updated Terraform provider versions
- Improved error handling in modules
- Enhanced security configurations

### Deprecated
- Legacy network configuration (will be removed in 2.0.0)

### Removed
- Deprecated firewall module

### Fixed
- Fixed VPC peering connectivity issues
- Resolved Cloud SQL backup scheduling
- Fixed IAM policy binding conflicts

### Security
- Updated base images to latest versions
- Enhanced encryption configurations
- Added additional security scanning
```

## 💡 Tips for Contributors

### Best Practices

1. **Start Small**: Begin with small, focused contributions
2. **Ask Questions**: Don't hesitate to ask for clarification
3. **Follow Examples**: Look at existing code for patterns
4. **Test Thoroughly**: Test changes in multiple scenarios
5. **Document Changes**: Update documentation with code changes

### Common Pitfalls

- Not testing in a clean environment
- Forgetting to update documentation
- Including sensitive information
- Not following naming conventions
- Creating overly complex solutions

### Getting Help

- **GitHub Discussions**: For general questions
- **Issues**: For bugs and feature requests
- **Slack**: For real-time discussions
- **Code Reviews**: For implementation feedback

## 📞 Contact

- **Security Team**: security@cloudon-one.com

Thank you for contributing to make this project better! 🚀