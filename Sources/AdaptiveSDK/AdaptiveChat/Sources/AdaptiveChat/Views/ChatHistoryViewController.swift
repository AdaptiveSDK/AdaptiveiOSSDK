#if canImport(UIKit)
import UIKit

/// Slide-over panel displaying chat session history — equivalent to Android's DrawerLayout.
final class ChatHistoryViewController: UIViewController {

    var onSessionSelected: ((ChatSession) -> Void)?
    var onNewChat: (() -> Void)?

    private var sessions: [ChatSession]
    private let tableView = UITableView()
    private let panelView = UIView()

    init(sessions: [ChatSession]) {
        self.sessions = sessions
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        setupPanel()

        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.25) {
            self.panelView.transform = .identity
        }
    }

    private func setupPanel() {
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.backgroundColor = .white
        panelView.layer.cornerRadius = 0
        panelView.transform = CGAffineTransform(translationX: -300, y: 0)
        view.addSubview(panelView)

        NSLayoutConstraint.activate([
            panelView.topAnchor.constraint(equalTo: view.topAnchor),
            panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panelView.widthAnchor.constraint(equalToConstant: 300),
        ])

        // Header
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(headerView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Chat History"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        headerView.addSubview(titleLabel)

        let newChatButton = UIButton(type: .system)
        newChatButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            newChatButton.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        }
        newChatButton.tintColor = UIColor(red: 15/255, green: 118/255, blue: 110/255, alpha: 1)
        newChatButton.addTarget(self, action: #selector(newChatTapped), for: .touchUpInside)
        headerView.addSubview(newChatButton)

        // Table
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatHistoryCell.self, forCellReuseIdentifier: ChatHistoryCell.reuseId)
        panelView.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: panelView.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            newChatButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            newChatButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            newChatButton.widthAnchor.constraint(equalToConstant: 36),
            newChatButton.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),
        ])
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        if !panelView.frame.contains(point) {
            dismissPanel()
        }
    }

    @objc private func newChatTapped() {
        dismissPanel {
            self.onNewChat?()
        }
    }

    private func dismissPanel(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.panelView.transform = CGAffineTransform(translationX: -300, y: 0)
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
}

// MARK: - UITableView

extension ChatHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatHistoryCell.reuseId, for: indexPath) as! ChatHistoryCell
        cell.configure(with: sessions[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = sessions[indexPath.row]
        dismissPanel {
            self.onSessionSelected?(session)
        }
    }
}

// MARK: - History Cell

final class ChatHistoryCell: UITableViewCell {
    static let reuseId = "ChatHistoryCell"

    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        contentView.addSubview(titleLabel)

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        previewLabel.numberOfLines = 2
        contentView.addSubview(previewLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            previewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with session: ChatSession) {
        titleLabel.text = session.title
        previewLabel.text = session.lastMessage

        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            timeLabel.text = formatter.localizedString(for: session.timestamp, relativeTo: Date())
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            timeLabel.text = formatter.string(from: session.timestamp)
        }

        if session.isActive {
            contentView.backgroundColor = UIColor(red: 15/255, green: 118/255, blue: 110/255, alpha: 0.08)
        } else {
            contentView.backgroundColor = .clear
        }
    }
}
#endif
