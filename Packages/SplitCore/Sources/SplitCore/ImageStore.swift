import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Stores optional bill photos on disk (extension Application Support).
public final class ImageStore: @unchecked Sendable {
    private let imagesDirectory: URL?

    public init(appGroupID: String? = nil) {
        let base: URL?
        if let appGroupID,
           let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
           ) {
            base = groupURL
        } else {
            base = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first?.appendingPathComponent("Split", isDirectory: true)
        }

        if let base {
            let images = base.appendingPathComponent("images", isDirectory: true)
            try? FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
            imagesDirectory = images
        } else {
            imagesDirectory = nil
        }
    }

    public func fileName(for expenseId: UUID) -> String {
        "images/\(expenseId.uuidString).jpg"
    }

    public func saveJPEG(data: Data, expenseId: UUID) -> String? {
        guard let imagesDirectory else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent("\(expenseId.uuidString).jpg")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName(for: expenseId)
        } catch {
            return nil
        }
    }

    public func loadData(fileName: String) -> Data? {
        guard let imagesDirectory else { return nil }
        let name = (fileName as NSString).lastPathComponent
        let fileURL = imagesDirectory.appendingPathComponent(name)
        return try? Data(contentsOf: fileURL)
    }

    public func delete(fileName: String) {
        guard let imagesDirectory else { return }
        let name = (fileName as NSString).lastPathComponent
        let fileURL = imagesDirectory.appendingPathComponent(name)
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
