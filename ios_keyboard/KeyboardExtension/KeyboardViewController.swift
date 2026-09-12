import UIKit

final class KeyboardViewController: UIInputViewController {

    private var isShifted = false
    private let stackContainer = UIStackView()
    private var letterButtons: [UIButton] = []
    private var shiftButton: UIButton!

    private let letterRows: [[String]] = [
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        for row in letterRows {
            stackContainer.addArrangedSubview(makeRow(titles: row, isLetterRow: true))
        }
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

        let globe = UIButton(type: .system)
        globe.setTitle("🌐", for: .normal)
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        let shift = UIButton(type: .system)
        shift.setTitle("⇧", for: .normal)
        shift.addTarget(self, action: #selector(shiftTapped), for: .touchUpInside)
        shiftButton = shift

        let space = UIButton(type: .system)
        space.setTitle("space", for: .normal)
        space.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)

        let backspace = UIButton(type: .system)
        backspace.setTitle("⌫", for: .normal)
        backspace.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)

        let returnKey = UIButton(type: .system)
        returnKey.setTitle("return", for: .normal)
        returnKey.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)

        let paste = UIButton(type: .system)
        paste.setTitle("Paste", for: .normal)
        paste.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)

        [globe, shift, space, backspace, returnKey, paste].forEach { row.addArrangedSubview($0) }
        return row
    }

    @objc private func letterKeyTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(isShifted ? title.uppercased() : title)
        if isShifted {
            isShifted = false
            updateShiftAppearance()
        }
    }

    @objc private func shiftTapped() {
        isShifted.toggle()
        updateShiftAppearance()
    }

    private func updateShiftAppearance() {
        shiftButton.backgroundColor = isShifted ? .systemBlue : .clear
        for button in letterButtons {
            guard let title = button.title(for: .normal) else { continue }
            button.setTitle(isShifted ? title.uppercased() : title.lowercased(), for: .normal)
        }
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
    }

    @objc private func pasteTapped() {
        guard hasFullAccess else {
            showTemporaryMessage("Enable Full Access in Settings to paste")
            return
        }
        if let text = UIPasteboard.general.string, !text.isEmpty {
            textDocumentProxy.insertText(text)
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak label] in
            label?.removeFromSuperview()
        }
    }
}
