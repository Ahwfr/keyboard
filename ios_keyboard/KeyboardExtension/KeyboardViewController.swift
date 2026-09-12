import UIKit

final class KeyboardViewController: UIInputViewController {
    private let keyboard = UIStackView()
    private let clipboardScroll = UIScrollView()
    private let clipboardStack = UIStackView()
    private var shifted = false
    private var deleteTimer: Timer?

    private let letters = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
    private let keyBackground = UIColor.white
    private let panelBackground = UIColor(red: 0.82, green: 0.83, blue: 0.86, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = panelBackground
        buildKeyboard()
        refreshClipboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        preferredContentSize = CGSize(width: 0, height: 296)
    }

    private func buildKeyboard() {
        keyboard.axis = .vertical
        keyboard.spacing = 7
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboard)
        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor, constant: 7),
            keyboard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5)
        ])

        addClipboardRow()
        addNumberRow()
        for row in letters { addLetterRow(row) }
        addBottomRow()
    }

    private func addClipboardRow() {
        clipboardScroll.showsHorizontalScrollIndicator = false
        clipboardScroll.alwaysBounceHorizontal = true
        clipboardStack.axis = .horizontal
        clipboardStack.spacing = 7
        clipboardStack.translatesAutoresizingMaskIntoConstraints = false
        clipboardScroll.addSubview(clipboardStack)
        NSLayoutConstraint.activate([
            clipboardStack.leadingAnchor.constraint(equalTo: clipboardScroll.leadingAnchor),
            clipboardStack.trailingAnchor.constraint(equalTo: clipboardScroll.trailingAnchor),
            clipboardStack.topAnchor.constraint(equalTo: clipboardScroll.topAnchor),
            clipboardStack.bottomAnchor.constraint(equalTo: clipboardScroll.bottomAnchor),
            clipboardStack.heightAnchor.constraint(equalTo: clipboardScroll.heightAnchor)
        ])
        keyboard.addArrangedSubview(clipboardScroll)
        clipboardScroll.heightAnchor.constraint(equalToConstant: 34).isActive = true
    }

    private func addNumberRow() {
        let row = makeRow()
        for number in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
            row.addArrangedSubview(makeKey(title: number, action: #selector(insertKey(_:)), value: number))
        }
        keyboard.addArrangedSubview(row)
    }

    private func addLetterRow(_ letters: String) {
        let row = makeRow()
        for letter in letters {
            let value = String(letter)
            row.addArrangedSubview(makeKey(title: value, action: #selector(insertKey(_:)), value: value))
        }
        keyboard.addArrangedSubview(row)
    }

    private func addBottomRow() {
        let row = makeRow()
        let shift = makeKey(title: "⇧", action: #selector(toggleShift))
        shift.accessibilityIdentifier = "shift-key"
        row.addArrangedSubview(shift)
        row.addArrangedSubview(makeKey(title: "space", action: #selector(insertSpace)))
        let delete = makeKey(title: "⌫", action: #selector(deleteBackward))
        delete.addTarget(self, action: #selector(beginDelete), for: .touchDown)
        delete.addTarget(self, action: #selector(endDelete), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        row.addArrangedSubview(delete)
        keyboard.addArrangedSubview(row)
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillEqually
        return row
    }

    private func makeKey(title: String, action: Selector, value: String? = nil) -> KeyButton {
        let button = KeyButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = title == "space" ? .systemFont(ofSize: 15) : .systemFont(ofSize: 21)
        button.backgroundColor = keyBackground
        button.layer.cornerRadius = 5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.18
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.accessibilityLabel = title == "⌫" ? "Backspace" : title
        button.value = value
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func insertKey(_ sender: KeyButton) {
        guard let value = sender.value else { return }
        textDocumentProxy.insertText(shifted ? value.uppercased() : value)
        if shifted { shifted = false; updateLetterCase() }
    }

    @objc private func insertSpace() { textDocumentProxy.insertText(" ") }
    @objc private func deleteBackward() { textDocumentProxy.deleteBackward() }
    @objc private func toggleShift() { shifted.toggle(); updateLetterCase() }

    @objc private func beginDelete() {
        deleteBackward()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in self?.deleteBackward() }
    }

    @objc private func endDelete() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    private func updateLetterCase() {
        for case let row as UIStackView in keyboard.arrangedSubviews.dropFirst(2) {
            for case let key as KeyButton in row.arrangedSubviews {
                guard let value = key.value else { continue }
                key.setTitle(shifted ? value.uppercased() : value, for: .normal)
            }
        }
    }

    private func refreshClipboard() {
        clipboardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let clipboardButton = makeAccessory(title: "📋", action: #selector(readClipboard))
        clipboardStack.addArrangedSubview(clipboardButton)
        guard hasFullAccess else {
            let accessLabel = makeAccessory(title: "Enable Full Access for clipboard", action: #selector(readClipboard))
            accessLabel.isEnabled = false
            clipboardStack.addArrangedSubview(accessLabel)
            return
        }
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        let item = makeAccessory(title: text, action: #selector(insertClipboard(_:)))
        item.value = text
        clipboardStack.addArrangedSubview(item)
    }

    private func makeAccessory(title: String, action: Selector) -> KeyButton {
        let button = KeyButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.backgroundColor = UIColor(white: 0.93, alpha: 1)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 11)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func readClipboard() { refreshClipboard() }
    @objc private func insertClipboard(_ sender: KeyButton) {
        if let value = sender.value { textDocumentProxy.insertText(value) }
    }
}

private final class KeyButton: UIButton {
    var value: String?
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.08) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
                self.backgroundColor = self.isHighlighted ? UIColor(white: 0.78, alpha: 1) : (self.titleLabel?.text == "⇧" && self.superview != nil ? self.backgroundColor : .white)
            }
        }
    }
}
