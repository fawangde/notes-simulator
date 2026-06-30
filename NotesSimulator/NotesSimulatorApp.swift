import FirebaseCore
import SwiftUI

@main
struct NotesSimulatorApp: App {
    @UIApplicationDelegateAdaptor(NotesAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState: AppState

    init() {
        FirebaseBootstrap.configureIfNeeded()
        #if DEBUG
        if FirebaseApp.app() == nil {
            print("[Firebase] configure 未成功，请确认 GoogleService-Info.plist 已加入 NotesSimulator target")
        }
        #endif
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.handleIncomingURL(url)
                }
                .onAppear {
                    appState.consumePendingImportIfNeeded()
                    Task { await AppUpdateController.shared.checkNow() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .noteImportRequested)) { _ in
                    appState.consumePendingImportIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: .noteImportFileOpened)) { note in
                    guard let url = note.object as? URL else { return }
                    appState.handleIncomingURL(url)
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                appState.checkLocalTimeActivationExpiry()
                appState.consumePendingImportIfNeeded()
                Task {
                    await appState.performPeriodicActivationCheck()
                    await PurchaseOrderService.shared.reconcilePendingOrder(app: appState)
                    await AppUpdateController.shared.checkNow()
                }
            }
        }
    }
}
