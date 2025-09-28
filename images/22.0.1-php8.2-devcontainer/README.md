# Dolibarr Development Container

A complete development environment for Dolibarr ERP CRM using Docker and VS Code DevContainers.

## 🚀 Quick Start

### Prerequisites

- Docker Desktop
- VS Code with the Dev Containers extension
- Git

### Setup

1. **Clone this repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/dolibarr-docker.git
   cd dolibarr-docker/images/22.0.1-php8.2-devcontainer
   ```

2. **Run the setup script:**
   ```bash
   chmod +x scripts/setup-development.sh
   ./scripts/setup-development.sh
   ```

3. **Open in VS Code:**
   ```bash
   code ../../..
   ```

4. **Reopen in Container:**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Dev Containers: Reopen in Container"
   - Select the option and wait for the container to build

## 🛠️ What's Included

### Development Tools

- **PHP 8.2** with all Dolibarr required extensions
- **Xdebug** configured for VS Code debugging
- **Composer** for dependency management
- **Code Quality Tools:**
  - PHPUnit for testing
  - PHPCS for code style checking (Dolibarr standards)
  - PHPStan for static analysis
  - PHP CS Fixer for automatic code formatting
  - PHPMD for mess detection

### Services

- **Dolibarr Application** (http://localhost:8080)
- **MariaDB 10.11** database
- **phpMyAdmin** (http://localhost:8081)
- **MailHog** for email testing (http://localhost:8025)

### VS Code Integration

- **Pre-configured extensions** for PHP development
- **Debugging support** with Xdebug
- **IntelliSense** with Intelephense
- **Code formatting** on save
- **Git integration** with helpful hooks

## 📁 Project Structure

```
dolibarr-docker/
├── .devcontainer/
│   └── devcontainer.json           # VS Code container configuration
├── images/22.0.1-php8.2-devcontainer/
│   ├── Dockerfile                  # Development Docker image
│   ├── docker-compose.yml          # Multi-service setup
│   ├── config/
│   │   └── mysql/
│   │       └── dolibarr-dev.cnf    # MySQL development config
│   ├── scripts/
│   │   ├── setup-development.sh    # Environment setup script
│   │   └── setup-git-hooks.sh      # Git hooks installer
│   ├── dolibarr/                   # Your Dolibarr source code (auto-created)
│   └── README.md                   # This file
└── helper scripts...
```

## 🔧 Development Workflow

### 1. Code Quality Checks

The environment includes pre-commit hooks that automatically run:

- **PHP syntax check** - Ensures no syntax errors
- **PHPCS** - Checks code style against Dolibarr standards
- **Automatic formatting** - VS Code formats on save

#### Manual Quality Checks

```bash
# Check code style
dolibarr-dev cs-check

# Fix code style issues
dolibarr-dev cs-fix

# Run static analysis
dolibarr-dev stan

# Run all tests
dolibarr-dev test
```

### 2. Debugging

1. **Set breakpoints** in VS Code
2. **Start debugging** with F5 or the debug panel
3. **Access your application** at http://localhost:8080
4. **Debug in browser** - Xdebug will pause at breakpoints

### 3. Database Management

- **phpMyAdmin**: http://localhost:8081
  - Host: `db`
  - Username: `dolibarr`
  - Password: `dolibarr_dev_password`

- **Direct MySQL access**:
  ```bash
  docker exec -it dolibarr-dev-db mysql -u dolibarr -p dolibarr
  ```

### 4. Email Testing

All emails sent by Dolibarr are captured by MailHog:
- **Web Interface**: http://localhost:8025
- **SMTP Server**: localhost:1025 (configured automatically)

## 🎯 Development Commands

### Inside the Container

```bash
# Development helper (main command)
dolibarr-dev [command]

# Available commands:
dolibarr-dev test      # Run PHPUnit tests
dolibarr-dev cs-check  # Check code style
dolibarr-dev cs-fix    # Fix code style
dolibarr-dev stan      # Run static analysis
```

### From Host Machine

```bash
# Run tests
./run-tests.sh

# Check code quality
./check-code-quality.sh

# Fix code style
./fix-code-style.sh

# Access container shell
docker exec -it dolibarr-dev-app bash
```

## 🔄 Git Workflow

The environment sets up helpful Git hooks:

### Pre-commit Hook
Automatically runs before each commit:
- PHP syntax validation
- Code style checks
- Prevents commits with style issues

### Commit Message Template
Provides structured commit messages:
```
feat: Add customer import functionality

Longer description if needed

Types: feat, fix, docs, style, refactor, test, chore
```

### Working with Forks

If you're using a personal fork:

```bash
# Sync with upstream
git fetch upstream
git checkout develop
git merge upstream/develop

