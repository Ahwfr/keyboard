import UIKit

final class SetupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        buildView()
    }

    private func buildView() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
        ])

        let icon = UIImageView(image: UIImage(systemName: "keyboard.fill"))
        icon.tintColor = .white
        icon.backgroundColor = .systemBlue
        icon.contentMode = .center
        icon.layer.cornerRadius = 18
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 72).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 72).isActive = true
        let title = label("Keyboard", style: .title1, weight: .bold, color: .label)
        let subtitle = label("A familiar iPhone keyboard with a number row and clipboard shortcut.", style: .body, weight: .regular, color: .secondaryLabel)
        let hero = UIStackView(arrangedSubviews: [icon, title, subtitle])
        hero.axis = .vertical
        hero.spacing = 10
        hero.alignment = .leading
        stack.addArrangedSubview(hero)
        stack.addArrangedSubview(card("Set up your keyboard", [
            "Open Keyboard Settings below.",
            "Tap Keyboards, then Add New Keyboard.",
            "Choose Keyboard and enable Full Access for clipboard paste.",
        ]))

        var config = UIButton.Configuration.filled()
        config.title = "Open Keyboard Settings"
        config.image = UIImage(systemName: "gearshape")
        config.imagePadding = 8
        config.cornerStyle = .large
        let settings = UIButton(configuration: config)
        settings.configuration?.baseBackgroundColor = .systemBlue
        settings.configuration?.baseForegroundColor = .white
        settings.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 17, weight: .semibold)
            return attributes
        }
        settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settings.heightAnchor.constraint(equalToConstant: 54).isActive = true
        stack.addArrangedSubview(settings)
        stack.addArrangedSubview(card("Privacy", [
            "Typing stays in the keyboard extension.",
            "Full Access is only used when you tap the clipboard button to paste.",
        ]))
    }

    private func label(_ text: String, style: UIFont.TextStyle, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func card(_ title: String, _ items: [String]) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 16
        let heading = label(title, style: .headline, weight: .semibold, color: .label)
        let body = label(items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n"), style: .subheadline, weight: .regular, color: .secondaryLabel)
        let stack = UIStackView(arrangedSubviews: [heading, body])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
        ])
        return container
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
