#if os(Linux)
    import Glibc
    import Cgdlinux
#else
    import Darwin
    import Cgdmac
#endif

import Foundation

// MARK: - LibGd Data Coding

/// Defines a type that can encode any `gdImage` using libgd's built-in **none**-parametrizable `Data` encoding
private protocol CGDDataEncoder: Encoder {

    /// Function pointer to one of libgd's built-in **none**-parametrizable `Data` encoding functions
    var encode: (_ image: gdImagePtr, _ size: UnsafeMutablePointer<Int32>) -> UnsafeMutableRawPointer? { get }

    /// Creates a `Data` representation from given `gdImagePtr`.
    ///
    /// - Parameter image: The `gdImagePtr` to encode
    /// - Returns: The native format for external representation
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> Data
}

/// Defines a type that can encode any `gdImage` using libgd's built-in **parametrizable** `Data` encoding
private protocol CGDParametrizableDataEncoder: Encoder {

    /// The parameters to apply on encoding
    var encodingParameters: Int32 { get }

    /// Function pointer to one of libgd's built-in **parametrizable** `Data` encoding functions
    var encode: (_ image: gdImagePtr, _ size: UnsafeMutablePointer<Int32>, _ parameters: Int32) -> UnsafeMutableRawPointer? { get }

    /// Creates a `Data` representation from given `gdImagePtr` applying `encodingParameters` on encoding.
    ///
    /// - Parameter image: The `gdImagePtr` to encode
    /// - Returns: The native format for external representation
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> Data
}

/// Defines a type that can decode image `Data` representations into `gdImage`s.
private protocol CGDDataDecoder: Decoder {

    /// Function pointer to one of libgd's built-in **parametrizable** `Data` decoding functions
    var decode: (_ size: Int32, _ data: UnsafeMutableRawPointer) -> gdImagePtr? { get }

    /// Creates a `gdImagePtr` from given `Data`.
    ///
    /// - Parameter decodable: The `Data` object to decode an image
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    func decode(decodable: Data) throws -> gdImagePtr
}

/// Defines a type that can be used for both, encoding & decoding, of one of libgd's built-in **none**-parametrizable coding functions
private typealias CGDDataCoder = CGDDataEncoder & CGDDataDecoder

/// Defines a type that can be used for both, encoding & decoding, of one of libgd's built-in **parametrizable** coding functions
private typealias CGDParametrizableDataCoder = CGDParametrizableDataEncoder & CGDDataDecoder

// MARK: Common LibGd Data Coding

extension CGDDataEncoder {
    internal func encode(image: gdImagePtr) throws -> Data {
        var size: Int32 = 0
        guard let bytesPtr = encode(image, &size) else { throw Error.invalidFormat }
        return Data(bytes: bytesPtr, count: Int(size))
    }
}

extension CGDParametrizableDataEncoder {
    internal func encode(image: gdImagePtr) throws -> Data {
        var size: Int32 = 0
        guard let bytesPtr = encode(image, &size, encodingParameters) else {
            throw Error.invalidFormat
        }
        return Data(bytes: bytesPtr, count: Int(size))
    }
}

extension CGDDataDecoder {
    internal func decode(decodable: Data) throws -> gdImagePtr {
        let (pointer, size) = try decodable.memory()
        guard let imagePtr = decode(size, pointer) else { throw Error.invalidFormat }
        return imagePtr
    }
}

// MARK: - Data Encoding & Decoding

/// Defines a coder to be used on BMP `Data` encoding & decoding
private struct BMPDataCoder: CGDParametrizableDataCoder {
    fileprivate let encodingParameters: Int32
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromBmpPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>, Int32) -> UnsafeMutableRawPointer? = gdImageBmpPtr

    /// Initializes a new instance of `Self` using given RLE compression option on encoding
    ///
    /// - Parameter compression:
    ///     Indicates whether to apply RLE compression on encoding or not. Defaults to `false`.
    ///     See [Reference](https://libgd.github.io/manuals/2.2.5/files/gd_bmp-c.html)
    fileprivate init(compression: Bool = false) {
        encodingParameters = compression ? 1 : 0
    }
}

/// Defines a coder to be used on GIF `Data` encoding & decoding
private struct GIFDataCoder: CGDDataCoder {
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromGifPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>) -> UnsafeMutableRawPointer? = gdImageGifPtr
}

/// Defines a coder to be used on JPEG `Data` encoding & decoding
private struct JPGDataCoder: CGDParametrizableDataCoder {
    fileprivate let encodingParameters: Int32
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromJpegPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>, Int32) -> UnsafeMutableRawPointer? = gdImageJpegPtr

    /// Initializes a new instance of `Self` using given quality on encoding.
    ///
    /// For practical purposes, the quality should be a value in the range of `0...95`. For values less than or equal `0`,
    /// the IJG JPEG quality value (which should yield a good general quality / size tradeoff for most situations) is used.
    ///
    /// - Parameter quality:
    ///     Compression quality to apply on encoding. Defaults to the IJG JPEG quality value.
    ///     See [Reference](https://libgd.github.io/manuals/2.2.5/files/gd_jpeg-c.html)
    fileprivate init(quality: Int32 = -1) {
        encodingParameters = quality
    }
}

/// Defines a coder to be used on PNG `Data` encoding & decoding
private struct PNGDataCoder: CGDDataCoder {
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromPngPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>) -> UnsafeMutableRawPointer? = gdImagePngPtr
}

