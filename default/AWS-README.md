# {{PROJECT_NAME}}

This infrastructure project was scaffolded using **Terruvim CLI**.
It uses **Pulumi** to manage cloud infrastructure as code (IaC) on **AWS**.

## Documentation:
[![Version](https://img.shields.io/npm/v/terruvim-cli.svg)](https://npmjs.org/package/terruvim-cli)

## 📋 Prerequisites

Ensure you have the following tools installed:

- [Node.js](https://nodejs.org/) (v18+)
- [Pulumi CLI](https://www.pulumi.com/docs/get-started/install/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Docker](https://www.docker.com/) (Required for building Lambda layers/images locally)

## 🔐 Configuration

### 1. Install Dependencies
```bash
  npm install
```

### 2. AWS Credentials Setup
This project uses named AWS profiles for security isolation between environments. Open your `~/.aws/credentials` file and add the following blocks:

Note: Replace placeholders with your real AWS IAM keys.
```text
  # Root/Shared resources (ECR, DNS zones, etc.)
  [{{PROJECT_NAME}}-root]
  aws_access_key_id=AKIA...
  aws_secret_access_key=SECRET...
  
  # Development Environment
  [{{PROJECT_NAME}}-dev]
  aws_access_key_id=AKIA...
  aws_secret_access_key=SECRET...
  
  # Staging Environment (Optional)
  [{{PROJECT_NAME}}-stage]
  aws_access_key_id=AKIA...
  aws_secret_access_key=SECRET...
  
  # Production Environment (Optional)
  [{{PROJECT_NAME}}-prod]
  aws_access_key_id=AKIA...
  aws_secret_access_key=SECRET...
```

### 3. Environment Configuration
The infrastructure configuration is driven by JSON files located in the envs/ directory:

- `envs/infrastructure.json` - Shared/Global settings
- `envs/infrastructure.dev.json` - Settings for Dev
- `envs/infrastructure.prod.json` - Settings for Prod

Modify these files to change instance sizes, domain names, or other parameters.

## 🚀 Deployment Workflow
Initial Login

Login to the Pulumi backend (Service or Local):

```bash
  pulumi login
```

### Select an Environment (Stack)
Pulumi uses "stacks" to represent environments. The CLI has generated config files for you (e.g., `Pulumi.{{PROJECT_NAME}}-dev.yaml`).

To switch to the Development environment:
```bash
  pulumi stack select {{PROJECT_NAME}}-dev
```

_If the stack does not exist yet in the backend, initialize it:_
```bash
  pulumi stack init {{PROJECT_NAME}}-dev
```

### Preview Changes
Before applying any changes, always run a preview to see what will happen:
```bash
  pulumi preview
```

### Deploy Infrastructure
To provision or update resources in the cloud:
```bash
  pulumi up
```
_Select "yes" when prompted to confirm._

## 🧹 Teardown
To destroy all resources in the selected environment (**⚠️ Destructive Action**):
```bash
  pulumi destroy
```

## 📂 Project Structure
```text
├── assets/              # Configuration for assets
├── envs/                # JSON Configuration for each environment
├── pulumi/              # Pulumi YAML configs (stacks)
├── index.ts             # Entry point
├── Pulumi.yaml          # Main project definition
└── package.json         # Dependencies
```

## 🛠 Troubleshooting
**Docker Error during build:** If you see errors related to building assets, ensure Docker is running smoothly:

```bash
  docker ps
```

**AWS Profile Error:** If Pulumi complains about missing credentials, check that the profile name in `Pulumi.{{PROJECT_NAME}}-<env>.yaml` matches exactly what is in your `~/.aws/credentials`.