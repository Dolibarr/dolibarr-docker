#!/bin/bash
# Dolibarr Development Helper Script (Improved)
# Works on current directory by default

case "$1" in
    "test")
        echo "Running PHPUnit tests..."
        cd /var/www/html && phpunit
        ;;
    "cs-check")
        TARGET="${2:-.}"  # Use 2nd argument or current directory
        echo "🔍 Checking code style with PHPCS on: $(realpath "$TARGET")"
        if [ -f "/var/www/html/dev/setup/codesniffer/ruleset.xml" ]; then
            phpcs --standard=/var/www/html/dev/setup/codesniffer/ruleset.xml "$TARGET" --extensions=php
        else
            phpcs --standard=PSR12 "$TARGET" --extensions=php
        fi
        ;;
    "cs-fix")
        TARGET="${2:-.}"  # Use 2nd argument or current directory
        echo "🔧 Fixing code style with PHP-CS-Fixer on: $(realpath "$TARGET")"
        php-cs-fixer fix "$TARGET" --rules=@PSR12
        ;;
    "stan")
        TARGET="${2:-.}"  # Use 2nd argument or current directory
        echo "🔬 Running PHPStan static analysis on: $(realpath "$TARGET")"
        phpstan analyse "$TARGET" --level=5
        ;;
    *)
        echo "📦 Dolibarr Development Helper"
        echo ""
        echo "Usage: dolibarr-dev [command] [path]"
        echo ""
        echo "Commands:"
        echo "  test                - Run PHPUnit tests"
        echo "  cs-check [path]     - Check code style (default: current directory)"
        echo "  cs-fix [path]       - Fix code style (default: current directory)"
        echo "  stan [path]         - Run static analysis (default: current directory)"
        echo ""
        echo "Examples:"
        echo "  # Check current directory"
        echo "  cd /var/www/html/custom/mymodule && dolibarr-dev cs-check"
        echo ""
        echo "  # Check specific path"
        echo "  dolibarr-dev cs-check /var/www/html/custom/mymodule"
        echo ""
        echo "  # Check all custom modules"
        echo "  dolibarr-dev cs-check /var/www/html/custom"
        echo ""
        echo "  # Check single file"
        echo "  cd /var/www/html/custom/mymodule && dolibarr-dev cs-check myfile.php"
        ;;
esac
