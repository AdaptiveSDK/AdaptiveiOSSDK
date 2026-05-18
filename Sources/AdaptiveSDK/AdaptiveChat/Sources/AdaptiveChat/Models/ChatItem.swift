import Foundation

/// All possible items in the chat feed — mirrors Android's sealed class ChatItem.
public enum ChatItem: Identifiable {
    case textMessage(TextMessage)
    case surveyMCQ(SurveyMCQ)
    case surveyPictureCards(SurveyPictureCards)
    case quizTrueFalse(QuizTrueFalse)
    case flashcard(Flashcard)
    case stepByStep(StepByStep)
    case typingIndicator

    public var id: String {
        switch self {
        case .textMessage(let m): return m.id
        case .surveyMCQ(let m): return m.id
        case .surveyPictureCards(let m): return m.id
        case .quizTrueFalse(let m): return m.id
        case .flashcard(let m): return m.id
        case .stepByStep(let m): return m.id
        case .typingIndicator: return "typing_indicator"
        }
    }
}

// MARK: - Sub-types

public struct TextMessage {
    public let id: String
    public let text: String
    public let isFromUser: Bool
    public let timestamp: Date

    public init(id: String = UUID().uuidString, text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

public struct SurveyMCQ {
    public let id: String
    public let question: String
    public let options: [String]
    public var selectedIndex: Int?

    public init(id: String = UUID().uuidString, question: String, options: [String], selectedIndex: Int? = nil) {
        self.id = id
        self.question = question
        self.options = options
        self.selectedIndex = selectedIndex
    }
}

public struct PictureCard {
    public let imageUrl: String
    public let label: String

    public init(imageUrl: String, label: String) {
        self.imageUrl = imageUrl
        self.label = label
    }
}

public struct SurveyPictureCards {
    public let id: String
    public let question: String
    public let cards: [PictureCard]
    public var selectedIndex: Int?

    public init(id: String = UUID().uuidString, question: String, cards: [PictureCard], selectedIndex: Int? = nil) {
        self.id = id
        self.question = question
        self.cards = cards
        self.selectedIndex = selectedIndex
    }
}

public struct QuizTrueFalse {
    public let id: String
    public let statement: String
    public let correctAnswer: Bool
    public var userAnswer: Bool?

    public init(id: String = UUID().uuidString, statement: String, correctAnswer: Bool, userAnswer: Bool? = nil) {
        self.id = id
        self.statement = statement
        self.correctAnswer = correctAnswer
        self.userAnswer = userAnswer
    }
}

public struct Flashcard {
    public let id: String
    public let front: String
    public let back: String
    public var isFlipped: Bool
    public var isDone: Bool

    public init(id: String = UUID().uuidString, front: String, back: String, isFlipped: Bool = false, isDone: Bool = false) {
        self.id = id
        self.front = front
        self.back = back
        self.isFlipped = isFlipped
        self.isDone = isDone
    }
}

public struct StepByStep {
    public let id: String
    public let title: String
    public let steps: [String]
    public var currentStep: Int

    public init(id: String = UUID().uuidString, title: String, steps: [String], currentStep: Int = 0) {
        self.id = id
        self.title = title
        self.steps = steps
        self.currentStep = currentStep
    }
}
