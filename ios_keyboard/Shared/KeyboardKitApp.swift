import KeyboardKit

extension KeyboardApp {
    static var ahwfrKeyboard: KeyboardApp {
        .init(
            name: "Keyboard",
            appGroupId: "group.com.ahwfr.keyboard",
            locales: .keyboardKitSupported
        )
    }
}
