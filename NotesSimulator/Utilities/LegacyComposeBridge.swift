import Foundation

/// iOS 17 气泡尾巴：当前与 1718 共用实现，后续可独立微调。
enum IMessage17BubbleTailPreset {
    static var defaultPresetID: String { IMessage1718BubbleTailPreset.defaultPresetID }

    static func resolvedParams(
        presetID: String,
        tuning: Notes17TuningSettings? = nil
    ) -> IMessage1718BubbleTailParams {
        IMessage1718BubbleTailPreset.resolvedParams(
            presetID: presetID,
            tuning: tuning?.bridgedTo1718()
        )
    }
}

/// iOS 18 气泡尾巴：当前与 1718 共用实现，后续可独立微调。
enum IMessage18BubbleTailPreset {
    static var defaultPresetID: String { IMessage1718BubbleTailPreset.defaultPresetID }

    static func resolvedParams(
        presetID: String,
        tuning: Notes18TuningSettings? = nil
    ) -> IMessage1718BubbleTailParams {
        IMessage1718BubbleTailPreset.resolvedParams(
            presetID: presetID,
            tuning: tuning?.bridgedTo1718()
        )
    }
}

enum ComposeThread17PinWarmup {
    @MainActor
    static func refresh(app: AppState, keyboardTopInset: CGFloat = 0) {
        ComposeThread1718PinWarmup.refresh(app: app, keyboardTopInset: keyboardTopInset)
    }
}

enum ComposeThread18PinWarmup {
    @MainActor
    static func refresh(app: AppState, keyboardTopInset: CGFloat = 0) {
        ComposeThread1718PinWarmup.refresh(app: app, keyboardTopInset: keyboardTopInset)
    }
}
