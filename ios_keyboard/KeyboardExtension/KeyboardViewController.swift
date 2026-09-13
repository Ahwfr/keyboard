import UIKit

final class KeyboardViewController: UIInputViewController {
    private var isShifted = false
    private let stackContainer = UIStackView()
    private var letterButtons: [UIButton] = []
    private var shiftButton: UIButton!
    private let letterRows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]
    private let numberRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        buildLayout()
        updateShiftAppearance()
    }

    private func buildLayout() {
        stackContainer.axis = .vertical
        stackContainer.distribution = .fillEqually
        stackContainer.spacing = 6
        stackContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackContainer)
        NSLayoutConstraint.activate([
            stackContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stackContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            stackContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            stackContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
        ])
        view.heightAnchor.constraint(equalToConstant: 260).isActive = true
        stackContainer.addArrangedSubview(makeRow(titles: numberRow, isLetterRow: false))
        letterRows.forEach { stackContainer.addArrangedSubview(makeRow(titles: $0, isLetterRow: true)) }
        stackContainer.addArrangedSubview(makeBottomRow())
    }

    private func makeRow(titles: [String], isLetterRow: Bool) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillEqually
        for title in titles {
            let button = makeKeyButton(title: title)
            if isLetterRow { letterButtons.append(button) }
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(letterKeyTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeBottomRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillProportionally
        let globe = makeButton("🌐", action: #selector(handleInputModeList(from:with:)), events: .allTouchEvents)
        let shift = makeButton("⇧", action: #selector(shiftTapped))
        shiftButton = shift
        let space = makeButton("space", action: #selector(spaceTapped))
        let backspace = makeButton("⌫", action: #selector(backspaceTapped))
        let returnKey = makeButton("return", action: #selector(returnTapped))
        let paste = makeButton("Paste", action: #selector(pasteTapped))
        [globe, shift, space, backspace, returnKey, paste].forEach(row.addArrangedSubview)
        return row
    }

    private func makeButton(_ title: String, action: Selector, events: UIControl.Event = .touchUpInside) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: events)
        return button
    }

    @objc private func letterKeyTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(isShifted ? title.uppercased() : title)
        if isShifted { isShifted = false; updateShiftAppearance() }
    }

    @objc private func shiftTapped() { isShifted.toggle(); updateShiftAppearance() }

    private func updateShiftAppearance() {
        shiftButton.backgroundColor = isShifted ? .systemBlue : .clear
        letterButtons.forEach { button in
            guard let title = button.title(for: .normal) else { return }
            button.setTitle(isShifted ? title.uppercased() : title.lowercased(), for: .normal)
        }
    }

    @objc private func spaceTapped() { textDocumentProxy.insertText(" ") }
    @objc private func backspaceTapped() { textDocumentProxy.deleteBackward() }
    @objc private func returnTapped() { textDocumentProxy.insertText("\n") }

    @objc private func pasteTapped() {
        guard hasFullAccess else { showTemporaryMessage("Enable Full Access in Settings to paste"); return }
        if let text = UIPasteboard.general.string, !text.isEmpty { textDocumentProxy.insertText(text) }
    }

    private func showTemporaryMessage(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak label] in label?.removeFromSuperview() }
    }
}
