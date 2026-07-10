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

private enum AppStateLegacyMigrationKeys: String, CodingKey {
    case notesStyleIOS1718
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
    var noteImportedAt: Double?
    var threadTimeRangeInput: String
    var threadHeaderStyleIOS264: Bool
    var messageLinkUnderlineHidden: Bool
    var notesStyleIOS17: Bool
    var notesStyleIOS18: Bool
    var activationExpiresAt: Double?
    var activationCode: String?
    var activationBoundUID: String?
    var activationMode: String?
    var activationRemainingClicks: Int?

    enum CodingKeys: String, CodingKey {
        case mode, bothContentOrder, simCardMode, senderLineLabel, messageText
        case messageImageJPEG, noteTitle, noteBody, noteImportedAt, threadTimeRangeInput
        case threadHeaderStyleIOS264, messageLinkUnderlineHidden, notesStyleIOS17, notesStyleIOS18, activationExpiresAt, activationCode, activationBoundUID
        case activationMode, activationRemainingClicks
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
        noteImportedAt: Double? = nil,
        threadTimeRangeInput: String,
        threadHeaderStyleIOS264: Bool = false,
        messageLinkUnderlineHidden: Bool = false,
        notesStyleIOS17: Bool = false,
        notesStyleIOS18: Bool = false,
        activationExpiresAt: Double? = nil,
        activationCode: String? = nil,
        activationBoundUID: String? = nil,
        activationMode: String? = nil,
        activationRemainingClicks: Int? = nil
    ) {
        self.mode = mode
        self.bothContentOrder = bothContentOrder
        self.simCardMode = simCardMode
        self.senderLineLabel = senderLineLabel
        self.messageText = messageText
        self.messageImageJPEG = messageImageJPEG
        self.noteTitle = noteTitle
        self.noteBody = noteBody
        self.noteImportedAt = noteImportedAt
        self.threadTimeRangeInput = threadTimeRangeInput
        self.threadHeaderStyleIOS264 = threadHeaderStyleIOS264
        self.messageLinkUnderlineHidden = messageLinkUnderlineHidden
        self.notesStyleIOS17 = notesStyleIOS17
        self.notesStyleIOS18 = notesStyleIOS18
        self.activationExpiresAt = activationExpiresAt
        self.activationCode = activationCode
        self.activationBoundUID = activationBoundUID
        self.activationMode = activationMode
        self.activationRemainingClicks = activationRemainingClicks
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
        noteImportedAt = try c.decodeIfPresent(Double.self, forKey: .noteImportedAt)
        threadTimeRangeInput = try c.decode(String.self, forKey: .threadTimeRangeInput)
        threadHeaderStyleIOS264 = try c.decodeIfPresent(Bool.self, forKey: .threadHeaderStyleIOS264) ?? false
        messageLinkUnderlineHidden = try c.decodeIfPresent(Bool.self, forKey: .messageLinkUnderlineHidden) ?? false
        notesStyleIOS17 = try c.decodeIfPresent(Bool.self, forKey: .notesStyleIOS17) ?? false
        notesStyleIOS18 = try c.decodeIfPresent(Bool.self, forKey: .notesStyleIOS18) ?? false
        if !notesStyleIOS17 && !notesStyleIOS18 {
            let legacy = try decoder.container(keyedBy: AppStateLegacyMigrationKeys.self)
            if try legacy.decodeIfPresent(Bool.self, forKey: .notesStyleIOS1718) == true {
                notesStyleIOS18 = true
            }
        }
        activationExpiresAt = try c.decodeIfPresent(Double.self, forKey: .activationExpiresAt)
        activationCode = try c.decodeIfPresent(String.self, forKey: .activationCode)
        activationBoundUID = try c.decodeIfPresent(String.self, forKey: .activationBoundUID)
        activationMode = try c.decodeIfPresent(String.self, forKey: .activationMode)
        activationRemainingClicks = try c.decodeIfPresent(Int.self, forKey: .activationRemainingClicks)
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

    /// 长按菜单「呼叫」副标题：双卡为「电话 (标签)」，单卡为「电话」
    var phoneMenuCallSubtitle: String {
        switch simCardMode {
        case .single:
            return "电话"
        case .dual:
            let trimmed = senderLineLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            let label = trimmed.isEmpty ? "副号" : trimmed
            return "电话 (\(label))"
        }
    }
    @Published var messageText = ""
    @Published var messageImage: UIImage?
    @Published var noteTitle = ""
    @Published var noteBody = ""
    /// 备忘录顶栏日期：导入时写入（仅持久化，展示见 `noteHeaderDisplayDate`）
    @Published var noteImportedAt = Date()
    /// 撰写页时间小字区间，格式「HH:mm-HH:mm」，按备忘录行数从上到下分配
    @Published var threadTimeRangeInput = ""
    /// 三行时间小字样式（对齐 iOS 26.4 Messages；与系统版本无关，仅改展示）
    @Published var threadHeaderStyleIOS264 = false
    /// 信息页气泡内网址是否隐藏下划线（开启=无下划线，关闭=保持现状）
    @Published var messageLinkUnderlineHidden = false
    /// 备忘录页 iOS 17 legacy 样式（与系统版本无关，仅改展示）
    @Published var notesStyleIOS17 = false
    /// 备忘录页 iOS 18 legacy 样式（与系统版本无关，仅改展示）
    @Published var notesStyleIOS18 = false
    @Published var notes17Tuning = Notes17TuningSettings.default
    @Published var notes18Tuning = Notes18TuningSettings.default
    @Published var notes1718Tuning = Notes1718TuningSettings.default
    @Published var notes26Tuning = Notes26TuningSettings.default
    @Published var composeBubbleTuning = ComposeBubbleTuningSettings.default
    @Published var selectedPhone: String?
    @Published var phoneMenuAnchor: CGRect = .zero
    @Published var showPhoneMenu = false
    @Published var phoneMenuPresentation: PhoneMenuPresentation = .longPress
    /// 长按菜单压暗 + 正文模糊强度（0 正常，1 完全生效）
    @Published var phoneMenuBackdropStrength: Double = 0
    /// iOS 26 长按：触发正文号码缩回动画（递增值，不做逐帧绑定）
    @Published var phoneMenuBodyDismissSignal: Int = 0
    @Published var showIMessage = false
    @Published var activationExpiresAt: Date?
    @Published var activationCode: String?
    @Published var activationBoundUID: String?
    @Published var activationMode: ActivationMode?
    @Published var activationRemainingClicks: Int?
    @Published var showActivationRequiredAlert = false
    @Published var showPurchaseActivationSuccessAlert = false
    @Published var showPurchasePaymentRejectedAlert = false
    @Published var purchaseActivationErrorMessage: String?
    @Published var showNetworkGuideAlert = false
    @Published var pcPairResultMessage: String?
    @Published var showPCPairResultAlert = false
    /// 次数码：仅通过「返回备忘录」扣次后解锁；离开设置页或导入后失效
    @Published private(set) var notesSimulationUnlocked = false

    private var isHydrating = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        isHydrating = true
        if let saved = AppStateStore.load() {
            applySnapshot(saved)
        }
        notes17Tuning = Notes17TuningStore.load()
        notes18Tuning = Notes18TuningStore.load()
        notes1718Tuning = Notes1718TuningStore.load()
        migrateLegacy1718TuningIfNeeded()
        notes26Tuning = Notes26TuningStore.load()
        composeBubbleTuning = ComposeBubbleTuningStore.load()
        isHydrating = false
        if activationMode == .clicks {
            screen = .home
            notesSimulationUnlocked = false
        }
        installPersistence()
        startPeriodicActivationCheck()
        Task { @MainActor in
            await syncActivationIfNeeded()
        }
    }

