import SwiftUI

struct ActivationSheetView: View {
    @Binding var code: String
    let isLoading: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("5 位 1 天 · 6 位 3 天 · 7 位 30 天 · 8 位按次数（字母/数字均可）")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("请输入激活码", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textContentType(.oneTimeCode)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    onConfirm()
                } label: {
                    Text("确认")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("取消", role: .cancel) {
                    onCancel()
                }
                .disabled(isLoading)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("激活 App")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(isLoading)
    }
}
