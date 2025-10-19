#!/bin/bash
# ==============================================================================
# Git Hooks Installation Script
# ==============================================================================
# Installs pre-commit hook for the Sarcopenia project
#
# Usage:
#   ./scripts/install_hooks.sh

set -e

echo "🔧 Installing Git hooks for Sarcopenia project..."
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo "❌ ERROR: Not in a Git repository root"
  echo "Please run this script from the project root directory"
  exit 1
fi

# Check if hooks directory exists
if [ ! -d ".git/hooks" ]; then
  echo "Creating .git/hooks directory..."
  mkdir -p .git/hooks
fi

# Install pre-commit hook
if [ -f "scripts/pre-commit" ]; then
  echo "📋 Installing pre-commit hook..."
  cp scripts/pre-commit .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  echo "✅ Pre-commit hook installed"
else
  echo "❌ ERROR: scripts/pre-commit not found"
  exit 1
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ Installation complete!"
echo ""
echo "The pre-commit hook will now run automatically before each commit."
echo "It will check for:"
echo "  • PHI/PII patterns"
echo "  • Large files (>10MB)"
echo "  • Code style issues"
echo "  • Test failures"
echo "  • Debugging code"
echo "  • Documentation consistency"
echo "  • Security issues"
echo ""
echo "To bypass the hook (use sparingly):"
echo "  git commit --no-verify"
echo ""
