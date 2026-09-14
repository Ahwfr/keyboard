import UIKit

/// Native keyboard extension. There is deliberately no Flutter engine or
/// FlutterViewController in this target: extensions have a small memory budget.
final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {

    private enum ShiftState { case lower, shift, capsLock }

    private let rootStack = UIStackView()
    private let clipboardTray = UIStackView()
    private var letterKeys: [KeyboardKey] = []
    private var shiftKey: KeyboardKey?
    private var shiftState: ShiftState = .lower
    private var lastShiftTap = Date.distantPast
    private var deleteTimer: Timer?
    private var deleteStartedAt: Date?
    private var lastPasteboardChangeCount = -1
    private var cursorPanTranslation: CGFloat = 0
    private var accentPopover: AccentPopover?

    private let clipboardStore = ClipboardHistoryStore(
        suiteName: KeyboardAppConfiguration.appGroupID
    )

    private let numberRow = Array("1234567890").map(String.init)
    private let firstRow = Array("qwertyuiop").map(String.init)
    private let secondRow = Array("asdfghjkl").map(String.init)
    private let thirdRow = Array("zxcvbnm").map(String.init)

    var enableInputClicksWhenVisible: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .systemGray6 : .systemGray5
        }
        buildKeyboard()
        refreshClipboardIfNeeded()
        updateShiftAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshClipboardIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDeleting()
        dismissAccentPopover()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshClipboardIfNeeded()
        if shiftState == .shift { shiftState = .lower }
        updateShiftAppearance()
    }

    deinit { deleteTimer?.invalidate() }

    private func buildKeyboard() {
        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -7),
        ])

        configureClipboardTray()
        rootStack.addArrangedSubview(clipboardTray)
        clipboardTray.isHidden = true
        rootStack.addArrangedSubview(makeLetterRow(numberRow, style: .secondary))
        rootStack.addArrangedSubview(makeLetterRow(firstRow))
        rootStack.addArrangedSubview(makeInsetRow(secondRow))
        rootStack.addArrangedSubview(makeActionRow())
        rootStack.addArrangedSubview(makeBottomRow())
    }

    private func configureClipboardTray() {
        clipboardTray.axis = .horizontal
        clipboardTray.spacing = 6
        clipboardTray.alignment = .fill
        clipboardTray.heightAnchor.constraint(equalToConstant: 38).isActive = true
    }

    private func redrawClipboardTray() {
        clipboardTray.arrangedSubviews.forEach { item in
            clipboardTray.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
        guard hasFullAccess else {
            let message = KeyboardKey(title: "Enable Full Access in Settings to use Clipboard", style: .secondary)
            message.isUserInteractionEnabled = false
            clipboardTray.addArrangedSubview(message)
            return
        }
        let clips = clipboardStore.clips
        if clips.isEmpty {
            let empty = KeyboardKey(title: "Clipboard is empty", style: .secondary)
            empty.isUserInteractionEnabled = false
            clipboardTray.addArrangedSubview(empty)
        } else {
            clips.prefix(4).forEach { clip in
                let title = clip.replacingOccurrences(of: "\n", with: " ")
                let key = KeyboardKey(title: String(title.prefix(28)), style: .secondary)
                key.onTap = { [weak self] in self?.insertClip(clip) }
                clipboardTray.addArrangedSubview(key)
            }
        }
    }

    private func makeLetterRow(_ letters: [String], style: KeyboardKey.Style = .primary) -> UIStackView {
        let row = makeRow()
        letters.forEach { row.addArrangedSubview(makeCharacterKey($0, style: style)) }
        return row
    }

    private func makeInsetRow(_ letters: [String]) -> UIStackView {
        let row = makeRow()
        row.addArrangedSubview(spacer(width: 16))
        letters.forEach { row.addArrangedSubview(makeCharacterKey($0)) }
        row.addArrangedSubview(spacer(width: 16))
        return row
    }

    private func makeActionRow() -> UIStackView {
        let row = makeRow()
        let shift = KeyboardKey(title: "⇧", style: .secondary)
        shift.accessibilityLabel = "Shift"
        shift.onTap = { [weak self] in self?.shiftTapped() }
        shift.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shiftKey = shift
        row.addArrangedSubview(shift)
        thirdRow.forEach { row.addArrangedSubview(makeCharacterKey($0)) }

        let delete = KeyboardKey(title: "⌫", style: .secondary)
        delete.accessibilityLabel = "Delete"
        delete.onTouchDown = { [weak self] in self?.startDeleting() }
        delete.onTouchUp = { [weak self] in self?.stopDeleting() }
        delete.widthAnchor.constraint(equalToConstant: 44).isActive = true
        row.addArrangedSubview(delete)
        return row
    }

    private func makeBottomRow() -> UIStackView {
        let row = makeRow()
        let globe = KeyboardKey(title: "🌐", style: .secondary)
        globe.accessibilityLabel = "Next keyboard"
        globe.onTap = { [weak self] in self?.advanceToNextInputMode() }
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        let clipboard = KeyboardKey(title: "▣", style: .secondary)
        clipboard.accessibilityLabel = "Clipboard history"
        clipboard.onTap = { [weak self] in self?.toggleClipboardTray() }

        let space = KeyboardKey(title: "space", style: .primary)
        space.accessibilityLabel = "Space"
        space.onTap = { [weak self] in self?.textDocumentProxy.insertText(" ") }
        space.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(spacePanned(_:))))

        let returnKey = KeyboardKey(title: "return", style: .secondary)
        returnKey.accessibilityLabel = "Return"
        returnKey.onTap = { [weak self] in self?.textDocumentProxy.insertText("\n") }
        [globe, clipboard, space, returnKey].forEach(row.addArrangedSubview)
        globe.widthAnchor.constraint(equalToConstant: 43).isActive = true
        clipboard.widthAnchor.constraint(equalToConstant: 43).isActive = true
        returnKey.widthAnchor.constraint(equalToConstant: 70).isActive = true
        return row
    }

    private func makeCharacterKey(_ character: String, style: KeyboardKey.Style = .primary) -> KeyboardKey {
        let key = KeyboardKey(title: character, style: style)
        key.accessibilityLabel = character.uppercased()
        key.onTap = { [weak self, weak key] in
            guard let self, let key else { return }
            self.type(key.baseTitle)
        }
        if let variants = accentVariants[character] {
            key.onLongPress = { [weak self, weak key] in
                guard let self, let key else { return }
                self.showAccentPopover(variants, from: key)
            }
        }
        if style == .primary { letterKeys.append(key) }
        return key
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        // Key height is content-driven. Do not impose an extension height.
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        return row
    }

    private func spacer(width: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.widthAnchor.constraint(equalToConstant: width).isActive = true
        return spacer
    }

    private func type(_ character: String) {
        let value: String
        switch shiftState {
        case .lower: value = character
        case .shift, .capsLock: value = character.uppercased()
        }
        textDocumentProxy.insertText(value)
        if shiftState == .shift { shiftState = .lower }
        updateShiftAppearance()
    }

    private func shiftTapped() {
        let now = Date()
        if now.timeIntervalSince(lastShiftTap) < 0.32 {
            shiftState = shiftState == .capsLock ? .lower : .capsLock
        } else {
            shiftState = shiftState == .lower ? .shift : .lower
        }
        lastShiftTap = now
        updateShiftAppearance()
    }

    private func updateShiftAppearance() {
        let uppercased = shiftState != .lower
        letterKeys.forEach {
            $0.setDisplayedTitle(uppercased ? $0.baseTitle.uppercased() : $0.baseTitle.lowercased())
        }
        shiftKey?.setDisplayedTitle(shiftState == .capsLock ? "⇪" : "⇧")
        shiftKey?.isSelected = shiftState != .lower
    }

    private func startDeleting() {
        textDocumentProxy.deleteBackward()
        deleteStartedAt = Date()
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.32, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.textDocumentProxy.deleteBackward()
            let heldFor = Date().timeIntervalSince(self.deleteStartedAt ?? Date())
            if heldFor > 1.0, let timer = self.deleteTimer {
                timer.invalidate()
                self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.055, repeats: true) { [weak self] _ in
                    self?.textDocumentProxy.deleteBackward()
                }
            }
        }
    }

    private func stopDeleting() {
        deleteTimer?.invalidate()
        deleteTimer = nil
        deleteStartedAt = nil
    }

    @objc private func spacePanned(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            cursorPanTranslation = 0
        case .changed:
            let translation = gesture.translation(in: gesture.view).x
            let velocity = gesture.velocity(in: gesture.view).x
            // Velocity gives the cursor a system-like responsive feel while
            // translation prevents fast, repeated over-stepping.
            let weighted = translation + velocity * 0.045
            let step = Int((weighted - cursorPanTranslation) / 18)
            guard step != 0 else { return }
            cursorPanTranslation += CGFloat(step * 18)
            moveCursor(by: step)
        default:
            cursorPanTranslation = 0
        }
    }

    private func moveCursor(by requestedOffset: Int) {
        // UITextDocumentProxy only exposes text adjacent to the selection. Its
        // counts are safe bounds, avoiding cursor desync past either document end.
        let before = textDocumentProxy.documentContextBeforeInput?.count ?? 0
        let after = textDocumentProxy.documentContextAfterInput?.count ?? 0
        let offset = max(-before, min(requestedOffset, after))
        guard offset != 0 else { return }
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
    }

    private func toggleClipboardTray() {
        if !hasFullAccess {
            clipboardTray.isHidden = false
            redrawClipboardTray()
            return
        }
        refreshClipboardIfNeeded(force: true)
        clipboardTray.isHidden.toggle()
        redrawClipboardTray()
    }

    private func refreshClipboardIfNeeded(force: Bool = false) {
        guard hasFullAccess else { return }
        let pasteboard = UIPasteboard.general
        guard force || pasteboard.changeCount != lastPasteboardChangeCount else { return }
        lastPasteboardChangeCount = pasteboard.changeCount
        if let text = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            clipboardStore.record(text)
        }
        if !clipboardTray.isHidden { redrawClipboardTray() }
    }

    private func insertClip(_ clip: String) {
        textDocumentProxy.insertText(clip)
        clipboardTray.isHidden = true
    }

    private func showAccentPopover(_ values: [String], from key: UIView) {
        dismissAccentPopover()
        let popover = AccentPopover(values: values) { [weak self] value in
            self?.type(value)
            self?.dismissAccentPopover()
        }
        popover.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popover)
        let sourceFrame = key.convert(key.bounds, to: view)
        NSLayoutConstraint.activate([
            popover.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: sourceFrame.midX),
            popover.bottomAnchor.constraint(equalTo: view.topAnchor, constant: sourceFrame.minY - 4),
        ])
        accentPopover = popover
        popover.present()
    }

    private func dismissAccentPopover() {
        accentPopover?.removeFromSuperview()
        accentPopover = nil
    }
}

