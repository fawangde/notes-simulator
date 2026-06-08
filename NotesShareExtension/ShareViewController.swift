import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var didStart = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStart else { return }
        didStart = true
        importSharedItems()
    }

    private func importSharedItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            finish()
            return
        }

        for item in items {
            let suggestedTitle = item.attributedTitle?.string ?? "导入备忘录"
            guard let providers = item.attachments else { continue }
            for provider in providers {
                if loadFile(from: provider) { return }
                if loadText(from: provider, title: suggestedTitle) { return }
            }
        }
        finish()
    }

    private func loadFile(from provider: NSItemProvider) -> Bool {
        let types = [
            UTType.fileURL.identifier,
            UTType.plainText.identifier,
            UTType.text.identifier,
            UTType.data.identifier,
        ]
        guard let type = types.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: type) { [weak self] loaded, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if let url = loaded as? URL {
                    self.importFile(url: url)
                    return
                }
                if let text = loaded as? String {
                    let payload = ImportPayload.parseText(text, title: "导入备忘录")
                    ImportPayload.queue(payload)
                    self.openHostApp()
                    return
                }
                if let data = loaded as? Data,
                   let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .unicode) {
                    let payload = ImportPayload.parseText(text, title: "导入备忘录")
                    ImportPayload.queue(payload)
                    self.openHostApp()
                    return
                }
                self.finish()
            }
        }
        return true
    }

    private func loadText(from provider: NSItemProvider, title: String) -> Bool {
        guard provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
            || provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) else {
            return false
        }
        let type = provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
            ? UTType.plainText.identifier
            : UTType.text.identifier
        provider.loadItem(forTypeIdentifier: type) { [weak self] loaded, _ in
            DispatchQueue.main.async {
                guard let self, let text = loaded as? String else {
                    self?.finish()
                    return
                }
                let payload = ImportPayload.parseText(text, title: title)
                ImportPayload.queue(payload)
                self.openHostApp()
            }
        }
        return true
    }

    private func importFile(url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .unicode) else {
            finish()
            return
        }
        let title = url.deletingPathExtension().lastPathComponent
        let payload = ImportPayload.parseText(text, title: title)
        ImportPayload.queue(payload)
        openHostApp()
    }

    private func openHostApp() {
        guard let url = URL(string: "notesimulator://import") else {
            finish()
            return
        }
        // 稍等 App Group 落盘后再唤起主 App，避免主 App 读不到待导入数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else { return }
            self.extensionContext?.open(url) { _ in
                DispatchQueue.main.async {
                    self.finish()
                }
            }
        }
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
