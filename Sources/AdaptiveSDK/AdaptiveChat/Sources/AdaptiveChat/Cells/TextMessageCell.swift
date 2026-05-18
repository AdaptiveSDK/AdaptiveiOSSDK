#if canImport(UIKit)
import UIKit

/// Displays a sent or received text message bubble.
final class TextMessageCell: UITableViewCell {
    static let reuseId = "TextMessageCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let actionsBar = AIActionsBar()

    var onActionChipClicked: ((String, String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    private func setupViews() {
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        contentView.addSubview(bubbleView)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 15)
        bubbleView.addSubview(messageLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1)
        contentView.addSubview(timeLabel)

        actionsBar.translatesAutoresizingMaskIntoConstraints = false
        actionsBar.isHidden = true
        contentView.addSubview(actionsBar)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),

            actionsBar.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
            actionsBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionsBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])
    }

    func configure(with message: TextMessage, primaryColor: UIColor, onActionChip: ((String, String) -> Void)? = nil) {
        self.onActionChipClicked = onActionChip
        messageLabel.text = message.text

        // Deactivate both before setting
        leadingConstraint.isActive = false
        trailingConstraint.isActive = false

        if message.isFromUser {
            trailingConstraint.isActive = true
            bubbleView.backgroundColor = primaryColor
            messageLabel.textColor = .white
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
            actionsBar.isHidden = true
        } else {
            leadingConstraint.isActive = true
            bubbleView.backgroundColor = UIColor(red: 224/255, green: 242/255, blue: 241/255, alpha: 1)
            messageLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
            actionsBar.isHidden = false
            actionsBar.onLike = { [weak self] in self?.onActionChipClicked?(message.id, "like") }
            actionsBar.onDislike = { [weak self] in self?.onActionChipClicked?(message.id, "dislike") }
            actionsBar.onCopy = { UIPasteboard.general.string = message.text }
            actionsBar.onRetry = { [weak self] in self?.onActionChipClicked?(message.id, "retry") }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        timeLabel.text = formatter.string(from: message.timestamp)
    }
}
#endif
