#if canImport(UIKit)
import UIKit

/// Main chat view controller — equivalent to Android's AdaptiveChatActivity.
/// Manages survey flow → free chat, with support for all interactive item types.
public final class AdaptiveChatViewController: UIViewController {

    var config: AdaptiveChatConfig = .default

    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.keyboardDismissMode = .interactive
        tv.allowsSelection = false
        return tv
    }()

    private lazy var inputContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()

    private lazy var inputField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Ask anything…"
        tf.font = .systemFont(ofSize: 14)
        tf.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        tf.backgroundColor = UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1)
        tf.layer.cornerRadius = 22
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 0))
        tf.rightViewMode = .always
        tf.isEnabled = false
        tf.alpha = 0.5
        return tf
    }()

    private lazy var attachmentButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "paperclip"), for: .normal)
        }
        btn.tintColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        return btn
    }()

    private lazy var recordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "mic"), for: .normal)
        }
        btn.tintColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        return btn
    }()

    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            btn.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        }
        btn.tintColor = config.primaryColor
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var toolbarView: ChatToolbarView = {
        let toolbar = ChatToolbarView(config: config)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.onHistoryTapped = { [weak self] in self?.showHistory() }
        toolbar.onCloseTapped = { [weak self] in self?.dismiss(animated: true) }
        return toolbar
    }()

    private lazy var subjectBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 224/255, green: 242/255, blue: 241/255, alpha: 1)
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(config.subject) · \(config.topic)"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = config.primaryColor
        v.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        return v
    }()

    // MARK: - State
    private var items: [ChatItem] = []
    private var currentFlashcardIndex = 0
    private var totalFlashcards = 0
    private var knownCount = 0
    private var flashcardDeck: [Flashcard] = []
    private var chatSessions: [ChatSession] = []

    private lazy var demoItems: [ChatItem] = [
        .textMessage(TextMessage(
            text: "Hi! 👋 I'm your AI learning coach. Here's a preview of all available interaction types.",
            isFromUser: false
        )),
        .textMessage(TextMessage(
            text: "Looks great! Show me everything.",
            isFromUser: true
        )),
        .surveyMCQ(SurveyMCQ(
            id: "q1",
            question: "How do you prefer to learn?",
            options: [
                "📖 Reading explanations",
                "🎥 Watching videos",
                "✍️ Practice problems",
                "🗣️ Discussing with someone"
            ]
        )),
        .surveyPictureCards(SurveyPictureCards(
            id: "q2",
            question: "What subject are you working on today?",
            cards: [
                PictureCard(imageUrl: "", label: "Math"),
                PictureCard(imageUrl: "", label: "Science"),
                PictureCard(imageUrl: "", label: "English"),
                PictureCard(imageUrl: "", label: "History")
            ]
        )),
        .quizTrueFalse(QuizTrueFalse(
            id: "tf1",
            statement: "A fraction with the same numerator and denominator always equals 1.",
            correctAnswer: true
        )),
        .flashcard(Flashcard(
            id: "fc1",
            front: "What is ¾ + ½?",
            back: "1¼ (or 5/4)"
        )),
        .stepByStep(StepByStep(
            id: "sbs1",
            title: "How to add ¾ + ½",
            steps: [
                "Find the LCD of 4 and 2 → LCD = 4",
                "Convert ½ to 2/4",
                "Add numerators: 3 + 2 = 5",
                "Write as 5/4",
                "Convert to mixed number: 1¼"
            ]
        ))
    ]

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = config.backgroundColor
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        registerCells()
        addCurrentSessionToHistory()
        startSurveyFlow()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(toolbarView)
        view.addSubview(subjectBar)
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(attachmentButton)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(recordButton)
        inputContainer.addSubview(sendButton)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1)
        view.addSubview(divider)

        NSLayoutConstraint.activate([
            // Toolbar
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 56),

            // Subject bar
            subjectBar.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            subjectBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subjectBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subjectBar.heightAnchor.constraint(equalToConstant: 40),

            // TableView
            tableView.topAnchor.constraint(equalTo: subjectBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: divider.topAnchor),

            // Divider
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            // Input container
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),

            // Attachment button
            attachmentButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            attachmentButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            attachmentButton.widthAnchor.constraint(equalToConstant: 36),
            attachmentButton.heightAnchor.constraint(equalToConstant: 36),

            // Input field
            inputField.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 6),
            inputField.trailingAnchor.constraint(equalTo: recordButton.leadingAnchor, constant: -6),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 44),

            // Record button
            recordButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -4),
            recordButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 36),
            recordButton.heightAnchor.constraint(equalToConstant: 36),

            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48),
        ])

        tableView.dataSource = self
        tableView.delegate = self
        inputField.delegate = self
    }

    private func registerCells() {
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: TextMessageCell.reuseId)
        tableView.register(SurveyMCQCell.self, forCellReuseIdentifier: SurveyMCQCell.reuseId)
        tableView.register(SurveyPictureCardsCell.self, forCellReuseIdentifier: SurveyPictureCardsCell.reuseId)
        tableView.register(QuizTrueFalseCell.self, forCellReuseIdentifier: QuizTrueFalseCell.reuseId)
        tableView.register(FlashcardCell.self, forCellReuseIdentifier: FlashcardCell.reuseId)
        tableView.register(StepByStepCell.self, forCellReuseIdentifier: StepByStepCell.reuseId)
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: TypingIndicatorCell.reuseId)
    }

    // MARK: - Survey Flow

    private func startSurveyFlow() {
        // Set up flashcard deck
        flashcardDeck = [
            Flashcard(id: "fc1", front: "What is ¾ + ½?", back: "1¼ (or 5/4)"),
            Flashcard(id: "fc2", front: "What is 2/3 + 1/6?", back: "5/6"),
            Flashcard(id: "fc3", front: "What is 1/2 × 3/4?", back: "3/8"),
            Flashcard(id: "fc4", front: "What is 5/8 − 1/4?", back: "3/8")
        ]
        totalFlashcards = flashcardDeck.count
        currentFlashcardIndex = 0
        knownCount = 0

        var delay: TimeInterval = 0.3
        for item in demoItems {
            let isUserMessage: Bool
            if case .textMessage(let msg) = item { isUserMessage = msg.isFromUser } else { isUserMessage = false }

            if isUserMessage {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.addItem(item)
                }
                delay += 0.4
            } else {
                let capturedDelay = delay
                DispatchQueue.main.asyncAfter(deadline: .now() + capturedDelay) { [weak self] in
                    self?.addItem(.typingIndicator)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + capturedDelay + 0.7) { [weak self] in
                    self?.removeLastItem()
                    self?.addItem(item)
                }
                delay += 1.3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.inputField.isEnabled = true
            self?.inputField.alpha = 1.0
            self?.inputField.placeholder = "Ask anything about your lesson…"
        }
    }

    // MARK: - User Actions

    @objc private func sendTapped() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        inputField.text = ""
        sendUserMessage(text)
    }

    private func sendUserMessage(_ text: String) {
        addItem(.textMessage(TextMessage(text: text, isFromUser: true)))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.addItem(.typingIndicator)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            self.removeLastItem()
            self.addItem(.textMessage(TextMessage(
                text: "I'm still being connected to an AI backend. This is a placeholder response!",
                isFromUser: false
            )))
        }
    }

    // MARK: - Item Management

    private func addItem(_ item: ChatItem) {
        items.append(item)
        let indexPath = IndexPath(row: items.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func removeLastItem() {
        guard !items.isEmpty else { return }
        items.removeLast()
        let indexPath = IndexPath(row: items.count, section: 0)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    private func updateItem(at index: Int, with item: ChatItem) {
        items[index] = item
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }

    private func findIndex(byId id: String) -> Int? {
        return items.firstIndex(where: { $0.id == id })
    }

    // MARK: - Callback Handlers

    func onSurveyOptionSelected(itemId: String, optionIndex: Int) {
        guard let index = findIndex(byId: itemId) else { return }
        switch items[index] {
        case .surveyMCQ(var survey):
            survey.selectedIndex = optionIndex
            updateItem(at: index, with: .surveyMCQ(survey))
        case .surveyPictureCards(var survey):
            survey.selectedIndex = optionIndex
            updateItem(at: index, with: .surveyPictureCards(survey))
        default: break
        }
    }

    func onTrueFalseAnswered(itemId: String, answer: Bool) {
        guard let index = findIndex(byId: itemId),
              case .quizTrueFalse(var tf) = items[index] else { return }
        tf.userAnswer = answer
        updateItem(at: index, with: .quizTrueFalse(tf))
    }

    func onFlashcardFlipped(itemId: String) {
        guard let index = findIndex(byId: itemId),
              case .flashcard(var fc) = items[index] else { return }
        fc.isFlipped.toggle()
        updateItem(at: index, with: .flashcard(fc))
    }

    func onFlashcardAction(itemId: String, knowsIt: Bool) {
        if knowsIt { knownCount += 1 }
        currentFlashcardIndex += 1

        guard let index = findIndex(byId: itemId) else { return }

        if currentFlashcardIndex < totalFlashcards {
            let nextCard = flashcardDeck[currentFlashcardIndex]
            updateItem(at: index, with: .flashcard(nextCard))
        } else {
            // Update card with final counts + isDone
            var lastCard = flashcardDeck[totalFlashcards - 1]
            lastCard.isFlipped = false
            lastCard.isDone = true
            currentFlashcardIndex = totalFlashcards - 1
            updateItem(at: index, with: .flashcard(lastCard))

            addItem(.textMessage(TextMessage(
                text: "Great work! You knew \(knownCount) out of \(totalFlashcards) cards. 🎉",
                isFromUser: false
            )))
        }
    }

    func onNextStepClicked(itemId: String) {
        guard let index = findIndex(byId: itemId),
              case .stepByStep(var sbs) = items[index] else { return }
        if sbs.currentStep < sbs.steps.count - 1 {
            sbs.currentStep += 1
            updateItem(at: index, with: .stepByStep(sbs))
        }
    }

    func onActionChipClicked(itemId: String, action: String) {
        switch action {
        case "quiz": sendUserMessage("Quiz me on this")
        case "retry": sendUserMessage("Try another way")
        default: break
        }
    }

    // MARK: - Chat History

    private func showHistory() {
        let historyVC = ChatHistoryViewController(sessions: chatSessions)
        historyVC.onSessionSelected = { [weak self] session in
            self?.onHistorySessionSelected(session)
        }
        historyVC.onNewChat = { [weak self] in
            self?.startNewChat()
        }
        historyVC.modalPresentationStyle = .overCurrentContext
        historyVC.modalTransitionStyle = .crossDissolve
        present(historyVC, animated: true)
    }

    private func addCurrentSessionToHistory() {
        let session = ChatSession(
            title: "\(config.subject) · \(config.topic)",
            lastMessage: "AI Coach session started",
            isActive: true
        )
        chatSessions.insert(session, at: 0)
    }

    private func onHistorySessionSelected(_ session: ChatSession) {
        for i in chatSessions.indices {
            chatSessions[i].isActive = (chatSessions[i].id == session.id)
        }
        // TODO: Load messages for the selected session from persistence
    }

    private func startNewChat() {
        for i in chatSessions.indices {
            chatSessions[i].isActive = false
        }
        let newSession = ChatSession(title: "New Conversation", lastMessage: "", isActive: true)
        chatSessions.insert(newSession, at: 0)

        items.removeAll()
        tableView.reloadData()
        currentFlashcardIndex = 0
        totalFlashcards = 0
        knownCount = 0
        flashcardDeck.removeAll()
        inputField.isEnabled = false
        inputField.alpha = 0.5
        inputField.placeholder = "Ask anything…"

        startSurveyFlow()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension AdaptiveChatViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        switch item {
        case .textMessage(let msg):
            let cell = tableView.dequeueReusableCell(withIdentifier: TextMessageCell.reuseId, for: indexPath) as! TextMessageCell
            cell.configure(with: msg, primaryColor: config.primaryColor) { [weak self] itemId, action in
                self?.onActionChipClicked(itemId: itemId, action: action)
            }
            return cell

        case .surveyMCQ(let survey):
            let cell = tableView.dequeueReusableCell(withIdentifier: SurveyMCQCell.reuseId, for: indexPath) as! SurveyMCQCell
            cell.configure(with: survey, primaryColor: config.primaryColor) { [weak self] index in
                self?.onSurveyOptionSelected(itemId: survey.id, optionIndex: index)
            }
            return cell

        case .surveyPictureCards(let survey):
            let cell = tableView.dequeueReusableCell(withIdentifier: SurveyPictureCardsCell.reuseId, for: indexPath) as! SurveyPictureCardsCell
            cell.configure(with: survey, primaryColor: config.primaryColor) { [weak self] index in
                self?.onSurveyOptionSelected(itemId: survey.id, optionIndex: index)
            }
            return cell

        case .quizTrueFalse(let quiz):
            let cell = tableView.dequeueReusableCell(withIdentifier: QuizTrueFalseCell.reuseId, for: indexPath) as! QuizTrueFalseCell
            cell.configure(with: quiz, primaryColor: config.primaryColor) { [weak self] answer in
                self?.onTrueFalseAnswered(itemId: quiz.id, answer: answer)
            }
            return cell

        case .flashcard(let fc):
            let cell = tableView.dequeueReusableCell(withIdentifier: FlashcardCell.reuseId, for: indexPath) as! FlashcardCell
            cell.configure(
                with: fc,
                currentIndex: currentFlashcardIndex,
                totalCards: max(totalFlashcards, 1),
                knownCount: knownCount,
                accentColor: config.accentColor,
                primaryColor: config.primaryColor,
                onFlip: { [weak self] in self?.onFlashcardFlipped(itemId: fc.id) },
                onKnowIt: { [weak self] in self?.onFlashcardAction(itemId: fc.id, knowsIt: true) },
                onStillLearning: { [weak self] in self?.onFlashcardAction(itemId: fc.id, knowsIt: false) }
            )
            return cell

        case .stepByStep(let sbs):
            let cell = tableView.dequeueReusableCell(withIdentifier: StepByStepCell.reuseId, for: indexPath) as! StepByStepCell
            cell.configure(
                with: sbs,
                primaryColor: config.primaryColor,
                onDotTapped: { [weak self] stepIndex in
                    guard let self = self, let idx = self.findIndex(byId: sbs.id),
                          case .stepByStep(var s) = self.items[idx] else { return }
                    s.currentStep = stepIndex
                    self.updateItem(at: idx, with: .stepByStep(s))
                },
                onChipTapped: { [weak self] action in
                    self?.onActionChipClicked(itemId: sbs.id, action: action)
                }
            )
            return cell

        case .typingIndicator:
            let cell = tableView.dequeueReusableCell(withIdentifier: TypingIndicatorCell.reuseId, for: indexPath) as! TypingIndicatorCell
            cell.startAnimating()
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITextFieldDelegate

extension AdaptiveChatViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}
#endif
