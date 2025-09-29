#!/bin/bash
#
# Git Hooks Setup Script for Dolibarr Development
# Sets up pre-commit hooks to ensure code quality
#

set -e

echo "🔧 Setting up Git hooks for Dolibarr development..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "Not in a Git repository. Please run this script from the root of your Dolibarr repository."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
#
# Dolibarr Pre-commit Hook
# Runs code quality checks before allowing commits
#

echo "Running pre-commit checks..."

# Check if we're in the container
if command -v dolibarr-dev >/dev/null 2>&1; then
    PHPCS_CMD="phpcs"
    PHP_CMD="php"
else
    echo "Pre-commit hooks work best inside the development container"
    PHPCS_CMD="docker exec dolibarr-dev-app phpcs"
    PHP_CMD="docker exec dolibarr-dev-app php"
fi

# Get list of staged PHP files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.php$' || true)

if [ -z "$STAGED_FILES" ]; then
    echo "No PHP files to check"
    exit 0
fi

echo "Checking $(echo "$STAGED_FILES" | wc -l) PHP files..."

# Check PHP syntax
echo "Checking PHP syntax..."
for FILE in $STAGED_FILES; do
    if [ -f "$FILE" ]; then
        $PHP_CMD -l "$FILE" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "PHP syntax error in: $FILE"
            exit 1
        fi
    fi
done

# Run PHPCS if available
if command -v $PHPCS_CMD >/dev/null 2>&1; then
    echo "Running PHPCS code style check..."
    
    # Use Dolibarr ruleset if available, otherwise PSR12
    if [ -f "dev/setup/codesniffer/ruleset.xml" ]; then
        STANDARD="dev/setup/codesniffer/ruleset.xml"
    else
        STANDARD="PSR12"
    fi
    
    for FILE in $STAGED_FILES; do
        if [ -f "$FILE" ]; then
            $PHPCS_CMD --standard="$STANDARD" "$FILE" --error-severity=1
            if [ $? -ne 0 ]; then
                echo "Code style issues found in: $FILE"
                echo "Run 'dolibarr-dev cs-fix' to fix automatically fixable issues"
                exit 1
            fi
        fi
    done
fi

echo "All pre-commit checks passed!"
exit 0
EOF

# Make pre-commit hook executable
chmod +x .git/hooks/pre-commit

# Create prepare-commit-msg hook for commit message templates
cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/bash
#
# Dolibarr Prepare Commit Message Hook
# Provides helpful commit message templates
#

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only run for regular commits (not merge, amend, etc.)
if [ "$COMMIT_SOURCE" = "" ] || [ "$COMMIT_SOURCE" = "template" ]; then
    # Check if commit message is empty or contains default message
    if [ ! -s "$COMMIT_MSG_FILE" ] || grep -q "^#" "$COMMIT_MSG_FILE"; then
        cat > "$COMMIT_MSG_FILE" << 'TEMPLATE'
# Type: Brief description (50 chars max)
#
# Longer description if needed (wrap at 72 chars)
#
# Types:
# feat:     A new feature
# fix:      A bug fix
# docs:     Documentation only changes
# style:    Changes that do not affect code meaning (formatting, etc)
# refactor: A code change that neither fixes a bug nor adds a feature
# test:     Adding missing tests or correcting existing tests
# chore:    Changes to build process or auxiliary tools
#
# Examples:
# feat: Add customer import functionality
# fix: Resolve invoice calculation rounding error
# docs: Update installation guide for Docker setup
TEMPLATE
    fi
fi
EOF

chmod +x .git/hooks/prepare-commit-msg

echo "Git hooks installed successfully!"
echo ""
echo "Hooks installed:"
echo "  • pre-commit: Runs PHP syntax and code style checks"
echo "  • prepare-commit-msg: Provides commit message templates"
echo ""
echo "To bypass hooks temporarily, use: git commit --no-verify"