# Create feature branch
git checkout -b feature/my-new-feature

# Push to your fork
git push origin feature/my-new-feature
```

## 📚 Dolibarr Development Guidelines

This environment follows Dolibarr's official coding standards:

### Code Style
- **PSR-12** compliant with Dolibarr exceptions
- **Tabs allowed** (not forced to spaces)
- **Line length**: 120 characters (soft limit), 1000 characters (hard limit)
- **Unix line endings** (LF)

### File Structure
- **PHP files**: Start with `<?php`
- **Class files**: Use `.class.php` extension
- **Include files**: Use `.inc.php` extension
- **Template files**: Use `.tpl.php` extension

### Database
- **Tables**: Prefix with `llx_`
- **Primary keys**: Always `rowid`
- **Character set**: `utf8mb4_unicode_ci`

## 🚨 Troubleshooting

### Container Issues

**Container won't start:**
```bash
# Check Docker logs
docker-compose logs dolibarr-dev

# Rebuild container
docker-compose build --no-cache dolibarr-dev
```

**Permission issues:**
```bash
# Fix file permissions
docker exec dolibarr-dev-app chown -R www-data:www-data /var/www/html
```

### Database Issues

**Can't connect to database:**
```bash
# Check database status
docker-compose logs db

# Restart database
docker-compose restart db
```

**Database not initialized:**
```bash
# Access Dolibarr install page
http://localhost:8080/install/
```

### Xdebug Issues

**Debugging not working:**
1. Check VS Code has PHP Debug extension installed
2. Verify launch.json configuration
3. Ensure port 9003 is not blocked
4. Check Xdebug logs: `docker exec dolibarr-dev-app tail -f /var/log/xdebug.log`

### Code Quality Issues

**PHPCS errors:**
```bash
# See detailed error report
phpcs --standard=/var/www/html/dev/setup/codesniffer/ruleset.xml --report=full htdocs/

# Fix automatically fixable issues
phpcbf --standard=/var/www/html/dev/setup/codesniffer/ruleset.xml htdocs/
```

## 🤝 Contributing

### To Dolibarr Core

1. **Fork** the main Dolibarr repository
2. **Clone** your fork into the `dolibarr/` directory
3. **Create** a feature branch
4. **Develop** using this environment
5. **Test** thoroughly
6. **Submit** a pull request

### To This Development Environment

1. **Fork** this dolibarr-docker repository
2. **Make** your improvements
3. **Test** with a fresh setup
4. **Document** your changes
5. **Submit** a pull request

## 📝 Environment Variables

### Application Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DOLI_DB_HOST` | `db` | Database host |
| `DOLI_DB_NAME` | `dolibarr` | Database name |
| `DOLI_DB_USER` | `dolibarr` | Database user |
| `DOLI_DB_PASSWORD` | `dolibarr_dev_password` | Database password |
| `DOLI_URL_ROOT` | `http://localhost:8080` | Application URL |
| `DOLI_ADMIN_LOGIN` | `admin` | Default admin login |
| `DOLI_ADMIN_PASSWORD` | `admin_dev_password` | Default admin password |

### Development Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DOLI_DEV_MODE` | `1` | Enable development mode |
| `DOLI_PROD` | `0` | Disable production mode |
| `XDEBUG_CONFIG` | `client_host=host.docker.internal...` | Xdebug configuration |
| `WWW_USER_ID` | `1000` | Web server user ID |
| `WWW_GROUP_ID` | `1000` | Web server group ID |

## 🏷️ Version Compatibility

| Dolibarr Version | PHP Version | Status |
|------------------|-------------|--------|
| 22.0.1 | 8.2 | ✅ Current |
| 21.0.4 | 8.2 | ✅ Supported |
| 20.0.4 | 8.1 | ⚠️ Legacy |

## 📖 Additional Resources

- [Dolibarr Developer Documentation](https://wiki.dolibarr.org/index.php/Developer_documentation)
- [Dolibarr Coding Standards](https://wiki.dolibarr.org/index.php/Language_and_development_rules)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📄 License

This development environment configuration is provided under the same license as Dolibarr ERP CRM (GPL v3 or later).

## 🙋‍♂️ Support

For issues related to:
- **This development environment**: Open an issue in this repository
- **Dolibarr core**: Use the [Dolibarr GitHub repository](https://github.com/Dolibarr/dolibarr)
- **VS Code DevContainers**: Check the [VS Code documentation](https://code.visualstudio.com/docs/devcontainers/containers)

---

**Happy Dolibarr Development! 🎉**