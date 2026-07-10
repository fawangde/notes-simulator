import SwiftUI

struct ZGConverterHost: UIViewControllerRepresentable {
    @EnvironmentObject private var app: AppState
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        ZGConverterAccessBridge.canUse = { app.canUseConverter }
        ZGConverterAccessBridge.deniedMessage = app.converterAccessDeniedMessage

        let root = ZGConverterViewController()
        context.coordinator.attach(to: root)
        let nav = UINavigationController(rootViewController: root)
        nav.modalPresentationStyle = .fullScreen

        root.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "关闭",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.close)
        )
        root.title = "超级转换器"

        ConverterRoutingStore.isConverterSessionActive = true
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        ZGConverterAccessBridge.canUse = { app.canUseConverter }
        ZGConverterAccessBridge.deniedMessage = app.converterAccessDeniedMessage
    }

    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
        coordinator.detach()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject {
        let onDismiss: () -> Void
        private weak var viewController: ZGConverterViewController?
        private var importObserver: NSObjectProtocol?

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func attach(to viewController: ZGConverterViewController) {
            self.viewController = viewController
            importObserver = NotificationCenter.default.addObserver(
                forName: .converterImportDidFinish,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let fileName = note.object as? String else { return }
                self?.viewController?.showImportNotice(fileName: fileName)
            }
        }

        func detach() {
            if let importObserver {
                NotificationCenter.default.removeObserver(importObserver)
            }
            importObserver = nil
            viewController = nil
        }

        @objc func close() {
            onDismiss()
        }
    }
}
