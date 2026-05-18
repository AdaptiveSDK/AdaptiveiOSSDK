#if canImport(UIKit)
import UIKit

/// Displays a step-by-step explanation card with dot progress and action chips.
final class StepByStepCell: UITableViewCell {
    static let reuseId = "StepByStepCell"

    private let titleLabel = UILabel()
    private let stepCounterLabel = UILabel()
    private let dotsStack = UIStackView()
    private let contentArea = UIView()
    private let stepContentLabel = UILabel()
    private let followUpLabel = UILabel()
    private let chipsStack = UIStackView()
    private let actionsBar = AIActionsBar()

    private var onDotTapped: ((Int) -> Void)?
    private var onChipTapped: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1).cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        contentView.addSubview(card)

        // Header row
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        stepCounterLabel.font = .boldSystemFont(ofSize: 13)
        stepCounterLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(titleLabel)
        card.addSubview(stepCounterLabel)

        // Dots
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        dotsStack.axis = .horizontal
        dotsStack.spacing = 6
        card.addSubview(dotsStack)

        // Content area
        contentArea.translatesAutoresizingMaskIntoConstraints = false
        contentArea.backgroundColor = UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1)
        contentArea.layer.cornerRadius = 12
        card.addSubview(contentArea)

        stepContentLabel.translatesAutoresizingMaskIntoConstraints = false
        stepContentLabel.numberOfLines = 0
        stepContentLabel.font = .systemFont(ofSize: 15)
        stepContentLabel.textColor = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1)
        stepContentLabel.textAlignment = .center
        contentArea.addSubview(stepContentLabel)

        // Follow-up + chips below card
        followUpLabel.numberOfLines = 0
        followUpLabel.font = .systemFont(ofSize: 15)
        followUpLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        followUpLabel.backgroundColor = UIColor(red: 224/255, green: 242/255, blue: 241/255, alpha: 1)
        followUpLabel.layer.cornerRadius = 16
        followUpLabel.layer.masksToBounds = true
        followUpLabel.isHidden = true

        chipsStack.axis = .horizontal
        chipsStack.spacing = 12
        chipsStack.distribution = .fillEqually
        chipsStack.isHidden = true
        chipsStack.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Wrapping in a vertical stack so hidden views collapse, preventing
        // the actionsBar from being pushed down when followUpLabel/chipsStack are hidden
        let belowCardStack = UIStackView(arrangedSubviews: [followUpLabel, chipsStack, actionsBar])
        belowCardStack.translatesAutoresizingMaskIntoConstraints = false
        belowCardStack.axis = .vertical
        belowCardStack.spacing = 10
        contentView.addSubview(belowCardStack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: stepCounterLabel.leadingAnchor, constant: -8),

            stepCounterLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            stepCounterLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            dotsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dotsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            contentArea.topAnchor.constraint(equalTo: dotsStack.bottomAnchor, constant: 12),
            contentArea.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentArea.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentArea.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            contentArea.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),

            stepContentLabel.topAnchor.constraint(equalTo: contentArea.topAnchor, constant: 20),
            stepContentLabel.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor, constant: 20),
            stepContentLabel.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor, constant: -20),
            stepContentLabel.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor, constant: -20),

            belowCardStack.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 8),
            belowCardStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            belowCardStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            belowCardStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(with sbs: StepByStep, primaryColor: UIColor, onDotTapped: @escaping (Int) -> Void, onChipTapped: @escaping (String) -> Void) {
        self.onDotTapped = onDotTapped
        self.onChipTapped = onChipTapped

        titleLabel.text = sbs.title
        stepCounterLabel.text = "Step \(sbs.currentStep + 1) of \(sbs.steps.count)"
        stepCounterLabel.textColor = primaryColor

        // Setup dots
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in sbs.steps.indices {
            let dot = UIView()
            let size: CGFloat = (i == sbs.currentStep) ? 12 : 8
            dot.widthAnchor.constraint(equalToConstant: size).isActive = true
            dot.heightAnchor.constraint(equalToConstant: size).isActive = true
            dot.layer.cornerRadius = size / 2
            dot.backgroundColor = (i <= sbs.currentStep) ? primaryColor : UIColor(red: 209/255, green: 213/255, blue: 219/255, alpha: 1)
            dot.tag = i
            let tap = UITapGestureRecognizer(target: self, action: #selector(dotTapped(_:)))
            dot.addGestureRecognizer(tap)
            dot.isUserInteractionEnabled = true
            dotsStack.addArrangedSubview(dot)
        }

        stepContentLabel.text = sbs.steps[sbs.currentStep]

        // Show follow-up + chips on last step
        let isLastStep = sbs.currentStep >= sbs.steps.count - 1
        followUpLabel.isHidden = !isLastStep
        chipsStack.isHidden = !isLastStep

        if isLastStep {
            followUpLabel.text = "  Makes sense? Let me know if you want to try a different approach.  "
            setupChips(primaryColor: primaryColor)
        }

        actionsBar.onCopy = { UIPasteboard.general.string = sbs.steps[sbs.currentStep] }
    }

    private func setupChips(primaryColor: UIColor) {
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let quizChip = makeChip(title: "🎯 Quiz me on this", primaryColor: primaryColor, action: "quiz")
        let retryChip = makeChip(title: "🔄 Try another way", primaryColor: primaryColor, action: "retry")
        chipsStack.addArrangedSubview(quizChip)
        chipsStack.addArrangedSubview(retryChip)
    }

    private func makeChip(title: String, primaryColor: UIColor, action: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 13)
        btn.setTitleColor(primaryColor, for: .normal)
        btn.layer.cornerRadius = 20
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = primaryColor.cgColor
        btn.backgroundColor = .white
        btn.accessibilityIdentifier = action
        btn.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func dotTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        onDotTapped?(tag)
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard let action = sender.accessibilityIdentifier else { return }
        onChipTapped?(action)
    }
}
#endif
