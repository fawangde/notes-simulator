import UIKit

/// 单图模式（全系）：仅对「纯白底」图片，把与边缘连通的近白背景压灰，避免与撰写页白底融为一体。
enum ImageBubbleWhiteBackgroundAdjust {
    private static let cache = NSCache<NSString, UIImage>()
    private static let maxAdjustPixels = 1_048_576

    static func displayImage(from image: UIImage?) -> UIImage? {
        guard let image else { return nil }

        let key = cacheKey(for: image)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard isPureWhiteBackgroundImage(image),
              let adjusted = adjustConnectedWhiteBackground(in: image) else {
            cache.setObject(image, forKey: key)
            return image
        }

        cache.setObject(adjusted, forKey: key)
        return adjusted
    }

    // MARK: - Detection

    private static func isPureWhiteBackgroundImage(_ image: UIImage) -> Bool {
        guard let raster = rasterize(image, maxPixelSize: 512) else { return false }

        let width = raster.width
        let height = raster.height
        let data = raster.data
        guard width > 1, height > 1 else { return false }

        var edgeSamples = 0
        var edgeNearWhite = 0

        func sampleEdge(x: Int, y: Int) {
            edgeSamples += 1
            if isNearWhitePixel(data: data, width: width, height: height, x: x, y: y) {
                edgeNearWhite += 1
            }
        }

        for x in 0 ..< width {
            sampleEdge(x: x, y: 0)
            sampleEdge(x: x, y: height - 1)
        }
        for y in 1 ..< height - 1 {
            sampleEdge(x: 0, y: y)
            sampleEdge(x: width - 1, y: y)
        }

        guard edgeSamples > 0 else { return false }
        let edgeRatio = CGFloat(edgeNearWhite) / CGFloat(edgeSamples)
        guard edgeRatio >= IMessageDesignTokens.imageBubbleWhiteBackgroundEdgeRatio else {
            return false
        }

        var interiorSamples = 0
        var interiorNearWhite = 0
        let stepX = max(1, width / 24)
        let stepY = max(1, height / 24)
        var y = 0
        while y < height {
            var x = 0
            while x < width {
                interiorSamples += 1
                if isNearWhitePixel(data: data, width: width, height: height, x: x, y: y) {
                    interiorNearWhite += 1
                }
                x += stepX
            }
            y += stepY
        }

        guard interiorSamples > 0 else { return false }
        let interiorRatio = CGFloat(interiorNearWhite) / CGFloat(interiorSamples)
        return interiorRatio >= IMessageDesignTokens.imageBubbleWhiteBackgroundInteriorRatio
    }

    // MARK: - Adjust

    private static func adjustConnectedWhiteBackground(in image: UIImage) -> UIImage? {
        guard var raster = rasterize(image, maxPixelSize: 2048) else { return nil }

        let width = raster.width
        let height = raster.height
        guard width > 0, height > 0, width * height <= maxAdjustPixels else { return nil }

        var background = [Bool](repeating: false, count: width * height)
        var stack: [(Int, Int)] = []
        stack.reserveCapacity(width * 2 + height * 2)

        func trySeed(x: Int, y: Int) {
            guard isNearWhitePixel(data: raster.data, width: width, height: height, x: x, y: y) else { return }
            let index = y * width + x
            guard !background[index] else { return }
            background[index] = true
            stack.append((x, y))
        }

        for x in 0 ..< width {
            trySeed(x: x, y: 0)
            trySeed(x: x, y: height - 1)
        }
        for y in 0 ..< height {
            trySeed(x: 0, y: y)
            trySeed(x: width - 1, y: y)
        }

        while let (x, y) = stack.popLast() {
            if x > 0 { trySeed(x: x - 1, y: y) }
            if x + 1 < width { trySeed(x: x + 1, y: y) }
            if y > 0 { trySeed(x: x, y: y - 1) }
            if y + 1 < height { trySeed(x: x, y: y + 1) }
        }

        let replacement = IMessageDesignTokens.imageBubbleWhiteBackgroundReplacementRGB
        for y in 0 ..< height {
            for x in 0 ..< width {
                let index = y * width + x
                guard background[index] else { continue }
                let offset = index * 4
                raster.data[offset] = replacement.r
                raster.data[offset + 1] = replacement.g
                raster.data[offset + 2] = replacement.b
                raster.data[offset + 3] = 255
            }
        }

        return makeImage(from: raster)
    }

    // MARK: - Raster helpers

    private struct Raster {
        var data: [UInt8]
        let width: Int
        let height: Int
        let scale: CGFloat
    }

    private static func rasterize(_ image: UIImage, maxPixelSize: Int) -> Raster? {
        let pixelSize = orientedPixelSize(for: image)
        guard pixelSize.width > 0, pixelSize.height > 0 else { return nil }

        let maxSide = max(pixelSize.width, pixelSize.height)
        let downscale = maxSide > CGFloat(maxPixelSize) ? CGFloat(maxPixelSize) / maxSide : 1
        let drawSize = CGSize(
            width: max(1, round(pixelSize.width * downscale)),
            height: max(1, round(pixelSize.height * downscale))
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let normalized = UIGraphicsImageRenderer(size: drawSize, format: format).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: drawSize))
            image.draw(in: CGRect(origin: .zero, size: drawSize))
        }

        guard let cgImage = normalized.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        var data = [UInt8](repeating: 255, count: width * height * 4)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Raster(data: data, width: width, height: height, scale: image.scale * downscale)
    }

    private static func orientedPixelSize(for image: UIImage) -> CGSize {
        guard let cgImage = image.cgImage else { return image.size }
        let pixelW = CGFloat(cgImage.width)
        let pixelH = CGFloat(cgImage.height)
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: pixelH, height: pixelW)
        default:
            return CGSize(width: pixelW, height: pixelH)
        }
    }

    private static func makeImage(from raster: Raster) -> UIImage? {
        var data = raster.data
        guard let context = CGContext(
            data: &data,
            width: raster.width,
            height: raster.height,
            bitsPerComponent: 8,
            bytesPerRow: raster.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: raster.scale, orientation: .up)
    }

    private static func isNearWhitePixel(data: [UInt8], width: Int, height: Int, x: Int, y: Int) -> Bool {
        guard x >= 0, x < width, y >= 0, y < height else { return false }
        let offset = (y * width + x) * 4
        guard offset + 3 < data.count else { return false }
        let alpha = data[offset + 3]
        guard alpha >= IMessageDesignTokens.imageBubbleWhiteBackgroundMinAlpha else { return false }

        let threshold = IMessageDesignTokens.imageBubbleWhiteBackgroundNearWhiteThreshold
        let r = data[offset]
        let g = data[offset + 1]
        let b = data[offset + 2]
        return r >= threshold && g >= threshold && b >= threshold
    }

    private static func cacheKey(for image: UIImage) -> NSString {
        let sizeKey = "\(Int(image.size.width))x\(Int(image.size.height))@\(image.scale)"
        let orientKey = image.imageOrientation.rawValue
        if let cgImage = image.cgImage {
            return "\(ObjectIdentifier(cgImage).hashValue)|\(sizeKey)|\(orientKey)" as NSString
        }
        return "\(sizeKey)|\(orientKey)|\(ObjectIdentifier(image).hashValue)" as NSString
    }
}
