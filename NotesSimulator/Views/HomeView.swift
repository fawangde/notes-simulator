import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var isMessageFieldFocused: Bool
    @FocusState private var isTimeRangeFocused: Bool
    @FocusState private var isSenderLabelFocused: Bool
    @State private var showActivationSheet = false
    @State private var showPurchaseSheet = false
    @State private var showActivationRequiredAlert = false
    @State private var activationInput = ""
    @State private var activationErrorMessage: String?
    @State private var isActivating = false
    @State private var displayNow = Date()
    @State private var showTutorial = false
    @State private var showPCPairScanner = false

    private let activationTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    tutorialSection
                    activationSection
                    gatedContent
                    Spacer(minLength: 0)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard app.isActivated else { return }
                    isMessageFieldFocused = false
                    isTimeRangeFocused = false
                    isSenderLabelFocused = false
                    KeyboardDismiss.resign()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("设置")
            .onReceive(activationTimer) { tick in
                displayNow = tick
                app.checkLocalTimeActivationExpiry()
            }
            .task {
                if !showPurchaseSheet {
                    await PurchaseOrderService.shared.reconcilePendingOrder(app: app)
                }
            }
            .onChange(of: showPurchaseSheet) { isOpen in
                if isOpen {
                    PurchaseOrderService.shared.stopObserving()
                } else {
                    Task { await PurchaseOrderService.shared.reconcilePendingOrder(app: app) }
                }
            }
            .onChange(of: app.activationExpiresAt) { _ in
                displayNow = Date()
            }
            .onChange(of: app.activationRemainingClicks) { _ in
                displayNow = Date()
            }
            .alert("请先激活 App", isPresented: $showActivationRequiredAlert) {
                Button("好", role: .cancel) {}
            }
            .alert("请先激活 App", isPresented: $app.showActivationRequiredAlert) {
                Button("好", role: .cancel) {}
            }
            .alert("PC 工具授权", isPresented: $app.showPCPairResultAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text(app.pcPairResultMessage ?? "")
            }
            .sheet(isPresented: $showTutorial) {
                AppUsageTutorialView()
            }
            .sheet(isPresented: $showPurchaseSheet) {
                PurchaseView()
                    .environmentObject(app)
            }
            .sheet(isPresented: $showActivationSheet) {
                ActivationSheetView(
                    code: $activationInput,
                    isLoading: isActivating,
                    errorMessage: activationErrorMessage,
                    onConfirm: { Task { await submitActivation() } },
                    onCancel: {
                        showActivationSheet = false
                        activationInput = ""
                        activationErrorMessage = nil
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showPCPairScanner) {
                PCPairScannerView()
                    .environmentObject(app)
            }
        }
    }

    private var gatedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            simCardSection
            modeSection
            timeRangeSection
            ios264ThreadHeaderSection
            actionSection
        }
        .disabled(!app.isActivated && !DevelopmentFlags.bypassActivation)
        .overlay {
            if !app.isActivated && !DevelopmentFlags.bypassActivation {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showActivationRequiredAlert = true
                    }
            }
        }
    }

    private var activationSection: some View {
        Group {
            if app.isActivated {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                        Text(app.activationRemainingText(at: displayNow))
                            .font(.headline)
                            .foregroundStyle(IOSTheme.labelPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(app.activationRemainingText(at: displayNow))

                    Button {
                        guard NetworkMonitor.shared.isConnected else {
                            app.showNetworkGuideAlert = true
                            return
                        }
                        showPCPairScanner = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title3)
                            Text("扫描授权 PC 工具")
                                .font(.headline)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(IOSTheme.labelPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                VStack(spacing: 10) {
                    Button {
                        guard NetworkMonitor.shared.isConnected else {
                            app.showNetworkGuideAlert = true
                            return
                        }
                        showPurchaseSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cart.fill")
                                .font(.title3)
                            Text("购买激活")
                                .font(.headline)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(IOSTheme.labelPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button {
                        guard NetworkMonitor.shared.isConnected else {
                            app.showNetworkGuideAlert = true
                            return
                        }
                        activationInput = ""
                        activationErrorMessage = nil
                        showActivationSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.title3)
                            Text("请激活APP")
                                .font(.headline)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(IOSTheme.labelPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func submitActivation() async {
        guard NetworkMonitor.shared.isConnected else {
            activationErrorMessage = ActivationError.networkUnavailable.errorDescription
            return
        }
        isActivating = true
        activationErrorMessage = nil
        defer { isActivating = false }
        do {
            try await app.activate(with: activationInput)
            showActivationSheet = false
            activationInput = ""
            displayNow = Date()
        } catch {
            activationErrorMessage = ActivationErrorMapper.message(for: error)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iMessage 演示")
                .font(.largeTitle.bold())
            Text("配置撰写页气泡内容；备忘录标题与正文可通过分享 txt 导入。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var tutorialSection: some View {
        Button {
            showTutorial = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.pages.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("操作教程")
                    .font(.headline)
                    .foregroundStyle(IOSTheme.labelPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var simCardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SIM 模式")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 10) {
                Picker("SIM 模式", selection: $app.simCardMode) {
                    ForEach(SimCardMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if app.simCardMode == .dual {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("发件人标签")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("副号", text: $app.senderLineLabel)
                            .focused($isSenderLabelFocused)
                    }
                } else {
                    Text("单卡模式仅显示收件人，不展示发件人行。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("模式选择")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            Picker("模式", selection: $app.mode) {
                ForEach(ContentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Group {
                if app.mode == .both {
                    Picker("图文顺序", selection: $app.bothContentOrder) {
                        ForEach(BothContentOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if app.mode == .text || app.mode == .both {
                    TextField("iMessage 气泡文字", text: $app.messageText, axis: .vertical)
                        .lineLimit(3...24)
                        .focused($isMessageFieldFocused)
                }

                if app.mode == .image || app.mode == .both {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(app.messageImage == nil ? "选择图片" : "更换图片", systemImage: "photo")
                    }
                    .onChange(of: photoItem) { item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    app.messageImage = image
                                }
                            }
                        }
                    }
                    if let image = app.messageDisplayImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间小字")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 6) {
                TextField(
                    ThreadTimeRangeInputFormatting.placeholder,
                    text: Binding(
                        get: { app.threadTimeRangeInput },
                        set: { app.threadTimeRangeInput = ThreadTimeRangeInputFormatting.formatted(from: $0) }
                    )
                )
                    .keyboardType(.numberPad)
                    .monospacedDigit()
                    .focused($isTimeRangeFocused)
                Text("按备忘录非空行数，从上到下在区间内依次分配时间；长按号码打开信息时使用对应行时间。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var ios264ThreadHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("界面样式")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("当前备忘录样式：\(activeNotesStyleLabel)")
                    .font(.subheadline.weight(.medium))

                Toggle("iOS 17 备忘录样式", isOn: legacyStyleToggleBinding(.ios17))
                Text("扁平金黄导航/工具栏，无液态玻璃。与系统版本无关，仅切换备忘录页展示。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Toggle("iOS 18 备忘录样式", isOn: legacyStyleToggleBinding(.ios18))
                Text("当前与 iOS 17 样式相同，后续可独立微调。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Toggle("iOS 26.4 三行样式", isOn: $app.threadHeaderStyleIOS264)
                Text("仅切换 iMessage 时间小字排版。iOS 26.4 及以上用户建议开启。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Toggle("信息页链接隐藏下划线", isOn: $app.messageLinkUnderlineHidden)
                Text("开启后，信息气泡内的网址（如 example.com）不再显示下划线；关闭则保持当前带下划线样式。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    guard await app.enterNotesFromSettings() else {
                        app.presentActivationRequired()
                        return
                    }
                    app.showIMessage = false
                    app.showPhoneMenu = false
                    app.screen = .notes
                }
            } label: {
                Label("返回备忘录", systemImage: "note.text")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                photoItem = nil
                app.clearMessageTextAndImage()
            } label: {
                Label("清理文案和图片", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
        }
    }

    private var activeNotesStyleLabel: String {
        switch app.legacyNotesShell {
        case .ios17: return "iOS 17"
        case .ios18: return "iOS 18"
        case nil: return "iOS 26（默认）"
        }
    }

    private func legacyStyleToggleBinding(_ shell: LegacyNotesShell) -> Binding<Bool> {
        Binding(
            get: {
                switch shell {
                case .ios17: app.notesStyleIOS17
                case .ios18: app.notesStyleIOS18
                }
            },
            set: { enabled in
                if enabled {
                    app.activateLegacyNotesShell(shell)
                } else {
                    switch shell {
                    case .ios17: app.notesStyleIOS17 = false
                    case .ios18: app.notesStyleIOS18 = false
                    }
                }
            }
        )
    }
}
