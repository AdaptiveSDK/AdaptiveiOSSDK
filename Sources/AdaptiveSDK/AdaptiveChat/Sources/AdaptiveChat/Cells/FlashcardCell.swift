#if canImport(UIKit)
import UIKit

/// Displays a flashcard with progress counter, flip animation, and action buttons.
final class FlashcardCell: UITableViewCell {
    static let reuseId = "FlashcardCell"

    private let counterLabel = UILabel()
    private let knownLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let cardContainer = UIView()
    private let frontLabel = UILabel()
    private let flipHintLabel = UILabel()
    private let backLabel = UILabel()
    private let stillLearningButton = UIButton(type: .system)
    private let knowItButton = UIButton(type: .system)
    private let buttonRow = UIStackView()
    private let actionsBar = AIActionsBar()

    private var onFlip: (() -> Void)?
    private var onKnowIt: (() -> Void)?
    private var onStillLearning: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        contentView.addSubview(stack)

        // Counter row
        let counterRow = UIStackView()
        counterRow.axis = .horizontal
        counterLabel.font = .boldSystemFont(ofSize: 14)
        counterLabel.textColor = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1)
        knownLabel.font = .systemFont(ofSize: 14)
        knownLabel.textColor = UIColor(red: 15/255, green: 118/255, blue: 110/255, alpha: 1)
        knownLabel.textAlignment = .right
        counterRow.addArrangedSubview(counterLabel)
        counterRow.addArrangedSubview(knownLabel)
        stack.addArrangedSubview(counterRow)

        // Progress bar
        progressBar.layer.cornerRadius = 3
        progressBar.clipsToBounds = true
        progressBar.heightAnchor.constraint(equalToConstant: 6).isActive = true
        stack.addArrangedSubview(progressBar)

        // Card container
        cardContainer.layer.cornerRadius = 16
        cardContainer.layer.borderWidth = 4
        cardContainer.backgroundColor = .white
        cardContainer.heightAnchor.constraint(equalToConstant: 200).isActive = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardContainer.addGestureRecognizer(tapGesture)

        frontLabel.translatesAutoresizingMaskIntoConstraints = false
        frontLabel.font = .boldSystemFont(ofSize: 22)
        frontLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        frontLabel.textAlignment = .center
        frontLabel.numberOfLines = 0
        cardContainer.addSubview(frontLabel)

        flipHintLabel.translatesAutoresizingMaskIntoConstraints = false
        flipHintLabel.text = "↻ Tap to flip"
        flipHintLabel.font = .systemFont(ofSize: 13)
        flipHintLabel.textColor = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1)
        flipHintLabel.textAlignment = .center
        cardContainer.addSubview(flipHintLabel)

        backLabel.translatesAutoresizingMaskIntoConstraints = false
        backLabel.font = .systemFont(ofSize: 18)
        backLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        backLabel.textAlignment = .center
        backLabel.numberOfLines = 0
        backLabel.isHidden = true
        cardContainer.addSubview(backLabel)

        NSLayoutConstraint.activate([
            frontLabel.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            frontLabel.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor, constant: -12),
            frontLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 24),
            frontLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -24),
            flipHintLabel.topAnchor.constraint(equalTo: frontLabel.bottomAnchor, constant: 16),
            flipHintLabel.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            backLabel.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            backLabel.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            backLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 24),
            backLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -24),
        ])
        stack.addArrangedSubview(cardContainer)

        // Buttons row
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.distribution = .fillEqually

        stillLearningButton.setTitle("Still learning ↩", for: .normal)
        stillLearningButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        stillLearningButton.layer.cornerRadius = 24
        stillLearningButton.layer.borderWidth = 1.5
        stillLearningButton.layer.borderColor = UIColor(red: 209/255, green: 213/255, blue: 219/255, alpha: 1).cgColor
        stillLearningButton.setTitleColor(UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1), for: .normal)
        stillLearningButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stillLearningButton.addTarget(self, action: #selector(stillLearningTapped), for: .touchUpInside)

        knowItButton.setTitle("Know it ✓", for: .normal)
        knowItButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        knowItButton.layer.cornerRadius = 24
        knowItButton.setTitleColor(.white, for: .normal)
        knowItButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        knowItButton.addTarget(self, action: #selector(knowItTapped), for: .touchUpInside)

        buttonRow.addArrangedSubview(stillLearningButton)
        buttonRow.addArrangedSubview(knowItButton)
        stack.addArrangedSubview(buttonRow)

        actionsBar.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(actionsBar)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(with flashcard: Flashcard, currentIndex: Int, totalCards: Int, knownCount: Int, accentColor: UIColor, primaryColor: UIColor, onFlip: @escaping () -> Void, onKnowIt: @escaping () -> Void, onStillLearning: @escaping () -> Void) {
        self.onFlip = onFlip
        self.onKnowIt = onKnowIt
        self.onStillLearning = onStillLearning

        counterLabel.text = "\(currentIndex + 1) / \(totalCards)"
        knownLabel.text = "✓ \(knownCount) known"

        progressBar.progress = Float(knownCount) / Float(totalCards)
        progressBar.progressTintColor = accentColor
        progressBar.trackTintColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1)

        cardContainer.layer.borderColor = accentColor.cgColor
        knowItButton.backgroundColor = UIColor(red: 77/255, green: 182/255, blue: 160/255, alpha: 1)

        frontLabel.text = flashcard.front
        backLabel.text = flashcard.back

        if flashcard.isFlipped {
            frontLabel.isHidden = true
            flipHintLabel.isHidden = true
            backLabel.isHidden = false
            buttonRow.isHidden = false
        } else {
            frontLabel.isHidden = false
            flipHintLabel.isHidden = false
            backLabel.isHidden = true
            buttonRow.isHidden = true
        }

        if flashcard.isDone {
            contentView.alpha = 0.5
            cardContainer.isUserInteractionEnabled = false
        } else {
            contentView.alpha = 1.0
            cardContainer.isUserInteractionEnabled = true
        }

        actionsBar.onCopy = { UIPasteboard.general.string = "\(flashcard.front)\n\(flashcard.back)" }
    }

    @objc private func cardTapped() { onFlip?() }
    @objc private func knowItTapped() { onKnowIt?() }
    @objc private func stillLearningTapped() { onStillLearning?() }
}
#endif
