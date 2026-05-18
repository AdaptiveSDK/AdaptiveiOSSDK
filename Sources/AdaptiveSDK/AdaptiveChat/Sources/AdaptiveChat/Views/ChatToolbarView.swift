#if canImport(UIKit)
import UIKit

/// Custom toolbar matching the Android chat toolbar.
final class ChatToolbarView: UIView {

    var onHistoryTapped: (() -> Void)?
    var onCloseTapped: (() -> Void)?

    private let config: AdaptiveChatConfig

    init(config: AdaptiveChatConfig) {
        self.config = config
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = .white

        // AI logo placeholder
        let logoView = UIView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.backgroundColor = config.primaryColor
        logoView.layer.cornerRadius = 18
        addSubview(logoView)

        // Title stack
        let titleLabel = UILabel()
        titleLabel.text = "AI Coach"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)

        let onlineDot = UIView()
        onlineDot.backgroundColor = config.primaryColor
        onlineDot.layer.cornerRadius = 4
        onlineDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        onlineDot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let onlineLabel = UILabel()
        onlineLabel.text = "Online"
        onlineLabel.font = .systemFont(ofSize: 12)
        onlineLabel.textColor = config.primaryColor

        let statusStack = UIStackView(arrangedSubviews: [onlineDot, onlineLabel])
        statusStack.axis = .horizontal
        statusStack.spacing = 4

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, statusStack])
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.axis = .vertical
        titleStack.spacing = 2
        addSubview(titleStack)

        // Action buttons
        let historyButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        }
        historyButton.tintColor = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1)
        historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)

        let closeButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        }
        closeButton.tintColor = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let actionsStack = UIStackView(arrangedSubviews: [historyButton, closeButton])
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.axis = .horizontal
        actionsStack.spacing = 8
        addSubview(actionsStack)

        NSLayoutConstraint.activate([
            logoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 36),
            logoView.heightAnchor.constraint(equalToConstant: 36),

            titleStack.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 10),
            titleStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            actionsStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            historyButton.widthAnchor.constraint(equalToConstant: 36),
            historyButton.heightAnchor.constraint(equalToConstant: 36),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])

        // Bottom border
        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.backgroundColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1)
        addSubview(border)
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    @objc private func historyTapped() { onHistoryTapped?() }
    @objc private func closeTapped() { onCloseTapped?() }
}
#endif
