import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Stores optional bill photos in the App Group container (not in the message URL).
public final class ImageStore: @unchecked Sendable {
    private let containerURL: URL?

    public init(appGroupID: String) {
        containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("images", isDirectory: true)
        if let containerURL {
            try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
    }

    public func fileName(for expenseId: UUID) -> String {
        "images/\(expenseId.uuidString).jpg"
    }

    public func saveJPEG(data: Data, expenseId: UUID) -> String? {
        guard let root = containerURL else { return nil }
        let fileURL = root.appendingPathComponent("\(expenseId.uuidString).jpg")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName(for: expenseId)
        } catch {
            return nil
        }
    }

    public func loadData(fileName: String) -> Data? {
        guard let root = containerURL?.deletingLastPathComponent() else { return nil }
        let fileURL = root.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    public func delete(fileName: String) {
        guard let root = containerURL?.deletingLastPathComponent() else { return }
        let fileURL = root.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

#if canImport(UIKit)
    /// Downscales and compresses for bubble + disk storage.
    public static func compressedJPEG(from image: UIImage, maxDimension: CGFloat = 960, quality: CGFloat = 0.72) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.jpegData(compressionQuality: quality)
    }
#endif
}
