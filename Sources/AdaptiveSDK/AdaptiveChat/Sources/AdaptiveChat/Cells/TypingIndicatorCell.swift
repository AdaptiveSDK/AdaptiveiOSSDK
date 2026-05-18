#if canImport(UIKit)
import UIKit

/// Displays an animated typing indicator (three bouncing dots).
final class TypingIndicatorCell: UITableViewCell {
    static let reuseId = "TypingIndicatorCell"

    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    private let bubbleView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.backgroundColor = UIColor(red: 224/255, green: 242/255, blue: 241/255, alpha: 1)
        bubbleView.layer.cornerRadius = 16
        contentView.addSubview(bubbleView)

        let dotsStack = UIStackView(arrangedSubviews: [dot1, dot2, dot3])
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        dotsStack.axis = .horizontal
        dotsStack.spacing = 6
        dotsStack.alignment = .center
        bubbleView.addSubview(dotsStack)

        [dot1, dot2, dot3].forEach { dot in
            dot.backgroundColor = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1)
            dot.layer.cornerRadius = 4
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        }

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(equalToConstant: 70),
            bubbleView.heightAnchor.constraint(equalToConstant: 40),

            dotsStack.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            dotsStack.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
        ])
    }

    func startAnimating() {
        let dots = [dot1, dot2, dot3]
        for (i, dot) in dots.enumerated() {
            dot.layer.removeAllAnimations()
            UIView.animate(
                withDuration: 0.4,
                delay: Double(i) * 0.15,
                options: [.repeat, .autoreverse],
                animations: { dot.transform = CGAffineTransform(translationX: 0, y: -4) },
                completion: nil
            )
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        [dot1, dot2, dot3].forEach { $0.layer.removeAllAnimations(); $0.transform = .identity }
    }
}
#endif
