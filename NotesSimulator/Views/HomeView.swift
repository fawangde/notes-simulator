import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var isMessageFieldFocused: Bool
    @FocusState private var isTimeRangeFocused: Bool
    @FocusState private var isSenderLabelFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    simCardSection
                    modeSection
                    timeRangeSection
                    ios264ThreadHeaderSection
                    actionSection
                    Spacer(minLength: 0)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    isMessageFieldFocused = false
                    isTimeRangeFocused = false
                    isSenderLabelFocused = false
                    KeyboardDismiss.resign()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("设置")
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
                        .lineLimit(3...8)
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
                                await MainActor.run { app.messageImage = image }
                            }
                        }
                    }
                    if let image = app.messageImage {
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
                TextField("09:00-18:00", text: $app.threadTimeRangeInput)
                    .keyboardType(.numbersAndPunctuation)
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
            Text("时间小字样式")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("iOS 26.4 三行样式", isOn: $app.threadHeaderStyleIOS264)
                Text("仅切换时间小字排版，不做系统版本判断。iOS 26.4 及以上用户建议开启，以匹配真机 Messages 样式。")
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
                app.showIMessage = false
                app.showPhoneMenu = false
                app.screen = .notes
            } label: {
                Label("返回备忘录", systemImage: "note.text")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                app.clearNotesAndTitle()
            } label: {
                Label("清除备忘录和标题", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
        }
    }
}
