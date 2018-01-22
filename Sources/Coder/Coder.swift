#if os(Linux)
    import Glibc
    import Cgdlinux
#else
    import Darwin
    import Cgdmac
#endif

import Foundation

// MARK: - Generic Coding

/// Defines a type that can encode any `gdImage` into a native format for external representation.
internal protocol Encoder {

    /// The native format for external representation
    associatedtype Encodable

    /// Creates an `Encodable` instance from given `gdImagePtr`.
    ///
    /// - Parameters:
    ///   - image: The `gdImagePtr` to encode
    /// - Returns: The native format for external representation
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> Encodable
}

/// Defines a type that can decode any `Decodable` from a native format (e.g. file, data, ...) into `gdImage` representations.
internal protocol Decoder {

    /// The object necessary to decode an image
    associatedtype Decodable

    /// Creates a `gdImagePtr` from given `Decodable`.
    ///
    /// - Parameter decodable: The object necessary to decode an image
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    func decode(decodable: Decodable) throws -> gdImagePtr
}

/// Defines a type that can be used for both, encoding & decoding.
internal typealias Coder = Encoder & Decoder

// MARK: - RasterFormat Coder

extension EncodableRasterFormat {

    /// The parameters to apply on encoding
    internal var encodingParameters: Int32 {
        switch self {
        // Parametrizable formats
        case let .bmp(compression): return compression ? 1 : 0
        case let .jpg(quality, _): return quality
        case let .png(compression, _): return min(max(compression, -1), 9) // -1 -> default, 0 -> none, 1-9 -> level
        case let .wbmp(index): return index
        // None parametrizable formats
        case .gif, .tiff, .webp: return -1
        }
    }

    /// Whether the alpha channel of the pixels should be saved on encoding. `nil` will leave this settings "as is".
    private var alpha: Bool? {
        switch self {
        case .png(_, let alpha): return alpha
        case .bmp, .gif, .jpg, .tiff, .wbmp, .webp:
            return nil
        }
    }

    /// Sets whether an image should be interlaced encoded. `nil` will leave this settings "as is".
    private var interlaced: Bool? {
        switch self {
        case .jpg(_, let progressive): return progressive
        case .bmp, .gif, .png, .tiff, .wbmp, .webp:
            return nil
        }
    }

    /// Prepares given image for encoding
    ///
    /// - Parameter image: The image to prepare for encoding
    internal func prepare(image: gdImagePtr) {
        if let alpha = alpha { gdImageSaveAlpha(image, alpha ? 1 : 0) }
        if let interlaced = interlaced { gdImageInterlace(image, interlaced ? 1 : 0) }
    }
}

extension DecodableRasterFormat {

    /// Initializes a `DecodableRasterFormat` that matches the raster format as identified by given file/path extension.
    /// Extensions are copied from wikipedia (see links at description)
    ///
    /// - Parameter pathExtension: The file/path extension to evaluate if matching raster format exists.
    internal init?(pathExtension: String) {
        switch pathExtension {
        case "bmp", "dib":
            self = .bmp
        case "gif":
            self = .gif
        case "jpg", "jpeg", "jpe", "jif", "jfif", "jfi":
            self = .jpg
        case "png":
            self = .png
        case "tiff", "tif":
            self = .tiff
        case "tga", "icb", "vda", "vst":
            self = .tga
        case "wbmp":
            self = .wbmp
        case "webp":
            self = .webp
        default:
            return nil
        }
    }
}