private let accentVariants: [String: [String]] = [
    "a": ["à", "á", "â", "ä", "æ", "ã", "å", "ā"],
    "c": ["ç", "ć", "č"], "e": ["è", "é", "ê", "ë", "ē"],
    "i": ["î", "ï", "í", "ī"], "n": ["ñ", "ń"],
    "o": ["ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"],
    "s": ["ß", "ś", "š"], "u": ["û", "ü", "ù", "ú", "ū"],
    "y": ["ÿ"], "z": ["ž", "ź", "ż"]
]

private final class ClipboardHistoryStore {
    private let defaults: UserDefaults?
    private let key = "keyboard.clipboard.history.v1"
    private(set) var clips: [String]

    init(suiteName: String) {
        defaults = UserDefaults(suiteName: suiteName)
        clips = defaults?.stringArray(forKey: key) ?? []
    }

    func record(_ clip: String) {
        // Bound clips and history to protect the extension's memory budget.
        let limited = String(clip.prefix(1_000))
        clips = [limited] + clips.filter { $0 != limited }
        clips = Array(clips.prefix(10))
        defaults?.set(clips, forKey: key)
    }
}

private final class KeyboardKey: UIControl {
    enum Style { case primary, secondary }

    let baseTitle: String
    var onTap: (() -> Void)?
    var onTouchDown: (() -> Void)?
    var onTouchUp: (() -> Void)?
    var onLongPress: (() -> Void)?
    private let label = UILabel()
    private let style: Style
    private var longPressFired = false

