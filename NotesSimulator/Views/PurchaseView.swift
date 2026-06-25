import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: PurchaseProduct?
    @State private var selectedClickCount = 1
    @State private var selectedPayment: PurchasePaymentMethod = .wechat
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var waitingForConfirmation = false
    @State private var showRejectionAlert = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    productSection
                    if let selectedProduct {
                        if selectedProduct.isClickBased {
                            clickCountSection
                        }
                        amountSection(for: selectedProduct)
                        paymentSection
                        paymentDetailSection(for: selectedProduct)
                    } else {
                        Text("请先选择上方套餐，再选择收款方式并完成支付。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    if waitingForConfirmation {
                        waitingBanner
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("购买激活")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                Task { await resumePendingOrderIfNeeded() }
            }
            .onDisappear {
                if !waitingForConfirmation {
                    PurchaseOrderService.shared.stopObserving()
                }
            }
            .alert("暂未收到付款", isPresented: $showRejectionAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请联系开发者核实转账信息。")
            }
            .alert("激活成功", isPresented: $showSuccessAlert) {
                Button("好") {
                    dismiss()
                }
            } message: {
                Text("开发者已确认收款，App 已自动激活。")
            }
        }
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("选择套餐")
            ForEach(PurchaseProduct.allCases) { product in
                Button {
                    selectedProduct = product
                    errorMessage = nil
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.title)
                                .font(.headline)
                            Text(product.listSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedProduct == product {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var clickCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("购买次数")
            Picker("次数", selection: $selectedClickCount) {
                ForEach(PurchaseConfig.minClickCount...PurchaseConfig.maxClickCount, id: \.self) { count in
                    Text("\(count) 次").tag(count)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .clipped()
            Text("单价 ¥\(PurchaseConfig.pricePerClick)/次，滑动选择次数。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func amountSection(for product: PurchaseProduct) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("应付金额")
            if let amount = resolvedAmount(for: product) {
                Text(product.priceText(clickCount: parsedClickCount()))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                if product.isClickBased, let count = parsedClickCount() {
                    Text("\(count) 次 × ¥\(PurchaseConfig.pricePerClick) = ¥\(amount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("请按上方金额准确转账，金额不符将无法确认。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("请输入有效次数")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("收款方式")
            Picker("收款方式", selection: $selectedPayment) {
                ForEach(PurchasePaymentMethod.allCases) { method in
                    Text(method.title).tag(method)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func paymentDetailSection(for product: PurchaseProduct) -> some View {
        if resolvedAmount(for: product) == nil {
            EmptyView()
        } else if selectedPayment.showsQRCode {
            onlinePaymentSection(for: product)
        } else {
            faceToFacePaymentSection(for: product)
        }
    }

    private func faceToFacePaymentSection(for product: PurchaseProduct) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("面子支付")
            Text("已与开发者协商好付款方式。完成付款后，点击下方按钮提交订单，等待开发者确认。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("订单标识：\(PurchaseOrderService.shared.deviceMemo())")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)

            Button {
                Task { await submitPaidOrder(product: product) }
            } label: {
                Text(isSubmitting ? "提交中…" : "我已支付")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting || waitingForConfirmation)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func onlinePaymentSection(for product: PurchaseProduct) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("扫码支付")

            qrImage(for: selectedPayment)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("转账金额：\(product.priceText(clickCount: parsedClickCount()))")
                Text("转账备注：\(PurchaseOrderService.shared.deviceMemo())")
                Text("备注必填，便于开发者核对订单。")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button {
                Task { await submitPaidOrder(product: product) }
            } label: {
                Text(isSubmitting ? "提交中…" : "我已支付")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting || waitingForConfirmation)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var waitingBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 4) {
                Text("等待开发者确认收款")
                    .font(.subheadline.bold())
                Text("可退出 App 或切到后台；确认后会自动激活。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func qrImage(for method: PurchasePaymentMethod) -> some View {
        let assetName = method == .wechat
            ? PurchaseConfig.wechatQRAssetName
            : PurchaseConfig.alipayQRAssetName

        if let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .padding(12)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "qrcode")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("请在 Assets 中添加 \(assetName) 收款码图片")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func parsedClickCount() -> Int? {
        guard let product = selectedProduct, product.isClickBased else { return nil }
        return selectedClickCount
    }

    private func resolvedAmount(for product: PurchaseProduct) -> Int? {
        if product.isClickBased {
            return product.amountYuan(clickCount: selectedClickCount)
        }
        return product.amountYuan()
    }

    private func resumePendingOrderIfNeeded() async {
        guard let orderId = PurchaseOrderStore.pendingOrderId else { return }
        waitingForConfirmation = true
        await PurchaseOrderService.shared.reconcilePendingOrder(app: app)
        observeOrder(orderId: orderId)
    }

    private func submitPaidOrder(product: PurchaseProduct) async {
        guard NetworkMonitor.shared.isConnected else {
            errorMessage = PurchaseOrderError.networkUnavailable.errorDescription
            return
        }
        guard resolvedAmount(for: product) != nil else {
            errorMessage = PurchaseOrderError.invalidClickCount.errorDescription
            return
        }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let orderId = try await PurchaseOrderService.shared.submitPaidOrder(
                product: product,
                paymentMethod: selectedPayment,
                clickCount: parsedClickCount()
            )
            waitingForConfirmation = true
            observeOrder(orderId: orderId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observeOrder(orderId: String) {
        PurchaseOrderService.shared.observePendingOrder(orderId: orderId) { order in
            guard let order else { return }
            Task { @MainActor in
                await PurchaseOrderService.shared.applyOrderOutcome(order, app: app)
                switch order.status {
                case .userClaimedPaid:
                    waitingForConfirmation = true
                case .fulfilled:
                    waitingForConfirmation = false
                    if app.isActivated {
                        showSuccessAlert = true
                    } else if let message = app.purchaseActivationErrorMessage {
                        errorMessage = message
                    }
                case .rejected:
                    waitingForConfirmation = false
                    showRejectionAlert = true
                }
            }
        }
    }
}

#Preview {
    PurchaseView()
        .environmentObject(AppState())
}
