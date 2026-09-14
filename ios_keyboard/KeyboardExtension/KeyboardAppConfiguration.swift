import KeyboardKit

/// The ID must be enabled in the Apple Developer portal for both targets.
enum KeyboardAppConfiguration {
    static let appGroupID = "group.com.ahwfr.keyboard"

    static let app = KeyboardApp(
        name: "Keyboard",
        appGroupId: appGroupID
    )
}
