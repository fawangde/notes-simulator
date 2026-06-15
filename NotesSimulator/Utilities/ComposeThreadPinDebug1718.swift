import Combine
import SwiftUI
import UIKit

/// 1718 聊天区 scroll / pin 探针
/// - 开启：信息页 **长按「取消」** 0.6s
/// - 日志：Xcode 底部 **Debug Console**，搜索 `ThreadPin1718`
/// - 复制：探针面板点 **复制日志**
final class ComposeThreadPinDebug1718: ObservableObject {
    static let shared = ComposeThreadPinDebug1718()
    static let consoleTag = "ThreadPin1718"

    @Published var isEnabled = false
    @Published private(set) var snapshot = Snapshot.empty
    @Published private(set) var eventLog = ""

    private let maxLogLines = 40

    struct Snapshot: Equatable {
        var phase: String
        var source: String
        var prefersTop: Bool
        var pinEngaged: Bool
        var userScrolled: Bool
        var isClosing: Bool
        var offsetY: CGFloat
        var targetY: CGFloat
        var anchorBottom: CGFloat
        var composerPinLine: CGFloat
        var insetBottom: CGFloat
        var reserveDelta: CGFloat
        var gapToPinLine: CGFloat
        var contentH: CGFloat
        var viewportH: CGFloat
        var bubbleRowH: CGFloat
        var bubbleRowW: CGFloat
        var textLines: Int
        var prewarmOffset: CGFloat

        static let empty = Snapshot(
            phase: "—",
            source: "—",
            prefersTop: true,
            pinEngaged: false,
            userScrolled: false,
            isClosing: false,
            offsetY: 0,
            targetY: 0,
            anchorBottom: 0,
            composerPinLine: 0,
            insetBottom: 0,
            reserveDelta: 0,
            gapToPinLine: 0,
            contentH: 0,
            viewportH: 0,
            bubbleRowH: 0,
            bubbleRowW: 0,
            textLines: 0,
            prewarmOffset: 0
        )
    }

    func publish(_ snapshot: Snapshot) {
        let line = snapshot.logLine
        appendLog(line)
        #if DEBUG
        print("[\(Self.consoleTag)] \(line)")
        #endif
        guard isEnabled else { return }
        DispatchQueue.main.async {
            self.snapshot = snapshot
        }
    }

    func log(_ message: String) {
        appendLog(message)
        #if DEBUG
        print("[\(Self.consoleTag)] \(message)")
        #endif
        guard isEnabled else { return }
    }

    func copyLogToPasteboard() {
        UIPasteboard.general.string = eventLog
    }

    func clearLog() {
        eventLog = ""
    }

    private func appendLog(_ line: String) {
        let stamped = "\(Self.timestamp()) \(line)"
        DispatchQueue.main.async {
            if self.eventLog.isEmpty {
                self.eventLog = stamped
            } else {
                self.eventLog += "\n" + stamped
            }
            let lines = self.eventLog.components(separatedBy: "\n")
            if lines.count > self.maxLogLines {
                self.eventLog = lines.suffix(self.maxLogLines).joined(separator: "\n")
            }
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}

extension ComposeThreadPinDebug1718.Snapshot {
    var logLine: String {
        String(
            format: "%@ src=%@ off=%.1f tgt=%.1f gap=%.1f anchor=%.1f pinLn=%.1f inset=%.1f Δres=%.1f pre=%.1f row=%.0fx%.0f L=%d top=%@ pin=%@ close=%@",
            phase,
            source,
            offsetY,
            targetY,
            gapToPinLine,
            anchorBottom,
            composerPinLine,
            insetBottom,
            reserveDelta,
            prewarmOffset,
            bubbleRowW,
            bubbleRowH,
            textLines,
            prefersTop ? "Y" : "N",
            pinEngaged ? "Y" : "N",
            isClosing ? "Y" : "N"
        )
    }
}

/// 关闭信息页期间冻结 scroll reconcile（怎么进怎么出）
enum ComposeThread1718Session {
    static var isClosing = false
}

struct ComposeThreadPinDebugOverlay1718: View {
    @ObservedObject private var debug = ComposeThreadPinDebug1718.shared
    @State private var didCopy = false

    var body: some View {
        if debug.isEnabled {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Pin Debug 1718")
                        .font(.caption.bold())
                    Spacer()
                    Button(didCopy ? "已复制" : "复制日志") {
                        debug.copyLogToPasteboard()
                        didCopy = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            didCopy = false
                        }
                    }
                    .font(.caption2.bold())
                }
                Text("Console 搜: \(ComposeThreadPinDebug1718.consoleTag)")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.75))

                Group {
                    line("phase", debug.snapshot.phase)
                    line("src", debug.snapshot.source)
                    line("offY", debug.snapshot.offsetY)
                    line("tgtY", debug.snapshot.targetY)
                    line("gap", debug.snapshot.gapToPinLine)
                    line("prewarm", debug.snapshot.prewarmOffset)
                    line("Δres", debug.snapshot.reserveDelta)
                    line("close", debug.snapshot.isClosing ? "Y" : "N")
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))

                ScrollView {
                    Text(debug.eventLog.isEmpty ? "（暂无日志）" : debug.eventLog)
                        .font(.system(size: 9, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
            }
            .foregroundStyle(.white)
            .padding(8)
            .frame(width: 300, alignment: .leading)
            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 118)
            .padding(.leading, 6)
            .allowsHitTesting(true)
        }
    }

    private func line(_ key: String, _ value: CGFloat) -> some View {
        Text("\(key): \(value, specifier: "%.1f")")
    }

    private func line(_ key: String, _ value: String) -> some View {
        Text("\(key): \(value)")
    }
}