    init(title: String, style: Style) {
        baseTitle = title
        self.style = style
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = .keyboardKey
        layer.cornerRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1)
        backgroundColor = style == .primary ? .systemBackground : .systemGray3
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setDisplayedTitle(title)
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:))))
    }

    required init?(coder: NSCoder) { nil }

    func setDisplayedTitle(_ title: String) {
        label.text = title
        accessibilityLabel = title
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        longPressFired = false
        onTouchDown?()
        animatePressed(true)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        onTouchUp?()
        animatePressed(false)
        if !longPressFired { onTap?() }
    }

    override func cancelTracking(with event: UIEvent?) {
        onTouchUp?()
        animatePressed(false)
    }

    @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, onLongPress != nil else { return }
        longPressFired = true
        onLongPress?()
    }

    private func animatePressed(_ pressed: Bool) {
        UIView.animate(withDuration: 0.10, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            self.transform = pressed ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            self.backgroundColor = pressed ? .systemGray4 : (self.style == .primary ? .systemBackground : .systemGray3)
        }
    }
}

private final class AccentPopover: UIStackView {
    init(values: [String], onSelect: @escaping (String) -> Void) {
        super.init(frame: .zero)
        axis = .horizontal
        spacing = 1
        layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        isLayoutMarginsRelativeArrangement = true
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
        values.forEach { value in
            let button = UIButton(type: .system)
            button.setTitle(value, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 23)
            button.widthAnchor.constraint(equalToConstant: 35).isActive = true
            button.heightAnchor.constraint(equalToConstant: 42).isActive = true
            button.addAction(UIAction { _ in onSelect(value) }, for: .touchUpInside)
            addArrangedSubview(button)
        }
    }

    required init?(coder: NSCoder) { nil }

    func present() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        UIView.animate(withDuration: 0.14, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}
