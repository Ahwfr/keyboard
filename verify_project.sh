#!/bin/bash
# Verification script for iOS Keyboard Extension project setup
# Run this on macOS after cloning the project to verify all files are in place

set -e

KEYBOARD_DIR="${1:-.}/ios_keyboard"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

check_file() {
    local file="$1"
    local required="${2:-true}"
    
    if [ -f "$KEYBOARD_DIR/$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $file (REQUIRED)"
            ((errors++))
        else
            echo -e "${YELLOW}⚠${NC} $file (optional)"
            ((warnings++))
        fi
    fi
}

check_dir() {
    local dir="$1"
    
    if [ -d "$KEYBOARD_DIR/$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir/"
    else
        echo -e "${RED}✗${NC} $dir/ (REQUIRED)"
        ((errors++))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "iOS Keyboard Extension Project Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "Checking directory structure..."
check_dir "Host"
check_dir "KeyboardExtension"
check_dir "Shared"
echo

echo "Checking project configuration..."
check_file "project.yml"
echo

echo "Checking Host target files..."
check_file "Host/AppDelegate.swift"
check_file "Host/SceneDelegate.swift"
check_file "Host/SetupViewController.swift"
check_file "Host/Info.plist"
check_file "Host/KeyboardHost.entitlements"
echo

echo "Checking KeyboardExtension target files..."
check_file "KeyboardExtension/KeyboardViewController.swift"
check_file "KeyboardExtension/KeyboardAppConfiguration.swift"
check_file "KeyboardExtension/Info.plist"
check_file "KeyboardExtension/KeyboardExtension.entitlements"
echo

echo "Checking Swift code for common issues..."
echo

# Check for actual Flutter usage in extension (should be NONE); explanatory
# comments that merely mention Flutter by name don't count as a violation.
if grep -rE "^\s*import Flutter\b" "$KEYBOARD_DIR/KeyboardExtension" 2>/dev/null; then
    echo -e "${RED}✗${NC} KeyboardExtension contains Flutter references (should be 100% native Swift)"
    ((errors++))
else
    echo -e "${GREEN}✓${NC} No Flutter references in extension"
fi

# KeyboardKit is intentionally NOT used: every recent release's Package.swift
# has a trailing-comma syntax error that fails to resolve on CI's Xcode.
if grep -q "import KeyboardKit" "$KEYBOARD_DIR/KeyboardExtension/KeyboardViewController.swift"; then
    echo -e "${RED}✗${NC} KeyboardKit is imported but its Package.swift fails to resolve on CI"
    ((errors++))
else
    echo -e "${GREEN}✓${NC} No KeyboardKit dependency (avoids upstream Package.swift bug)"
fi

# Check for UIInputViewController subclass
if grep -q "class KeyboardViewController: UIInputViewController" "$KEYBOARD_DIR/KeyboardExtension/KeyboardViewController.swift"; then
    echo -e "${GREEN}✓${NC} KeyboardViewController extends UIInputViewController"
else
    echo -e "${RED}✗${NC} KeyboardViewController should extend UIInputViewController"
    ((errors++))
fi

# Check for AudioFeedback protocol
if grep -q "UIInputViewAudioFeedback" "$KEYBOARD_DIR/KeyboardExtension/KeyboardViewController.swift"; then
    echo -e "${GREEN}✓${NC} UIInputViewAudioFeedback protocol implemented"
else
    echo -e "${YELLOW}⚠${NC} UIInputViewAudioFeedback not found (audio feedback may not work)"
    ((warnings++))
fi

# Check for App Group setup
if grep -q "group.com.ahwfr.keyboard" "$KEYBOARD_DIR/KeyboardExtension/KeyboardAppConfiguration.swift"; then
    echo -e "${GREEN}✓${NC} App Group ID configured"
else
    echo -e "${RED}✗${NC} App Group ID not found in configuration"
    ((errors++))
fi

# Check entitlements
if grep -q "com.apple.security.application-groups" "$KEYBOARD_DIR/KeyboardExtension/KeyboardExtension.entitlements"; then
    echo -e "${GREEN}✓${NC} Extension entitlements include App Group"
else
    echo -e "${RED}✗${NC} Extension entitlements missing App Group"
    ((errors++))
fi

if grep -q "com.apple.security.application-groups" "$KEYBOARD_DIR/Host/KeyboardHost.entitlements"; then
    echo -e "${GREEN}✓${NC} Host entitlements include App Group"
else
    echo -e "${RED}✗${NC} Host entitlements missing App Group"
    ((errors++))
fi

# Check Info.plist for RequestsOpenAccess
if grep -q "RequestsOpenAccess" "$KEYBOARD_DIR/KeyboardExtension/Info.plist"; then
    echo -e "${GREEN}✓${NC} Extension Info.plist has RequestsOpenAccess for clipboard"
else
    echo -e "${YELLOW}⚠${NC} RequestsOpenAccess not found in extension Info.plist"
    ((warnings++))
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verification Result:"
echo

if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo
    echo "Next steps:"
    echo "1. On macOS: brew install xcodegen"
    echo "2. cd ios_keyboard && xcodegen generate"
    echo "3. open Keyboard.xcodeproj"
    echo "4. Set DEVELOPMENT_TEAM in build settings"
    echo "5. Select physical device"
    echo "6. Product > Build (Cmd+B)"
    echo "7. Product > Run (Cmd+R) to install on device"
    if [ $warnings -gt 0 ]; then
        echo
        echo -e "${YELLOW}Note:${NC} $warnings warning(s) found. See above."
    fi
    exit 0
else
    echo -e "${RED}✗ $errors error(s) found. Fix above before proceeding.${NC}"
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠ $warnings warning(s) also present.${NC}"
    fi
    exit 1
fi
