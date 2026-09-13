# Keyboard

This repository contains two related surfaces:

- `lib/` is a Flutter preview used for fast widget testing and desktop
	development.
- `ios_keyboard/` is the production iOS host app and custom keyboard
	extension. The extension is native Swift because iOS launches keyboard
	extensions as isolated `UIInputViewController` processes; changes to the
	Flutter preview do not change the installed system keyboard.

## Flutter checks

```sh
flutter pub get
flutter analyze
flutter test
```

## Build the iOS project

The native Xcode project is generated from `ios_keyboard/project.yml` with
XcodeGen. The keyboard uses KeyboardKit 10.9.4 for the native layout,
gestures, callouts, feedback, and text actions. Run this on macOS with Xcode,
XcodeGen, and an Apple Developer account configured:

```sh
cd ios_keyboard
xcodegen generate
cd ..
xcodebuild -project ios_keyboard/Keyboard.xcodeproj \
	-scheme KeyboardHost \
	-configuration Debug \
	-sdk iphonesimulator
```

For a signed device archive, select an Apple Developer Team in the generated
project, register the host and extension bundle identifiers, then archive the
`KeyboardHost` scheme for `Any iOS Device` and export the archive from Xcode.

To test the extension, install the host app, enable `Keyboard` under Settings
> General > Keyboard > Keyboards, then select it from the Globe key in an app
with a normal text field. Secure fields, phone pads, and apps that disable
third-party keyboards intentionally use the system keyboard instead.

Clipboard access requires the user to enable **Allow Full Access**. Without
full access, normal typing remains available but the clipboard controls are
disabled, as required by iOS keyboard-extension sandboxing.