/// Defines a coder to be used on TIFF `Data` encoding & decoding
private struct TIFFDataCoder: CGDDataCoder {
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromTiffPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>) -> UnsafeMutableRawPointer? = gdImageTiffPtr
}

/// Defines a coder to be used on TGA `Data` decoding (TGA does not have native encoding support)
private struct TGADataDecoder: CGDDataDecoder {
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromTgaPtr
}

/// Defines a coder to be used on WBMP `Data` encoding & decoding
private struct WBMPDataCoder: CGDParametrizableDataCoder {
    fileprivate let encodingParameters: Int32
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromWBMPPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>, Int32) -> UnsafeMutableRawPointer? = gdImageWBMPPtr

    /// Initializes a new instance of `Self` using index as foreground color on encodings
    ///
    /// - Parameter index:
    ///     The index of the foreground color used on encoding. Any other value will be considered as background and will not be written.
    ///     See [Reference](https://libgd.github.io/manuals/2.2.5/files/gd_wbmp-c.html)
    fileprivate init(index: Int32) {
        encodingParameters = index
    }
}

/// Defines a coder to be used on WEBP `Data` encoding & decoding
private struct WEBPDataCoder: CGDDataCoder {
    fileprivate let decode: (Int32, UnsafeMutableRawPointer) -> gdImagePtr? = gdImageCreateFromWebpPtr
    fileprivate let encode: (gdImagePtr, UnsafeMutablePointer<Int32>) -> UnsafeMutableRawPointer? = gdImageWebpPtr
}

// MARK: - Raster Format Coding

/// Defines a coder to be used on supported `DecodableRasterFormat` `Data` decoding
internal struct DataDecoder: Decoder {

    /// The raster format of the image represented by data passed to this decoder.
    private let format: DecodableRasterFormat

    /// Initializes a instance of `Self` that will decode data into given raster `format`.
    ///
    /// - Parameter format: The raster format of the image represented by data passed this decoder.
    internal init(of format: DecodableRasterFormat) {
        self.format = format
    }

    /// Creates a `gdImagePtr` from given `Data`.
    ///
    /// - Parameter decodable: The image data representation necessary to decode an image instance
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    internal func decode(decodable data: Data) throws -> gdImagePtr {
        switch format {
        case .bmp: return try BMPDataCoder().decode(decodable: data)
        case .gif: return try GIFDataCoder().decode(decodable: data)
        case .jpg: return try JPGDataCoder().decode(decodable: data)
        case .png: return try PNGDataCoder().decode(decodable: data)
        case .tiff: return try TIFFDataCoder().decode(decodable: data)
        case .tga: return try TGADataDecoder().decode(decodable: data)
        case .wbmp: return try WBMPDataCoder(index: -1).decode(decodable: data)
        case .webp: return try WEBPDataCoder().decode(decodable: data)
        case .any:
            let gdImage: gdImagePtr? = [.jpg, .png, .gif, .webp, .tiff, .bmp, .wbmp].first {
                try? DataDecoder(of: $0).decode(decodable: data)
            }
            if let image = gdImage { return image }
            throw Error.invalidImage(reason: "No matching decoder for given image found")
        }
    }
}

/// Defines a coder to be used on supported `EncodableRasterFormat` `Data` encoding
private struct DataEncoder: Encoder {

    /// The raster format of the to be created/encoded data represention of images passed to this encoder
    fileprivate let format: EncodableRasterFormat

    /// Initializes a instance of `Self` that will decode data into given raster `format`.
    ///
    /// - Parameter format: The raster format of the to be created/encoded data represention of images passed to this encoder
    fileprivate init(of format: EncodableRasterFormat) {
        self.format = format
    }

    /// Creates a `Data` instance from given `gdImagePtr`.
    ///
    /// - Parameter image: The `gdImagePtr` to encode
    /// - Returns: The image data representation of given `image`.
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> Data {
        switch format {

        // Parametrizable image raster format
        case let .bmp(compression): return try BMPDataCoder(compression: compression).encode(image: image)
        case let .jpg(quality): return try JPGDataCoder(quality: quality).encode(image: image)
        case let .wbmp(index): return try WBMPDataCoder(index: index).encode(image: image)

        // None parametrizable image raster format
        case .gif: return try GIFDataCoder().encode(image: image)
        case .png: return try PNGDataCoder().encode(image: image)
        case .tiff: return try TIFFDataCoder().encode(image: image)
        case .webp: return try WEBPDataCoder().encode(image: image)
        }
    }
}

// MARK: - Image Extension

extension Image {

    /// Initializes a new `Image` instance from given image data in specified raster format.
    /// If `format` is omitted, all supported raster formats will be evaluated.
    ///
    /// - Parameters:
    ///   - data: The image data
    ///   - format: The raster format of the image data (e.g. png, webp, ...). Defaults to `.any`
    /// - Throws: `Error` if image `data` in raster `format` could not be decoded
    public convenience init(data: Data, as format: DecodableRasterFormat = .any) throws {
        try self.init(decode: data, using: DataDecoder(of: format))
    }

    /// Exports the image as `Data` object in specified raster format.
    ///
    /// - Parameter format: The raster format of the returning image data (e.g. jpg, png, ...). Defaults to `.png`
    /// - Returns: The image data
    /// - Throws: `Error` if the export of `self` in specified raster format failed.
    public func export(as format: EncodableRasterFormat = .png) throws -> Data {
        return try encode(using: DataEncoder(of: format))
    }
}
