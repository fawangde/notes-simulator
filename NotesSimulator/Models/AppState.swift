import Combine
import SwiftUI
import UIKit

enum ContentMode: String, CaseIterable, Identifiable, Codable {
    case text, image, both
    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "1 纯文"
        case .image: return "2 图片"
        case .both: return "3 图文"
        }
    }
}

enum SimCardMode: String, CaseIterable, Identifiable, Codable {
    case single
    case dual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .single: return "单卡"
        case .dual: return "双卡"
        }
    }
}

enum BothContentOrder: String, CaseIterable, Identifiable, Codable {
    case textFirst
    case imageFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .textFirst: return "先文后图"
        case .imageFirst: return "先图后文"
        }
    }
}

enum AppScreen {
    case home
    case notes
}

private struct AppStateSnapshot: Codable {
    var mode: ContentMode
    var bothContentOrder: BothContentOrder
    var simCardMode: SimCardMode
    var senderLineLabel: String
    var messageText: String
    var messageImageJPEG: Data?
    var noteTitle: String
    var noteBody: String
    var threadTimeRangeInput: String
    var threadHeaderStyleIOS264: Bool

    enum CodingKeys: String, CodingKey {
        case mode, bothContentOrder, simCardMode, senderLineLabel, messageText
        case messageImageJPEG, noteTitle, noteBody, threadTimeRangeInput
        case threadHeaderStyleIOS264
    }

    init(
        mode: ContentMode,
        bothContentOrder: BothContentOrder,
        simCardMode: SimCardMode,
        senderLineLabel: String,
        messageText: String,
        messageImageJPEG: Data?,
        noteTitle: String,
        noteBody: String,
        threadTimeRangeInput: String,
        threadHeaderStyleIOS264: Bool = false
    ) {
        self.mode = mode
        self.bothContentOrder = bothContentOrder
        self.simCardMode = simCardMode
        self.senderLineLabel = senderLineLabel
        self.messageText = messageText
        self.messageImageJPEG = messageImageJPEG
        self.noteTitle = noteTitle
        self.noteBody = noteBody
        self.threadTimeRangeInput = threadTimeRangeInput
        self.threadHeaderStyleIOS264 = threadHeaderStyleIOS264
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decode(ContentMode.self, forKey: .mode)
        bothContentOrder = try c.decode(BothContentOrder.self, forKey: .bothContentOrder)
        simCardMode = try c.decodeIfPresent(SimCardMode.self, forKey: .simCardMode) ?? .dual
        senderLineLabel = try c.decodeIfPresent(String.self, forKey: .senderLineLabel) ?? "副号"
        messageText = try c.decode(String.self, forKey: .messageText)
        messageImageJPEG = try c.decodeIfPresent(Data.self, forKey: .messageImageJPEG)
        noteTitle = try c.decode(String.self, forKey: .noteTitle)
        noteBody = try c.decode(String.self, forKey: .noteBody)
        threadTimeRangeInput = try c.decode(String.self, forKey: .threadTimeRangeInput)
        threadHeaderStyleIOS264 = try c.decodeIfPresent(Bool.self, forKey: .threadHeaderStyleIOS264) ?? false
    }
}

private enum AppStateStore {
    static let key = "AppStateSnapshot.v1"

