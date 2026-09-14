# iOS Keyboard Extension: Build, Test, and Deployment Guide

## Project Summary

This is a **native Swift/UIKit keyboard extension** for iOS using **KeyboardKit** (free open-source core). It replaces the previous Flutter-based implementation which crashed due to iOS memory limitations (~48–60MB for keyboard extensions).

### Key Features
- ✅ QWERTY keyboard with persistent number row (1–0)
- ✅ Accented character support (long-press on letters)
- ✅ Clipboard history (respects Full Access privacy setting)
- ✅ Cursor movement via space bar swipe (velocity-based)
- ✅ Shift/caps lock toggle (double-tap for caps lock)
- ✅ Delete with accelerating repeat hold
- ✅ Native audio feedback
- ✅ Optimized for <60MB memory footprint
- ✅ Tested layout: safe area + home indicator respect

---

## Part 1: Building the Project on macOS

### Prerequisites

- Xcode 15.0 or later
- macOS 14.0 or later
- iOS 16.0+ deployment target device
- Apple Developer account with team ID

### Step 1: Generate Xcode Project

The project uses **XcodeGen** to generate the Xcode project from `project.yml`. This keeps the project configuration clean and reproducible.

#### Install XcodeGen (if not already installed)

```bash
brew install xcodegen
```

#### Generate the Xcode Project

```bash
cd ios_keyboard
xcodegen generate
```

This creates `Keyboard.xcodeproj` from `project.yml`.

### Step 2: Update Team ID and Bundle ID (if needed)

Edit `ios_keyboard/project.yml`:

```yaml
options:
  bundleIdPrefix: com.yourcompany  # ← Change to your company prefix
  deploymentTarget:
    iOS: "16.0"
  createIntermediateGroups: true
  groupSortPosition: top
  developmentTeam: ABCD1234E5   # ← Add your Apple Developer Team ID
```

Then regenerate:
```bash
xcodegen generate
```

### Step 3: Open and Build in Xcode

```bash
open ios_keyboard/Keyboard.xcodeproj
```

