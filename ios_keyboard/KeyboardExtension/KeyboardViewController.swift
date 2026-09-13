import UIKit

final class KeyboardViewController: UIInputViewController {
    private let rootStack = UIStackView()
    private var letterButtons: [UIButton] = []
    private var isShifted = false
    private var shiftButton: UIButton?

    private let numberRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    private let firstRow = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let secondRow = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    private let thirdRow = ["z", "x", "c", "v", "b", "n", "m"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .systemGray6 : .systemGray5
        }
        buildKeyboard()
        updateShiftAppearance()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateShiftAppearance()
    }

    private func buildKeyboard() {
        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.distribution = .fillEqually
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 286),
        ])

        rootStack.addArrangedSubview(makeLetterRow(numberRow, isNumberRow: true))
        rootStack.addArrangedSubview(makeLetterRow(firstRow))
        rootStack.addArrangedSubview(makeInsetRow(secondRow, inset: 16))
        rootStack.addArrangedSubview(makeActionRow())
        rootStack.addArrangedSubview(makeBottomRow())
    }

    private func makeLetterRow(_ titles: [String], isNumberRow: Bool = false) -> UIStackView {
        let row = makeRow()
        titles.forEach { title in
            let button = makeKey(title, style: isNumberRow ? .secondary : .primary)
            button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
            if !isNumberRow { letterButtons.append(button) }
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeInsetRow(_ titles: [String], inset: CGFloat) -> UIStackView {
        let row = makeRow()
        let leading = UIView()
        let trailing = UIView()
        leading.widthAnchor.constraint(equalToConstant: inset).isActive = true
        trailing.widthAnchor.constraint(equalToConstant: inset).isActive = true
        row.addArrangedSubview(leading)
        titles.forEach { title in
            let button = makeKey(title)
            button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
            letterButtons.append(button)
            row.addArrangedSubview(button)
        }
        row.addArrangedSubview(trailing)
        return row
    }

    private func makeActionRow() -> UIStackView {
        let row = makeRow()
        let shift = makeKey("⇧", style: .secondary)
        shift.accessibilityLabel = "Shift"
        shift.addTarget(self, action: #selector(shiftTapped), for: .touchUpInside)
        shift.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shiftButton = shift
        row.addArrangedSubview(shift)
        thirdRow.forEach { title in
            let button = makeKey(title)
            button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
            letterButtons.append(button)
            row.addArrangedSubview(button)
        }
        let delete = makeKey("⌫", style: .secondary)
        delete.accessibilityLabel = "Delete"
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        delete.widthAnchor.constraint(equalToConstant: 44).isActive = true
        row.addArrangedSubview(delete)
        return row
    }

    private func makeBottomRow() -> UIStackView {
        let row = makeRow()
        let globe = makeKey("🌐", style: .secondary)
        globe.accessibilityLabel = "Next keyboard"
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        let clipboard = makeKey("📋", style: .secondary)
        clipboard.accessibilityLabel = "Paste clipboard"
        clipboard.addTarget(self, action: #selector(clipboardTapped), for: .touchUpInside)
        let space = makeKey("space", style: .primary)
        space.accessibilityLabel = "Space"
        space.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        let returnKey = makeKey("return", style: .secondary)
        returnKey.accessibilityLabel = "Return"
        returnKey.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        [globe, clipboard, space, returnKey].forEach(row.addArrangedSubview)
        globe.widthAnchor.constraint(equalToConstant: 43).isActive = true
        clipboard.widthAnchor.constraint(equalToConstant: 43).isActive = true
        returnKey.widthAnchor.constraint(equalToConstant: 70).isActive = true
        return row
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        return row
    }

    private enum KeyStyle { case primary, secondary }

    private func makeKey(_ title: String, style: KeyStyle = .primary) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = style == .primary ? .systemBackground : .systemGray3
        configuration.cornerStyle = .medium
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 20, weight: .regular)
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowRadius = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        return button
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let title = sender.configuration?.title else { return }
        textDocumentProxy.insertText(isShifted ? title.uppercased() : title)
        if isShifted { isShifted = false }
        updateShiftAppearance()
    }

    @objc private func shiftTapped() { isShifted.toggle(); updateShiftAppearance() }
    @objc private func deleteTapped() { textDocumentProxy.deleteBackward() }
    @objc private func spaceTapped() { textDocumentProxy.insertText(" ") }
    @objc private func returnTapped() { textDocumentProxy.insertText("\n") }

    @objc private func clipboardTapped() {
        guard hasFullAccess else { showNotice("Enable Full Access to paste") ; return }
        guard let text = UIPasteboard.general.string, !text.isEmpty else { showNotice("Clipboard is empty"); return }
        textDocumentProxy.insertText(text)
    }

    private func updateShiftAppearance() {
        shiftButton?.configuration?.title = isShifted ? "⇧" : "⇧"
        letterButtons.forEach { button in
            guard let title = button.configuration?.title else { return }
            button.configuration?.title = isShifted ? title.uppercased() : title.lowercased()
        }
    }

    private func showNotice(_ text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .caption1)
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            label.heightAnchor.constraint(equalToConstant: 28),
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { label.removeFromSuperview() }
    }
}
