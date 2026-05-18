#if canImport(UIKit)
import UIKit

/// Displays a picture card grid survey.
final class SurveyPictureCardsCell: UITableViewCell {
    static let reuseId = "SurveyPictureCardsCell"

    private let questionLabel = UILabel()
    private let gridStack = UIStackView()
    private let actionsBar = AIActionsBar()
    private var onCardSelected: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.numberOfLines = 0
        questionLabel.font = .boldSystemFont(ofSize: 16)
        questionLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        contentView.addSubview(questionLabel)

        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 8
        contentView.addSubview(gridStack)

        actionsBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionsBar)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            gridStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 16),
            gridStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gridStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            actionsBar.topAnchor.constraint(equalTo: gridStack.bottomAnchor, constant: 8),
            actionsBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionsBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(with survey: SurveyPictureCards, primaryColor: UIColor, onSelected: @escaping (Int) -> Void) {
        self.onCardSelected = onSelected
        questionLabel.text = survey.question
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Create 2-column grid
        var rowStack: UIStackView?
        for (index, card) in survey.cards.enumerated() {
            if index % 2 == 0 {
                rowStack = UIStackView()
                rowStack!.axis = .horizontal
                rowStack!.spacing = 8
                rowStack!.distribution = .fillEqually
                gridStack.addArrangedSubview(rowStack!)
            }

            let cardView = createCardView(card: card, index: index, isSelected: survey.selectedIndex == index, primaryColor: primaryColor, isDisabled: survey.selectedIndex != nil)
            rowStack?.addArrangedSubview(cardView)
        }

        // If odd number of cards, add spacer
        if survey.cards.count % 2 != 0 {
            let spacer = UIView()
            rowStack?.addArrangedSubview(spacer)
        }

        actionsBar.onCopy = { UIPasteboard.general.string = survey.question }
    }

    private func createCardView(card: PictureCard, index: Int, isSelected: Bool, primaryColor: UIColor, isDisabled: Bool) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 12
        container.layer.borderWidth = isSelected ? 2.5 : 1.5
        container.layer.borderColor = isSelected ? primaryColor.cgColor : UIColor(red: 209/255, green: 213/255, blue: 219/255, alpha: 1).cgColor
        container.backgroundColor = isSelected ? primaryColor.withAlphaComponent(0.05) : .white

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = card.label
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = isSelected ? primaryColor : UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1)
        label.textAlignment = .center
        container.addSubview(label)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 80),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        if !isDisabled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
            container.tag = index
            container.addGestureRecognizer(tap)
            container.isUserInteractionEnabled = true
        } else {
            container.alpha = isSelected ? 1.0 : 0.5
        }

        return container
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        onCardSelected?(tag)
    }
}
#endif
