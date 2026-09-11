import UIKit

final class SetupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildView()
    }

    private func buildView() {
        let title = UILabel()
        title.text = "Keyboard"
        title.font = .systemFont(ofSize: 36, weight: .bold)
        title.textColor = .label

        let subtitle = UILabel()
        subtitle.text = "Your custom keyboard is ready to enable."
        subtitle.font = .systemFont(ofSize: 18, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0

        let steps = UILabel()
        steps.text = "1. Tap Open Keyboard Settings\n2. Choose Keyboards\n3. Tap Add New Keyboard\n4. Select Keyboard\n5. Allow Full Access for clipboard features"
        steps.font = .systemFont(ofSize: 17, weight: .regular)
        steps.textColor = .label
        steps.numberOfLines = 0

        let settings = UIButton(type: .system)
        settings.setTitle("Open Keyboard Settings", for: .normal)
        settings.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        settings.configuration = .filled()
        settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, subtitle, steps, settings])
        stack.axis = .vertical
        stack.spacing = 22
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            settings.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
