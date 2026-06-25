import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject private var network = NetworkMonitor.shared

    var body: some View {
        ZStack {
            switch app.screen {
            case .home:
                HomeView()
                    .transition(.opacity)
            case .notes:
                NotesView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: app.screen)
        .onAppear {
            app.checkLocalTimeActivationExpiry()
            presentNetworkGuideIfNeeded()
            Task { await PurchaseOrderService.shared.reconcilePendingOrder(app: app) }
        }
        .alert("激活成功", isPresented: $app.showPurchaseActivationSuccessAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text("开发者已确认收款，App 已自动激活。")
        }
        .alert("暂未收到付款", isPresented: $app.showPurchasePaymentRejectedAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text("请联系开发者核实转账信息。")
        }
        .alert("激活失败", isPresented: Binding(
            get: { app.purchaseActivationErrorMessage != nil },
            set: { if !$0 { app.purchaseActivationErrorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(app.purchaseActivationErrorMessage ?? "")
        }
        .alert("激活需要网络", isPresented: $app.showNetworkGuideAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text(
                network.isConnected
                    ? "本 App 激活与校验需要联网，请保持 Wi-Fi 或蜂窝数据可用。"
                    : "当前未检测到网络，请先连接 Wi-Fi 或蜂窝数据，再到设置页输入激活码。"
            )
        }
    }

    private func presentNetworkGuideIfNeeded() {
        guard !NetworkPromptStore.hasShownPrompt else { return }
        NetworkPromptStore.markPromptShown()
        app.showNetworkGuideAlert = true
    }
}
