import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState

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
    }
}
