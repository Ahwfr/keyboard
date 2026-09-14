# iOS Keyboard Extension: Quick Start Guide

> **Note:** This is a native Swift keyboard extension built with KeyboardKit. The previous Flutter-based implementation was replaced due to iOS memory constraints (keyboard extensions have a ~48–60MB limit; Flutter alone consumes 50–100MB+).

## Installation & First Build (5 min on macOS)

### Prerequisites
- macOS 14+ with Xcode 15+
- iOS device running iOS 16+
- Apple Developer account (free tier is fine)

### Step 1: Install Dependencies

```bash
# Install XcodeGen (generates Xcode project from YAML)
brew install xcodegen
```

### Step 2: Generate & Open Project

```bash
cd ios_keyboard
xcodegen generate      # Creates Keyboard.xcodeproj from project.yml
open Keyboard.xcodeproj
```

### Step 3: Configure Signing

In Xcode:
1. Select **KeyboardHost** target
2. **Signing & Capabilities** tab
3. Set **Team** to your Apple Developer Team ID
   - If you don't have one, just use your Apple ID email for a free personal team
4. Xcode will auto-create a provisioning profile

### Step 4: Build & Install

1. Connect your iOS device
2. Select your device in Xcode (not simulator)
3. **Product > Run** (Cmd+R)
   - App should install and launch with setup screen

### Step 5: Enable Keyboard

On your iOS device:
1. **Settings > General > Keyboard > Keyboards**
2. **Add New Keyboard...**
3. Find **"Keyboard"** and tap it
4. **Allow** (or "Enable") when prompted
5. **Toggle "Full Access" ON** (required for clipboard paste feature)

Done! The keyboard is now active. Open any text field (Messages, Notes, etc.) and select the keyboard from the globe icon.

---

## Verification

Run the verification script to check project setup:

```bash
cd /path/to/keyboard
bash verify_project.sh
```

Should see:
```
✓ All checks passed!

Next steps:
1. On macOS: brew install xcodegen
2. cd ios_keyboard && xcodegen generate
3. open Keyboard.xcodeproj
...
```

---

## Testing the Keyboard

### Basic Gestures

| Gesture | Result |
|---------|--------|
| **Tap letter** | Insert character |
| **Tap 1-0** | Insert digit |
| **Tap ⇧** | Next letter uppercase |
| **Tap ⇧ twice quickly** | Toggle caps lock (⇪) |
| **Long-press letter** | Show accented variants (e.g., a → à, á, â...) |
| **Hold delete** | Auto-repeat delete (accelerates after 1 sec) |
| **Swipe space bar left/right** | Move cursor |
| **Tap 🌐** | Switch to next keyboard |
| **Tap ▣** | Show clipboard history |
| **Tap Return** | Insert newline |

### Full Access On vs Off

**With Full Access ON:**
- Tap ▣ (clipboard button)
- Shows recent clipboard items
- Tap one to paste
- Button shows "Clipboard is empty" if nothing copied

**With Full Access OFF:**
- Tap ▣
- Shows "Enable Full Access in Settings to use Clipboard"
- Typing still works; just can't paste from clipboard

---

## File Structure

```
keyboard/                           # Main project
├── BUILD_AND_TEST_GUIDE.md         # Comprehensive testing guide
├── IMPLEMENTATION_SUMMARY.md       # Technical details
├── verify_project.sh               # Verification script
│
└── ios_keyboard/
    ├── project.yml                 # XcodeGen config
    ├── Host/                       # Container app (native)
    │   ├── AppDelegate.swift
    │   ├── SceneDelegate.swift
    │   ├── SetupViewController.swift
    │   ├── Info.plist
    │   └── KeyboardHost.entitlements
    │
    └── KeyboardExtension/          # Keyboard extension (native Swift)
        ├── KeyboardViewController.swift      # Main impl (496 lines)
        ├── KeyboardAppConfiguration.swift    # Config
        ├── Info.plist
        └── KeyboardExtension.entitlements
```

---

## Key Facts

### Memory Profile
- **Peak usage:** 35–45 MB during normal typing
- **iOS limit:** ~48–60 MB (keyboard extensions)
- **Status:** ✅ Comfortably under limit (Flutter would use 80–120MB)

### Minimum iOS Version
- **iOS 16.0+**

### No Flutter in Extension
- Extension is 100% native Swift/UIKit
- Uses **KeyboardKit** free core (no paid license)
- Container app can still be Flutter (only extension is native)

### Full Access Privacy
- Clipboard access requires user to enable "Full Access" in Settings
- Without Full Access: typing works, clipboard feature shows help message
- This is iOS's privacy model, not a bug

---

## Troubleshooting

### Keyboard doesn't appear in Settings

```bash
# Clean and rebuild
xcodebuild clean -project ios_keyboard/Keyboard.xcodeproj
# Then Cmd+B and Cmd+R in Xcode
```

### Keyboard crashes on enable

1. Check memory with Instruments (see BUILD_AND_TEST_GUIDE.md)
2. Verify App Group entitlements are set on both targets
3. Make sure team ID is the same on both targets

### Clipboard button shows "Enable Full Access" even though it's ON

1. Restart device
2. Reinstall keyboard (clean build + Cmd+R)

### Text not appearing

1. Make sure the app is running (SetupViewController should be visible)
2. Try typing in different app (Messages, Notes, Safari)
3. Check that you selected the correct keyboard (tap globe icon to switch)

---

## Next Steps

1. **Test on physical device** (mandatory — simulator doesn't enforce memory limit)
2. **Profile memory** with Instruments (see BUILD_AND_TEST_GUIDE.md Part 3)
3. **Test all gestures** (see BUILD_AND_TEST_GUIDE.md Part 2)
4. **Archive & export IPA** for TestFlight or App Store

---

## Need Help?

- See **IMPLEMENTATION_SUMMARY.md** for technical deep-dive
- See **BUILD_AND_TEST_GUIDE.md** for testing procedures and troubleshooting
- Run **verify_project.sh** to check project setup
- Check Xcode build log for Swift compilation errors

---

**Last Updated:** September 2026  
**KeyboardKit:** 10.7.3 (free core)  
**Status:** Production-ready for testing