    static func load() -> AppStateSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AppStateSnapshot.self, from: data)
    }

    static func save(_ snapshot: AppStateSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var screen: AppScreen = .notes
    @Published var mode: ContentMode = .text
    @Published var bothContentOrder: BothContentOrder = .textFirst
    @Published var simCardMode: SimCardMode = .dual
    /// 双卡模式下发件人标签（如「副号」「副卡」）
    @Published var senderLineLabel = "副号"
    @Published var messageText = ""
    @Published var messageImage: UIImage?
    @Published var noteTitle = ""
    @Published var noteBody = ""
    /// 撰写页时间小字区间，格式「HH:mm-HH:mm」，按备忘录行数从上到下分配
    @Published var threadTimeRangeInput = ""
    /// 三行时间小字样式（对齐 iOS 26.4 Messages；与系统版本无关，仅改展示）
    @Published var threadHeaderStyleIOS264 = false
    @Published var selectedPhone: String?
    @Published var phoneMenuAnchor: CGRect = .zero
    @Published var showPhoneMenu = false
    @Published var showIMessage = false

    private var isHydrating = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        isHydrating = true
        if let saved = AppStateStore.load() {
            applySnapshot(saved)
        }
        isHydrating = false
        installPersistence()
    }

    var messagePreviewText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var showsMessageText: Bool {
        (mode == .text || mode == .both) && !messagePreviewText.isEmpty
    }

    var showsMessageImage: Bool {
        (mode == .image || mode == .both) && messageImage != nil
    }

    /// 按备忘录行序与所选号码，在时间区间内分配撰写页时间小字
    var threadDateLine: String {
        let lines = noteLines
        let count = max(lines.count, 1)
        let index = lineIndexForSelectedPhone(in: lines)
        guard let range = ThreadTimeRange.parse(threadTimeRangeInput) else {
            return NoteDateFormatting.composeThreadDateLabel(from: Date())
        }
        let minutes = range.minutes(atLineIndex: index, lineCount: count)
        return NoteDateFormatting.composeThreadDateLabel(minutesFromMidnight: minutes)
    }

    func clearNotesAndTitle() {
        noteTitle = ""
        noteBody = ""
        persist()
    }

    func applyImport(title: String, body: String) {
        noteTitle = title
        noteBody = body
        screen = .notes
        showIMessage = false
        showPhoneMenu = false
        persist()
    }

    func importTextFile(from url: URL) {
        guard NoteImportService.accepts(url: url) else { return }
        do {
            let payload = try NoteImportService.parseTextFile(url: url)
            applyImport(title: payload.title, body: payload.body)
        } catch {
            return
        }
    }

    func handleIncomingURL(_ url: URL) {
        if url.scheme == "notesimulator", url.host == "import" {
            consumePendingImportIfNeeded()
            return
        }
        if url.isFileURL {
            importTextFile(from: url)
        }
    }

    func consumePendingImportIfNeeded() {
        if let payload = NoteImportService.consumePendingImport() {
            applyImport(title: payload.title, body: payload.body)
            return
        }
        // Share Extension 写入 App Group 后可能略早于主 App 被唤起
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self,
                  let payload = NoteImportService.consumePendingImport() else { return }
            self.applyImport(title: payload.title, body: payload.body)
        }
    }

    private var noteLines: [String] {
        noteBody
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func lineIndexForSelectedPhone(in lines: [String]) -> Int {
        guard let phone = selectedPhone else { return 0 }
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return 0 }
        if let idx = lines.firstIndex(where: { line in
            let lineDigits = line.filter(\.isNumber)
            return line.contains(phone) || lineDigits.contains(digits) || digits.contains(lineDigits)
        }) {
            return idx
        }
        return 0
    }

    private func installPersistence() {
        let publishers: [AnyPublisher<Void, Never>] = [
            $mode.map { _ in () }.eraseToAnyPublisher(),
            $bothContentOrder.map { _ in () }.eraseToAnyPublisher(),
            $simCardMode.map { _ in () }.eraseToAnyPublisher(),
            $senderLineLabel.map { _ in () }.eraseToAnyPublisher(),
            $messageText.map { _ in () }.eraseToAnyPublisher(),
            $messageImage.map { _ in () }.eraseToAnyPublisher(),
            $noteTitle.map { _ in () }.eraseToAnyPublisher(),
            $noteBody.map { _ in () }.eraseToAnyPublisher(),
            $threadTimeRangeInput.map { _ in () }.eraseToAnyPublisher(),
            $threadHeaderStyleIOS264.map { _ in () }.eraseToAnyPublisher(),
        ]

        Publishers.MergeMany(publishers)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.persist()
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(_ snapshot: AppStateSnapshot) {
        mode = snapshot.mode
        bothContentOrder = snapshot.bothContentOrder
        simCardMode = snapshot.simCardMode
        senderLineLabel = snapshot.senderLineLabel.isEmpty ? "副号" : snapshot.senderLineLabel
        messageText = snapshot.messageText
        noteTitle = snapshot.noteTitle
        noteBody = snapshot.noteBody
        threadTimeRangeInput = snapshot.threadTimeRangeInput
        threadHeaderStyleIOS264 = snapshot.threadHeaderStyleIOS264
        if let data = snapshot.messageImageJPEG, let image = UIImage(data: data) {
            messageImage = image
        } else {
            messageImage = nil
        }
    }

    private func makeSnapshot() -> AppStateSnapshot {
        AppStateSnapshot(
            mode: mode,
            bothContentOrder: bothContentOrder,
            simCardMode: simCardMode,
            senderLineLabel: senderLineLabel,
            messageText: messageText,
            messageImageJPEG: messageImage?.jpegData(compressionQuality: 0.88),
            noteTitle: noteTitle,
            noteBody: noteBody,
            threadTimeRangeInput: threadTimeRangeInput,
            threadHeaderStyleIOS264: threadHeaderStyleIOS264
        )
    }

    private func persist() {
        guard !isHydrating else { return }
        AppStateStore.save(makeSnapshot())
    }
}

struct ThreadTimeRange {
    let startMinutes: Int
    let endMinutes: Int

    static func parse(_ input: String) -> ThreadTimeRange? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "-", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let start = parseClock(parts[0]),
              let end = parseClock(parts[1]) else {
            return nil
        }
        return ThreadTimeRange(startMinutes: start, endMinutes: end)
    }

    func minutes(atLineIndex index: Int, lineCount: Int) -> Int {
        let count = max(lineCount, 1)
        if count == 1 { return startMinutes }
        let clampedIndex = min(max(index, 0), count - 1)
        let progress = Double(clampedIndex) / Double(count - 1)
        let delta = endMinutes - startMinutes
        return startMinutes + Int((Double(delta) * progress).rounded())
    }

    private static func parseClock(_ text: String) -> Int? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let bits = cleaned.split(separator: ":")
        guard bits.count == 2,
              let hour = Int(bits[0]),
              let minute = Int(bits[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }
        return hour * 60 + minute
    }
}
