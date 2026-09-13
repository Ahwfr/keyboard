import KeyboardKit

extension KeyboardApp {
    static var ahwfrKeyboard: KeyboardApp {
        .init(
            name: "Keyboard",
            locales: .keyboardKitSupported
        )
    }
}
