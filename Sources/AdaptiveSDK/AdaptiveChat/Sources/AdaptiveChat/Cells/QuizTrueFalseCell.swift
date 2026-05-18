#if canImport(UIKit)
import UIKit

/// Displays a True/False quiz with pill-shaped buttons.
final class QuizTrueFalseCell: UITableViewCell {
    static let reuseId = "QuizTrueFalseCell"

    private let statementLabel = UILabel()
    private let instructionLabel = UILabel()
    private let trueButton = UIButton(type: .system)
    private let falseButton = UIButton(type: .system)
    private let actionsBar = AIActionsBar()
    private var onAnswered: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        statementLabel.translatesAutoresizingMaskIntoConstraints = false
        statementLabel.numberOfLines = 0
        statementLabel.font = .boldSystemFont(ofSize: 18)
        statementLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        statementLabel.textAlignment = .center
        contentView.addSubview(statementLabel)

        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.text = "Is this statement true or false?"
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        instructionLabel.textAlignment = .center
        contentView.addSubview(instructionLabel)

        configureButton(trueButton, title: "True ✓", tag: 1)
        configureButton(falseButton, title: "False ✗", tag: 0)

        contentView.addSubview(trueButton)
        contentView.addSubview(falseButton)

        actionsBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionsBar)

        trueButton.translatesAutoresizingMaskIntoConstraints = false
        falseButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statementLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statementLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            statementLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            instructionLabel.topAnchor.constraint(equalTo: statementLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            trueButton.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            trueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            trueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            trueButton.heightAnchor.constraint(equalToConstant: 56),

            falseButton.topAnchor.constraint(equalTo: trueButton.bottomAnchor, constant: 12),
            falseButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            falseButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            falseButton.heightAnchor.constraint(equalToConstant: 56),

            actionsBar.topAnchor.constraint(equalTo: falseButton.bottomAnchor, constant: 8),
            actionsBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionsBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    private func configureButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.layer.cornerRadius = 28
        button.layer.borderWidth = 2
        button.tag = tag
        button.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
    }

    func configure(with quiz: QuizTrueFalse, primaryColor: UIColor, onAnswered: @escaping (Bool) -> Void) {
        self.onAnswered = onAnswered
        statementLabel.text = "\"\(quiz.statement)\""

        let tealColor = primaryColor
        let redColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)

        if let userAnswer = quiz.userAnswer {
            // Show feedback
            trueButton.isUserInteractionEnabled = false
            falseButton.isUserInteractionEnabled = false

            let isCorrect = userAnswer == quiz.correctAnswer
            if userAnswer {
                trueButton.layer.borderColor = tealColor.cgColor
                trueButton.backgroundColor = UIColor(red: 236/255, green: 253/255, blue: 245/255, alpha: 1)
                trueButton.setTitleColor(tealColor, for: .normal)
                falseButton.alpha = 0.4
                falseButton.layer.borderColor = redColor.cgColor
                falseButton.setTitleColor(redColor, for: .normal)
            } else {
                falseButton.layer.borderColor = redColor.cgColor
                falseButton.backgroundColor = UIColor(red: 254/255, green: 242/255, blue: 242/255, alpha: 1)
                falseButton.setTitleColor(redColor, for: .normal)
                trueButton.alpha = 0.4
                trueButton.layer.borderColor = tealColor.cgColor
                trueButton.setTitleColor(tealColor, for: .normal)
            }
        } else {
            // Default state
            trueButton.layer.borderColor = tealColor.cgColor
            trueButton.setTitleColor(tealColor, for: .normal)
            trueButton.backgroundColor = .white
            trueButton.alpha = 1.0
            trueButton.isUserInteractionEnabled = true

            falseButton.layer.borderColor = redColor.cgColor
            falseButton.setTitleColor(redColor, for: .normal)
            falseButton.backgroundColor = .white
            falseButton.alpha = 1.0
            falseButton.isUserInteractionEnabled = true
        }

        actionsBar.onCopy = { UIPasteboard.general.string = quiz.statement }
    }

    @objc private func answerTapped(_ sender: UIButton) {
        onAnswered?(sender.tag == 1)
    }
}
#endif
