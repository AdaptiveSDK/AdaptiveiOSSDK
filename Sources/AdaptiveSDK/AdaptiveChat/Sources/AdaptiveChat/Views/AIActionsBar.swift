#if canImport(UIKit)
import UIKit

/// Reusable action bar (like, dislike, copy, retry) for AI message cells.
final class AIActionsBar: UIStackView {

    var onLike: (() -> Void)?
    var onDislike: (() -> Void)?
    var onCopy: (() -> Void)?
    var onRetry: (() -> Void)?

    private let likeButton = UIButton(type: .system)
    private let dislikeButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let retryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) { fatalError() }

    private func setup() {
        axis = .horizontal
        spacing = 24
        alignment = .center
        distribution = .fill

        let iconColor = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1)
        let iconSize: CGFloat = 16

        configureButton(likeButton, systemName: "hand.thumbsup", color: iconColor, size: iconSize, action: #selector(likeTapped))
        configureButton(dislikeButton, systemName: "hand.thumbsdown", color: iconColor, size: iconSize, action: #selector(dislikeTapped))
        configureButton(copyButton, systemName: "doc.on.doc", color: iconColor, size: iconSize, action: #selector(copyTapped))
        configureButton(retryButton, systemName: "arrow.counterclockwise", color: iconColor, size: iconSize, action: #selector(retryTapped))

        addArrangedSubview(likeButton)
        addArrangedSubview(dislikeButton)
        addArrangedSubview(copyButton)
        addArrangedSubview(retryButton)

        // Spacer pushes buttons to the left, preventing retry from drifting away
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addArrangedSubview(spacer)
    }

    private func configureButton(_ button: UIButton, systemName: String, color: UIColor, size: CGFloat, action: Selector) {
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
            button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        }
        button.tintColor = color
        button.widthAnchor.constraint(equalToConstant: size + 8).isActive = true
        button.heightAnchor.constraint(equalToConstant: size + 8).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    @objc private func likeTapped() { onLike?() }
    @objc private func dislikeTapped() { onDislike?() }
    @objc private func copyTapped() { onCopy?() }
    @objc private func retryTapped() { onRetry?() }
}
#endif
