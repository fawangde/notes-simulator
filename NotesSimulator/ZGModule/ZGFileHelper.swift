import UIKit

final class ZGFileHelper: NSObject {
    static let shared = ZGFileHelper()

    let txtFolder: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/TXTFiles"
    let vcfFolder: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/VCFFiles"

    override init() {
        super.init()
        createFolderIfNeeded(path: txtFolder)
        createFolderIfNeeded(path: vcfFolder)
    }

    func createFolderIfNeeded(path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }

    func allTXTFiles() -> [String] {
        do {
            let all = try FileManager.default.contentsOfDirectory(atPath: txtFolder)
            return all.filter { $0.hasSuffix(".txt") }.map { txtFolder + "/" + $0 }
        } catch {
            return []
        }
    }

    func allVCFFiles() -> [String] {
        do {
            let all = try FileManager.default.contentsOfDirectory(atPath: vcfFolder)
            return all.filter { $0.hasSuffix(".vcf") }.map { vcfFolder + "/" + $0 }
        } catch {
            return []
        }
    }

    func clearAllTXT() {
        allTXTFiles().forEach {
            try? FileManager.default.removeItem(atPath: $0)
        }
    }

    func clearAllVCF() {
        allVCFFiles().forEach {
            try? FileManager.default.removeItem(atPath: $0)
        }
    }

    func formatPhone(_ num: String) -> String {
        if num.count == 11 {
            let part1 = num.prefix(3)
            let part2 = num.dropFirst(3).prefix(4)
            let part3 = num.suffix(4)
            return "+86 \(part1) \(part2) \(part3)"
        }
        return num
    }

    func saveSharedFile(url: URL) -> Bool {
        let fileName = url.lastPathComponent
        let toPath = txtFolder + "/" + fileName

        if FileManager.default.fileExists(atPath: toPath) {
            try? FileManager.default.removeItem(atPath: toPath)
        }

        do {
            try FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: toPath))
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func saveImportedText(fileName: String, content: String) -> Bool {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let name = trimmed.lowercased().hasSuffix(".txt") ? trimmed : trimmed + ".txt"
        let toPath = txtFolder + "/" + name
        if FileManager.default.fileExists(atPath: toPath) {
            try? FileManager.default.removeItem(atPath: toPath)
        }
        do {
            try content.write(toFile: toPath, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
}