    /// 每 60 秒：本地到期检查 + 有网时从 Firebase 同步（失败不清本地）
    private func startPeriodicActivationCheck() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.performPeriodicActivationCheck() }
            }
            .store(in: &cancellables)
    }

    func performPeriodicActivationCheck() async {
        checkLocalActivationExpiry()
        guard activationCode != nil else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        await syncActivationIfNeeded()
    }

    func checkLocalTimeActivationExpiry() {
        checkLocalActivationExpiry()
    }

    private func checkLocalActivationExpiry() {
        switch activationMode {
        case .time:
            guard let expiresAt = activationExpiresAt, expiresAt <= Date() else { return }
            clearActivationLocal()
        case .clicks:
            guard let clicks = activationRemainingClicks, clicks <= 0 else { return }
            clearActivationLocal()
        case nil:
            break
        }
    }

    var isActivated: Bool {
        if DevelopmentFlags.bypassActivation { return true }
        switch activationMode {
        case .time:
            guard let activationExpiresAt else { return false }
            return activationExpiresAt > Date()
        case .clicks:
            guard let activationRemainingClicks else { return false }
            return activationRemainingClicks > 0
        case nil:
            return false
        }
    }

    var canUseSimulationFeatures: Bool {
        if DevelopmentFlags.bypassActivation { return true }
        guard isActivated else { return false }
        if activationMode == .clicks {
            return notesSimulationUnlocked
        }
        return true
    }

    func activationRemainingText(at now: Date = Date()) -> String {
        if DevelopmentFlags.bypassActivation { return "测试模式（未校验激活）" }
        guard isActivated else { return "请激活APP" }
        switch activationMode {
        case .time:
            guard let activationExpiresAt else { return "请激活APP" }
            return ActivationFormatting.remainingTimeText(until: activationExpiresAt, now: now)
        case .clicks:
            guard let activationRemainingClicks else { return "请激活APP" }
            return ActivationFormatting.remainingClicksText(activationRemainingClicks)
        case nil:
            return "请激活APP"
        }
    }

    func presentActivationRequired() {
        showActivationRequiredAlert = true
    }

    /// 备忘录扫码授权 PC 分割器；不写 activationCodes，不扣模拟次数。
    func authorizePCPairSession(_ sessionId: String) async throws {
        try await PCSessionService.shared.authorize(sessionId: sessionId, app: self)
    }

    func handlePCPairURL(_ url: URL) {
        guard url.scheme == "notesimulator", url.host == "pair" else { return }
        guard let sessionId = PCSessionLinkParser.sessionId(from: url.absoluteString) else { return }
        Task { @MainActor in
            do {
                try await authorizePCPairSession(sessionId)
                pcPairResultMessage = "PC 工具授权成功"
            } catch {
                pcPairResultMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            showPCPairResultAlert = true
        }
    }

    /// 设置页「返回备忘录」：次数码每次进入扣 1 次；时间码需已激活
    func enterNotesFromSettings() async -> Bool {
        if DevelopmentFlags.bypassActivation {
            if activationMode == .clicks {
                notesSimulationUnlocked = true
            }
            return true
        }
        switch activationMode {
        case .clicks:
            guard isActivated, let clicks = activationRemainingClicks, clicks > 0 else { return false }
            let next = clicks - 1
            if let code = activationCode, let uid = activationBoundUID {
                do {
                    try await ActivationService.shared.decrementRemainingClicks(
                        code: code,
                        boundUID: uid,
                        to: next
                    )
                } catch {
                    return false
                }
            }
            activationRemainingClicks = next
            notesSimulationUnlocked = true
            persist()
            return true
        case .time:
            return isActivated
        case nil:
            return false
        }
    }

    func activate(with rawCode: String) async throws {
        let outcome = try await ActivationService.shared.activate(code: rawCode)
        activationCode = ActivationFormatting.normalizedCode(rawCode)
        activationBoundUID = ActivationService.shared.deviceId()
        activationMode = outcome.mode
        activationExpiresAt = outcome.expiresAt
        activationRemainingClicks = outcome.remainingClicks
        persist()
    }

    func syncActivationIfNeeded() async {
        guard let code = activationCode,
              let uid = activationBoundUID else {
            return
        }
        guard NetworkMonitor.shared.isConnected else { return }
        guard await FirebaseReachability.canReachDatabase() else { return }

        do {
            let outcome = try await ActivationService.shared.syncActivationFromRemote(
                code: code,
                boundUID: uid,
                localExpiresAt: activationExpiresAt,
                localRemainingClicks: activationRemainingClicks
            )
            activationMode = outcome.mode
            activationExpiresAt = outcome.expiresAt
            activationRemainingClicks = outcome.remainingClicks
            persist()
        } catch {
            if shouldClearActivation(after: error) {
                clearActivationLocal()
            }
        }
    }

    @available(*, deprecated, message: "Use syncActivationIfNeeded")
    func refreshActivationOnLaunch() async {
        await syncActivationIfNeeded()
    }

    private func shouldClearActivation(after error: Error) -> Bool {
        if let activation = error as? ActivationError {
            return activation.shouldClearLocalActivation
        }
        return false
    }

    private func clearActivationLocal() {
        activationCode = nil
        activationBoundUID = nil
        activationExpiresAt = nil
        activationMode = nil
        activationRemainingClicks = nil
        notesSimulationUnlocked = false
        showPhoneMenu = false
        showIMessage = false
        persist()
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

    /// iOS 18：标准空白信息会话（第 2 行固定 + 随机 50）
    var isIOS18StandardBlankThreadForSelectedPhone: Bool {
        guard legacyNotesShell == .ios18, selectedPhone != nil else { return false }
        let lines = noteLines
        guard !lines.isEmpty else { return false }
        let index = lineIndexForSelectedPhone(in: lines)
        return BlankThread18.standardBlankLineIndices(lineCount: lines.count, noteBody: noteBody).contains(index)
    }

    /// iOS 18：绿色 SMS 空白会话（第 1 行固定 + 随机 60），撰写页 chrome 不同
    var isIOS18GreenSMSBlankThreadForSelectedPhone: Bool {
        guard legacyNotesShell == .ios18, selectedPhone != nil else { return false }
        let lines = noteLines
        guard !lines.isEmpty else { return false }
        let index = lineIndexForSelectedPhone(in: lines)
        return BlankThread18.greenSMSBlankLineIndices(lineCount: lines.count, noteBody: noteBody).contains(index)
    }

    var ios18ComposeChromeStyle: IOS18ComposeChromeStyle {
        isIOS18GreenSMSBlankThreadForSelectedPhone ? .greenSMS : .standard
    }

    /// iOS 18：任一空白会话（聊天区无内容）
    var isIOS18BlankThreadForSelectedPhone: Bool {
        isIOS18StandardBlankThreadForSelectedPhone || isIOS18GreenSMSBlankThreadForSelectedPhone
    }

    /// iOS 26：标准空白信息会话（第 2 行固定 + 随机 50）
    var isIOS26StandardBlankThreadForSelectedPhone: Bool {
        guard legacyNotesShell == nil, selectedPhone != nil else { return false }
        let lines = noteLines
        guard !lines.isEmpty else { return false }
        let index = lineIndexForSelectedPhone(in: lines)
        return BlankThread26.standardBlankLineIndices(lineCount: lines.count, noteBody: noteBody).contains(index)
    }

    /// iOS 26：绿色 SMS 空白会话（第 1 行固定 + 随机 60），撰写页 chrome 不同
    var isIOS26GreenSMSBlankThreadForSelectedPhone: Bool {
        guard legacyNotesShell == nil, selectedPhone != nil else { return false }
        let lines = noteLines
        guard !lines.isEmpty else { return false }
        let index = lineIndexForSelectedPhone(in: lines)
        return BlankThread26.greenSMSBlankLineIndices(lineCount: lines.count, noteBody: noteBody).contains(index)
    }

    var ios26ComposeChromeStyle: IOS26ComposeChromeStyle {
        isIOS26GreenSMSBlankThreadForSelectedPhone ? .greenSMS : .standard
    }

    /// iOS 26：任一空白会话（聊天区无内容）
    var isIOS26BlankThreadForSelectedPhone: Bool {
        isIOS26StandardBlankThreadForSelectedPhone || isIOS26GreenSMSBlankThreadForSelectedPhone
    }

    var composeShowsMessageText: Bool {
        showsMessageText && !isIOS26BlankThreadForSelectedPhone && !isIOS18BlankThreadForSelectedPhone
    }

    var composeShowsMessageImage: Bool {
        showsMessageImage && !isIOS26BlankThreadForSelectedPhone && !isIOS18BlankThreadForSelectedPhone
    }

    /// 单图展示：纯白底图压灰（全系 iOS 17/18/26 撰写页与设置预览共用）
    var messageDisplayImage: UIImage? {
        guard let messageImage else { return nil }
        return ImageBubbleWhiteBackgroundAdjust.displayImage(from: messageImage) ?? messageImage
    }

    /// 备忘录顶栏日期：时间小字区间开始时间的前 2 分钟（随区间设置变化，不用导入时间）
    var noteHeaderDisplayDate: Date {
        let range = ThreadTimeRange.parse(threadTimeRangeInput)
        let startMinutes = range?.startMinutes ?? (9 * 60)
        return NoteDateFormatting.notesHeaderDate(
            startMinutesFromMidnight: startMinutes,
            timeRange: range
        )
    }

    /// 按备忘录行序与所选号码，在时间区间内分配撰写页时间小字
    var threadDateLine: String {
        guard !isIOS26BlankThreadForSelectedPhone, !isIOS18BlankThreadForSelectedPhone else { return "" }
        let lines = noteLines
        let count = max(lines.count, 1)
        let index = lineIndexForSelectedPhone(in: lines)
        guard let range = ThreadTimeRange.parse(threadTimeRangeInput) else {
            return NoteDateFormatting.composeThreadDateLabel(from: Date())
        }
        let minutes = range.minutes(atLineIndex: index, lineCount: count)
        return NoteDateFormatting.composeThreadDateLabel(
            minutesFromMidnight: minutes,
            timeRange: range
        )
    }

    func clearMessageTextAndImage() {
        messageText = ""
        messageImage = nil
        persist()
    }

    func applyImport(title: String, body: String, importedAt: Date = Date()) {
        noteTitle = title
        noteBody = NoteImportService.appendTrailingBlankLines(to: body)
        noteImportedAt = importedAt
        BlankThread26.logAssignments(lines: noteLines, noteBody: noteBody)
        BlankThread18.logAssignments(lines: noteLines, noteBody: noteBody)
        showIMessage = false
        showPhoneMenu = false
        if activationMode == .clicks {
            // 次数码：导入后回到设置页，结束当前模拟会话，须再次点「返回备忘录」扣次
            notesSimulationUnlocked = false
            screen = .home
        } else {
            screen = .notes
        }
        persist()
    }

    /// 备忘录顶栏返回设置；次数码下结束本次模拟会话
    func leaveNotesToSettings() {
        showPhoneMenu = false
        showIMessage = false
        if activationMode == .clicks {
            notesSimulationUnlocked = false
        }
        screen = .home
    }

    func importTextFile(from url: URL) {
        guard NoteImportService.accepts(url: url) else { return }
        do {
            let payload = try NoteImportService.parseTextFile(url: url)
            applyImport(
                title: payload.title,
                body: payload.body,
                importedAt: payload.importedAt ?? Date()
            )
        } catch {
            return
        }
    }

    func handleIncomingURL(_ url: URL) {
        if url.scheme == "notesimulator", url.host == "import" {
            consumePendingImportIfNeeded()
            return
        }
        if url.scheme == "notesimulator", url.host == "pair" {
            handlePCPairURL(url)
            return
        }
        if url.isFileURL {
            importTextFile(from: url)
        }
    }

    func consumePendingImportIfNeeded() {
        if let payload = NoteImportService.consumePendingImport() {
            applyImport(
                title: payload.title,
                body: payload.body,
                importedAt: payload.importedAt ?? Date()
            )
            return
        }
        // Share Extension 写入 App Group 后可能略早于主 App 被唤起
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self,
                  let payload = NoteImportService.consumePendingImport() else { return }
            self.applyImport(
                title: payload.title,
                body: payload.body,
                importedAt: payload.importedAt ?? Date()
            )
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
            $noteImportedAt.map { _ in () }.eraseToAnyPublisher(),
            $threadTimeRangeInput.map { _ in () }.eraseToAnyPublisher(),
            $threadHeaderStyleIOS264.map { _ in () }.eraseToAnyPublisher(),
            $messageLinkUnderlineHidden.map { _ in () }.eraseToAnyPublisher(),
            $notesStyleIOS17.map { _ in () }.eraseToAnyPublisher(),
            $notesStyleIOS18.map { _ in () }.eraseToAnyPublisher(),
            $notes17Tuning.map { _ in () }.eraseToAnyPublisher(),
            $notes18Tuning.map { _ in () }.eraseToAnyPublisher(),
            $notes1718Tuning.map { _ in () }.eraseToAnyPublisher(),
            $notes26Tuning.map { _ in () }.eraseToAnyPublisher(),
            $composeBubbleTuning.map { _ in () }.eraseToAnyPublisher(),
            $activationExpiresAt.map { _ in () }.eraseToAnyPublisher(),
            $activationCode.map { _ in () }.eraseToAnyPublisher(),
            $activationBoundUID.map { _ in () }.eraseToAnyPublisher(),
            $activationMode.map { _ in () }.eraseToAnyPublisher(),
            $activationRemainingClicks.map { _ in () }.eraseToAnyPublisher(),
        ]

        Publishers.MergeMany(publishers)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.persist()
            }
            .store(in: &cancellables)

        Publishers.MergeMany([
            $messageText.map { _ in () }.eraseToAnyPublisher(),
            $simCardMode.map { _ in () }.eraseToAnyPublisher(),
            $notes17Tuning.map { _ in () }.eraseToAnyPublisher(),
            $notes18Tuning.map { _ in () }.eraseToAnyPublisher(),
            $notesStyleIOS17.map { _ in () }.eraseToAnyPublisher(),
            $notesStyleIOS18.map { _ in () }.eraseToAnyPublisher(),
        ])
        .debounce(for: .milliseconds(120), scheduler: RunLoop.main)
        .sink { [weak self] in
            guard let self else { return }
            ComposeThread1718PinWarmup.refresh(app: self)
        }
        .store(in: &cancellables)

        $composeBubbleTuning
            .debounce(for: .milliseconds(120), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                ComposeThread1718PinWarmup.refresh(app: self)
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
        if let stamp = snapshot.noteImportedAt {
            noteImportedAt = Date(timeIntervalSince1970: stamp)
        }
        threadTimeRangeInput = snapshot.threadTimeRangeInput
        threadHeaderStyleIOS264 = snapshot.threadHeaderStyleIOS264
        messageLinkUnderlineHidden = snapshot.messageLinkUnderlineHidden
        notesStyleIOS17 = snapshot.notesStyleIOS17
        notesStyleIOS18 = snapshot.notesStyleIOS18
        activationCode = snapshot.activationCode
        activationBoundUID = snapshot.activationBoundUID
        if let stamp = snapshot.activationExpiresAt {
            activationExpiresAt = Date(timeIntervalSince1970: stamp)
        } else {
            activationExpiresAt = nil
        }
        if let modeRaw = snapshot.activationMode, let mode = ActivationMode(rawValue: modeRaw) {
            activationMode = mode
        } else if snapshot.activationExpiresAt != nil {
            activationMode = .time
        } else if snapshot.activationRemainingClicks != nil {
            activationMode = .clicks
        } else {
            activationMode = nil
        }
        activationRemainingClicks = snapshot.activationRemainingClicks
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
            noteImportedAt: noteImportedAt.timeIntervalSince1970,
            threadTimeRangeInput: threadTimeRangeInput,
            threadHeaderStyleIOS264: threadHeaderStyleIOS264,
            messageLinkUnderlineHidden: messageLinkUnderlineHidden,
            notesStyleIOS17: notesStyleIOS17,
            notesStyleIOS18: notesStyleIOS18,
            activationExpiresAt: activationExpiresAt?.timeIntervalSince1970,
            activationCode: activationCode,
            activationBoundUID: activationBoundUID,
            activationMode: activationMode?.rawValue,
            activationRemainingClicks: activationRemainingClicks
        )
    }

    private func persist() {
        guard !isHydrating else { return }
        AppStateStore.save(makeSnapshot())
        Notes17TuningStore.save(notes17Tuning)
        Notes18TuningStore.save(notes18Tuning)
        Notes1718TuningStore.save(notes1718Tuning)
        Notes26TuningStore.save(notes26Tuning)
        ComposeBubbleTuningStore.save(composeBubbleTuning)
    }

    private func migrateLegacy1718TuningIfNeeded() {
        let legacy = notes1718Tuning
        guard legacy != .default else { return }
        if notes17Tuning == .default {
            notes17Tuning = .bridgedFrom1718(legacy)
        }
        if notes18Tuning == .default {
            notes18Tuning = .bridgedFrom1718(legacy)
        }
    }
}

struct ThreadTimeRange {
    let startMinutes: Int
    let endMinutes: Int

    var crossesMidnight: Bool { endMinutes < startMinutes }

    static func parse(_ input: String) -> ThreadTimeRange? {
        let trimmed = ThreadTimeRangeInputFormatting.formatted(from: input)
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

        if crossesMidnight {
            let span = (24 * 60 - startMinutes) + endMinutes
            let offset = Int((Double(span) * progress).rounded())
            var minutes = startMinutes + offset
            if minutes >= 24 * 60 { minutes -= 24 * 60 }
            return minutes
        }

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

/// 「时间小字」区间输入：只收数字，自动插入 `:` 与 `-`（09001800 → 09:00-18:00）
enum ThreadTimeRangeInputFormatting {
    static let placeholder = "09:00-18:00"
    private static let maxDigitCount = 8

    static func formatted(from input: String) -> String {
        let digits = input.filter(\.isNumber).prefix(maxDigitCount)
        let chars = Array(digits)
        var result = ""
        for (index, char) in chars.enumerated() {
            result.append(char)
            guard index + 1 < chars.count else { continue }
            switch index {
            case 1: result.append(":")
            case 3: result.append("-")
            case 5: result.append(":")
            default: break
            }
        }
        return result
    }
}