#### In Xcode:
1. Select the **KeyboardHost** scheme
2. Select your **physical device** (not simulator — the 48–60MB memory limit doesn't apply to simulator)
3. Go to **Build Settings**:
   - `DEVELOPMENT_TEAM` should be set to your team ID
   - Both targets (KeyboardHost and KeyboardExtension) must have the same team ID
4. Click **Product > Build** (Cmd+B)

#### Expected Build Success
- Should compile with no errors
- May see warnings about unused code (safe to ignore)

### Step 4: Configure App Group Entitlements

Both targets must have the **same App Group entitlement** to share clipboard data.

**Host Target (KeyboardHost):**
- Select target in Xcode
- **Signing & Capabilities** tab
- ➕ **Capability** → Search "App Groups"
- Add capability with ID: `group.com.ahwfr.keyboard` (matches `KeyboardAppConfiguration.swift`)

**Extension Target (KeyboardExtension):**
- Repeat the same steps
- Must use the **exact same** App Group ID: `group.com.ahwfr.keyboard`

Verify the entitlements files exist:
- `ios_keyboard/Host/KeyboardHost.entitlements` ← contains `com.apple.security.application-groups`
- `ios_keyboard/KeyboardExtension/KeyboardExtension.entitlements` ← same

---

## Part 2: Testing on Physical Device

### Pre-Test Checklist

**IMPORTANT: Do NOT test on simulator.** The iOS memory limit for keyboard extensions is NOT enforced in the simulator, so a build that seems fine there can crash on real devices.

- [ ] Physical device running iOS 16.0 or later
- [ ] Device connected via USB to Mac
- [ ] Xcode can see the device (Window > Devices and Simulators)
- [ ] App Group entitlements configured (see Part 1, Step 4)

### Step 1: Install the Keyboard Extension

1. In Xcode, select **KeyboardHost** scheme and your device
2. Build and run: **Cmd+R**
3. App should launch with a setup screen showing:
   - Keyboard icon
   - Instructions to enable the keyboard
   - Button to open Keyboard Settings

### Step 2: Enable the Keyboard

**In Settings on Device:**
1. Go to **Settings > General > Keyboard > Keyboards**
2. Tap **Add New Keyboard**
3. Scroll and find **Keyboard** (under Installed Keyboards, or in the list)
4. Tap it to enable
5. When prompted, tap **Allow** (standard keyboard permissions)
6. **Important:** Tap to toggle **Full Access** ON
   - This allows the keyboard to read/write the pasteboard
   - Without Full Access, clipboard history won't work (but keyboard typing will still work)

### Step 3: Test Basic Typing

Open any text field:
- **Messages app** (recommended)
- Notes
- Safari address bar
- WhatsApp
- Any third-party app with `UITextField` or `UITextView`

**Test each gesture:**

1. **Tap letters**: Type "hello world"
   - ✓ Characters should appear
   - ✓ Text should be in correct case (respecting shift state)

2. **Tap number row**: Tap "1234567890"
   - ✓ Numbers should appear

3. **Double-tap Shift**:
   - First tap: Shift is active (capital next letter)
   - Second tap within ~0.32s: Caps Lock (icon changes to ⇪, stays uppercase)
   - Third tap: Back to lowercase

4. **Long-press letter** (e.g., "a"):
   - Popover should appear above the key with accented variants: à, á, â, ä, æ, ã, å, ā
   - Tap one: character inserted

5. **Long-press Delete key**:
   - Delete should start immediately
   - After ~0.3s, repeat accelerates (speeds up)
   - After ~1.0s, repeat goes even faster
   - Release: stops deleting
   - ✓ Should feel natural, no lag

6. **Swipe left/right on Space bar**:
   - Drag your finger left/right across space bar
   - Text cursor should move left/right
   - Fast swipe: moves cursor multiple positions
   - Slow swipe: moves cursor one position
   - ✓ Movement should be smooth and velocity-responsive

7. **Tap Globe icon** (🌐):
   - Should switch to next keyboard (e.g., emoji, or another language if installed)

8. **Tap Clipboard icon** (▣):
   - If Full Access is ON:
     - Tray should show up to 4 most recent clipboard items
     - Tap one to paste
     - If no clipboard history, should show "Clipboard is empty"
   - If Full Access is OFF:
     - Should show "Enable Full Access in Settings to use Clipboard"

9. **Tap Return key**:
   - Should insert newline (or send in chat apps like Messages)

### Step 4: Test Rotation

1. Type some text
2. Rotate device from portrait to landscape
   - ✓ Keyboard should reflow to landscape
   - ✓ No visible resize flicker
   - ✓ Text should still be visible
3. Rotate back to portrait
   - ✓ Keyboard should reflow

### Step 5: Test Full Access On/Off

**With Full Access ON:**
1. Copy some text from Notes or Safari
2. Open Messages
3. Tap Clipboard icon in keyboard
4. Clipboard tray should show the text you just copied
5. Tap it to paste

**Then turn OFF Full Access:**
1. Go to Settings > General > Keyboard > Keyboard (our keyboard)
2. Toggle **Full Access** OFF
3. Dismiss and re-open the keyboard
4. Tap Clipboard icon
5. Should now show "Enable Full Access in Settings to use Clipboard"
6. Copy more text; tray should NOT update

### Step 6: Multi-App Testing

Test in these host apps to ensure broad compatibility:

| App | Field Type | Note |
|-----|-----------|------|
| Messages | Chat text field | Standard |
| Notes | Text view | Test multiline |
| Safari | URL bar | Test with autocorrect |
| Contacts | Name field | Test basic UITextField |
| Mail | Compose body | Multiline & cursor movement |
| Third-party app | Any text field | Verify no crashes |
| Password field | Secure text entry | iOS falls back to system keyboard automatically |

---

## Part 3: Memory Profiling (Critical)

This is **the proof** that the crash is fixed. Do NOT skip this.

### Using Instruments (Xcode)

1. While keyboard is running in an app, attach Instruments:
   - **Xcode > Debug > Attach to Process by PID**
   - Find "KeyboardExtension" (the extension process, not KeyboardHost app)

2. Or pre-attach:
   - **Product > Profile** (Cmd+I)
   - Select **Allocations** instrument
   - Run, and switch to text field to activate keyboard

3. In Instruments:
   - Select **Allocations** and **Memory** tracks
   - Record for ~30 seconds of active typing
   - Watch peak memory usage

### What to Test

| Scenario | Expected Peak | What to Watch |
|----------|--------------|---------------|
| Normal typing (10–20 chars) | <20MB | Baseline |
| Rapid typing (hold key) | 20–35MB | Shouldn't spike |
| Clipboard history open (4 clips showing) | 30–40MB | Tray rendering |
| Long-press accented popover showing | 35–45MB | Popover overlay |
| All of above sustained (30s) | <48MB | **Critical:** must stay under ceiling |

### Expected Results

**Before (Flutter-based):**
- Peak memory 80–120MB on startup
- Immediate jetsam kill by OS

**After (native Swift):**
- Peak memory 15–45MB depending on scenario
- **Stable below 48MB for extended use** ✓

### How to Report

Create a screenshot or note with:
```
iOS Keyboard Extension Memory Profile
Device: iPhone 14 Pro (or your device)
OS: iOS 17.1 (or your version)

Test Duration: 30 seconds continuous typing
Instruments Tool: Allocations + Memory

Results:
- Peak Allocations: 38 MB
- Peak Memory: 42 MB
- Sustained (30s avg): 35 MB
- Status: ✅ PASS (below 48MB ceiling)
```

---

## Part 4: Troubleshooting

### Keyboard doesn't appear in Settings

**Symptoms:** After install, Settings > Keyboard > Add New Keyboard doesn't show "Keyboard"

**Solutions:**
1. Verify extension bundle ID is correct:
   - Should be `com.ahwfr.keyboard.extension` (nests under host `com.ahwfr.keyboard`)
   - Check in `Info.plist` under NSExtension > NSExtensionPrincipalClass
2. Rebuild and reinstall:
   ```bash
   xcodebuild clean -project ios_keyboard/Keyboard.xcodeproj
   # Then rebuild in Xcode
   ```
3. Restart device

### Keyboard crashes when enabled

**Symptoms:** Keyboard appears, but crashes/bounces back to system keyboard immediately

**Solutions:**
1. Check memory with Instruments (see Part 3)
2. Verify KeyboardKit package is linked correctly:
   - Host target should have KeyboardKit in "Link Binary with Libraries"
   - Check Build Phases > Link Binary With Libraries
3. Check App Group entitlements (see Part 1, Step 4)
4. Check `KeyboardAppConfiguration.appGroupID` matches entitlements files

### Clipboard not working (Full Access is ON)

**Symptoms:** Clipboard button shows "Enable Full Access in Settings" even though it's enabled

**Solutions:**
1. Restart device
2. Reinstall keyboard:
   ```bash
   xcodebuild clean -project ios_keyboard/Keyboard.xcodeproj
   # Rebuild and reinstall
   ```
3. Check `UserDefaults` initialization:
   - Verify `ClipboardHistoryStore` is using correct suite name
   - Should be `group.com.ahwfr.keyboard` from `KeyboardAppConfiguration.appGroupID`

### Accent popover doesn't appear

**Symptoms:** Long-press on letters shows nothing

**Solutions:**
1. Verify character is in `accentVariants` dict at bottom of `KeyboardViewController.swift`
2. Test with known characters: a, e, o, n (these have variants defined)
3. Check if popover is off-screen:
   - On smaller devices (iPhone SE), popover might be positioned off-screen
   - Try long-pressing keys in the middle of keyboard first

### Delete repeat is too fast or slow

**Symptoms:** Long-press delete accelerates too quickly or too slowly

**Tuning in `KeyboardViewController.swift`, `startDeleting()` method:**
```swift
// Initial repeat interval (0.32s = 3.1 repeats/sec)
Timer.scheduledTimer(withTimeInterval: 0.32, repeats: true) { ... }

// After 1.0 second, switch to faster interval (0.055s ≈ 18 repeats/sec)
if heldFor > 1.0 { ... }
```

To adjust:
- Reduce first interval (e.g., 0.25s) for faster initial repeat
- Increase threshold (e.g., 1.5s) to delay acceleration
- Reduce second interval (e.g., 0.045s) for faster acceleration

---

## Part 5: Building for Release (Archive & IPA)

Once testing passes, build a signed IPA for distribution or TestFlight:

### Step 1: Set Up Code Signing

In Xcode:
1. Select **KeyboardHost** target
2. **Signing & Capabilities** tab
3. Ensure **Team** is set to your Apple Developer Team
4. Both targets must use the same team

### Step 2: Archive

```bash
cd ios_keyboard
xcodebuild archive -project Keyboard.xcodeproj \
  -scheme KeyboardHost \
  -archivePath build/Keyboard.xcarchive \
  -destination generic/platform=iOS \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  PROVISIONING_PROFILE_SPECIFIER="<your-profile-name>"
```

Or in Xcode GUI:
1. **Product > Archive**
2. Xcode opens Organizer
3. Select archive
4. Click **Distribute App**
5. Choose **App Store Connect** or **Ad Hoc**

### Step 3: Export IPA

From Organizer:
1. Select archive
2. **Export**
3. Choose **Ad Hoc** (for testing) or **App Store** (for submission)
4. IPA is exported to your chosen location

---

## Part 6: Deployment Checklist

Before shipping to production:

- [ ] Memory profiling complete; peak <48MB on physical device
- [ ] Tested on iPhone SE, standard iPhone, and Pro Max (or at least 2 devices)
- [ ] Tested portrait and landscape orientation
- [ ] Tested Full Access ON and OFF
- [ ] Tested in Messages, Notes, Safari, and at least 1 third-party app
- [ ] Accent popover works for accented characters
- [ ] Clipboard history shows and pastes correctly
- [ ] Cursor movement via space swipe works smoothly
- [ ] Delete repeat has expected acceleration
- [ ] Shift/caps lock toggles correctly
- [ ] Globe button switches keyboard
- [ ] No visible flicker on rotation
- [ ] App Group entitlements configured for both targets
- [ ] Bundle IDs follow nesting pattern (host.extension)
- [ ] Code signing team set for both targets
- [ ] Deployment target iOS 16.0 or later

---

## Appendix: File Structure

```
ios_keyboard/
├── project.yml                         # XcodeGen config (generates .xcodeproj)
├── Host/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── SetupViewController.swift        # UI with setup instructions
│   ├── Info.plist
│   ├── KeyboardHost.entitlements        # App Group entitlement
├── KeyboardExtension/
│   ├── KeyboardViewController.swift     # Main keyboard implementation
│   │   ├── KeyboardInputViewController setup
│   │   ├── Layout: number row + letter rows
│   │   ├── Gestures: tap, long-press, swipe, double-tap
│   │   ├── Animations: key press, shift state, popover
│   │   ├── ClipboardHistoryStore (App Group UserDefaults)
│   │   ├── KeyboardKey (custom UIControl)
│   │   ├── AccentPopover (overlay for accents)
│   │   └── accentVariants dict
│   ├── KeyboardAppConfiguration.swift   # App Group ID constant
│   ├── Info.plist
│   ├── KeyboardExtension.entitlements   # App Group entitlement
└── Shared/
    └── (empty; can hold shared code if needed in future)
```

---

## Contact & Support

For issues or questions:
- Review this guide's Troubleshooting section
- Check Xcode build logs for Swift compilation errors
- Attach Instruments memory profile to any bug report
- Verify device meets iOS 16.0+ requirement

---

**Last Updated:** September 2026  
**KeyboardKit Version:** 10.7.3 (free open-source core)  
**Minimum iOS:** 16.0  
**Memory Ceiling:** <48–60MB (iOS limit for keyboard extensions)
