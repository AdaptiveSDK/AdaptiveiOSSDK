#if canImport(UIKit)
import UIKit

/// Displays a multiple-choice survey question with selectable options.
final class SurveyMCQCell: UITableViewCell {
    static let reuseId = "SurveyMCQCell"

    private let questionLabel = UILabel()
    private let optionsStack = UIStackView()
    private let actionsBar = AIActionsBar()
    private var onOptionSelected: ((Int) -> Void)?

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

        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        optionsStack.axis = .vertical
        optionsStack.spacing = 10
        contentView.addSubview(optionsStack)

        actionsBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionsBar)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            optionsStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 16),
            optionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            optionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            actionsBar.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 8),
            actionsBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionsBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(with survey: SurveyMCQ, primaryColor: UIColor, onSelected: @escaping (Int) -> Void) {
        self.onOptionSelected = onSelected
        questionLabel.text = survey.question
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, option) in survey.options.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(option, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15)
            btn.contentHorizontalAlignment = .leading
            btn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 1.5
            btn.tag = index

            if survey.selectedIndex == index {
                btn.layer.borderColor = primaryColor.cgColor
                btn.backgroundColor = primaryColor.withAlphaComponent(0.08)
                btn.setTitleColor(primaryColor, for: .normal)
            } else {
                btn.layer.borderColor = UIColor(red: 209/255, green: 213/255, blue: 219/255, alpha: 1).cgColor
                btn.backgroundColor = .white
                btn.setTitleColor(UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1), for: .normal)
            }

            if survey.selectedIndex != nil {
                btn.isUserInteractionEnabled = false
                btn.alpha = (survey.selectedIndex == index) ? 1.0 : 0.5
            } else {
                btn.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            }

            optionsStack.addArrangedSubview(btn)
        }

        actionsBar.onCopy = { UIPasteboard.general.string = survey.question }
    }

    @objc private func optionTapped(_ sender: UIButton) {
        onOptionSelected?(sender.tag)
    }
}
#endif
