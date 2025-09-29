# Dolibarr 22.0.1 Development Container

Complete VS Code DevContainer setup for Dolibarr development with proper structure and all tools configured.

## Quick Start

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

3. **Open this folder in VS Code:**
   ```bash
   cd images/22.0.1-php8.2-devcontainer
   code .
   ```

4. **Reopen in Container:**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Dev Containers: Reopen in Container"
   - Wait for container to build and start

5. **Access Services:**
   - Dolibarr: http://localhost:8080
   - phpMyAdmin: http://localhost:8081



### Database Initialization
The database initializes automatically on first run. To manually initialize:
```bash
# Access install page
http://localhost:8080/install/

# Or use CLI
cd /var/www/html
php htdocs/install/index.php
```

### Xdebug Setup
Xdebug is pre-configured. To debug:
1. Set breakpoints in VS Code
2. Press F5 or go to Run → Start Debugging
3. Select "Listen for Xdebug"
4. Access your page in browser
5. Debugger will pause at breakpoints

The launch.json is automatically included in the devcontainer.

## Development Tools

### Code Quality
```bash
# Check code style (Dolibarr standards)
dolibarr-dev cs-check

# Fix code style automatically
dolibarr-dev cs-fix

# Run static analysis
dolibarr-dev stan

# Run tests
dolibarr-dev test
```

### Extensions Included
- **PHP Debug** (Xdebug integration)
- **PHP Intelephense** (IntelliSense)
- **PHPCS** (Code style checking)
- **PHP CS Fixer** (Auto-formatting)
- **PHPStan** (Static analysis)
- **PHPUnit** (Testing)
- **GitLens** (Git integration)

## Database Access

### phpMyAdmin
- URL: http://localhost:8080/phpmyadmin
- Username: `dolibarr`
- Password: `dolibarr_dev_password`

### Command Line
```bash
# Inside container
mysql -h db -u dolibarr -pdolibarr_dev_password dolibarr
```

## File Structure

```
/var/www/
├── html/                    # Dolibarr source code (Apache serves from here)
│   ├── htdocs/             # Main Dolibarr application  
│   ├── custom/             # Custom modules
│   ├── dev/                # Development tools
│   ├── scripts/            # Utility scripts
│   └── test/               # Tests
├── documents/              # User uploaded files (persistent)
└── .vscode-server/         # VS Code server files
```

## Common Tasks

### Install Dolibarr
1. Access http://localhost:8080
2. Follow installation wizard
3. Database details are pre-configured:
   - Host: `db`
   - Database: `dolibarr`
   - User: `dolibarr`
   - Password: `dolibarr_dev_password`

### Clone Your Fork
```bash
# Inside container
cd /var/www/html
git remote add myfork https://github.com/YOUR-USERNAME/dolibarr.git
git fetch myfork
```

### Run Pre-commit Hooks
Git hooks are automatically set up. They run on each commit:
- PHP syntax check
- Code style check (PHPCS)

To bypass (not recommended):
```bash
git commit --no-verify
```

## Troubleshooting

### Website Loading Infinitely (Stuck/Hanging)

**Symptom:** The website loads forever and never displays content.

**Cause:** Xdebug is configured with `xdebug.start_with_request=yes`, which means it waits for a debugger connection on **every** request. If VS Code isn't listening, requests hang indefinitely.

### Database Not Initializing
Check if DOLI_INSTALL_AUTO is enabled:
```bash
echo $DOLI_INSTALL_AUTO  # Should be 0 for manual, 1 for auto
```

Or manually run the install:
```bash
http://localhost:8080/install/
```

### Xdebug Not Working
1. Check Xdebug is loaded:
   ```bash
   php -m | grep xdebug
   ```

2. Check configuration:
   ```bash
   php -i | grep xdebug
   ```

3. Verify port 9003 is forwarded (should be automatic)

### Permission Issues
```bash
# Fix permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
```

## Contributing

This devcontainer follows Dolibarr coding standards:
- PSR-12 with Dolibarr exceptions
- Tabs allowed (not spaces)
- Line length: 120 chars (soft), 1000 chars (hard)
- Unix line endings (LF)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| DOLI_DB_HOST | db | Database host |
| DOLI_DB_NAME | dolibarr | Database name |
| DOLI_DB_USER | dolibarr | Database user |
| DOLI_DB_PASSWORD | dolibarr_dev_password | Database password |
| DOLI_URL_ROOT | http://localhost:8080 | Application URL |
| DOLI_DEV_MODE | 1 | Enable development mode |

## Version Specific Notes

This container is specifically for Dolibarr 22.0.1 with PHP 8.2.

For other versions, see the parent `images/` directory for version-specific containers.

## Support

For issues with this devcontainer, open an issue in the dolibarr-docker repository.
For Dolibarr core issues, use the main Dolibarr repository.

---

Happy Dolibarr Development!