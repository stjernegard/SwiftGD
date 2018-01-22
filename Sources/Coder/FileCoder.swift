#if os(Linux)
    import Glibc
    import Cgdlinux
#else
    import Darwin
    import Cgdmac
#endif

import Foundation

// MARK: - File

/// The input values for file encodings
private struct File {

    /// Whether or not override existing file
    fileprivate let override: Bool

    /// The output file path
    fileprivate let url: URL
}

// MARK: - Decoding

extension DecodableRasterFormat {

    /// Function pointer to one of libgd's built-in FILE decoding functions
    fileprivate var decode: (_ file: UnsafeMutablePointer<FILE>) -> gdImagePtr? {
        switch self {
        case .bmp: return gdImageCreateFromBmp
        case .gif: return gdImageCreateFromWebp
        case .jpg: return gdImageCreateFromJpeg
        case .png: return gdImageCreateFromPng
        case .tiff: return gdImageCreateFromTiff
        case .tga: return gdImageCreateFromTga
        case .wbmp: return gdImageCreateFromWBMP
        case .webp: return gdImageCreateFromWebp
        }
    }
}

/// Defines a coder to be used on supported `DecodableRasterFormat` decoding
private struct FileDecoder: Decoder {

    /// The raster format of the image represented by files passed to this decoder
    fileprivate let format: DecodableRasterFormat

    /// Creates a `gdImagePtr` from given file at `URL`.
    ///
    /// - Parameter decodable: The image representation as file necessary to decode an image instance
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    fileprivate func decode(decodable: URL) throws -> gdImagePtr {
        guard let inputFile = fopen(decodable.path, "rb") else { // Open for reading as binary
            throw Error.errorReadingFile(reason: "Can not open file at path: \(decodable.path)")
        }
        defer { fclose(inputFile) } // File is opened by now, defer close
        guard let image: gdImagePtr = format.decode(inputFile) else {
            throw Error.invalidFormat
        }
        return image
    }
}

/// Defines a coder to be used on multiple possible supported `DecodableRasterFormat` file encodings
private struct CollectionFileDecoder: Decoder {

    /// The raster formats of the images represented by files passed to this decoder
    fileprivate let formats: [DecodableRasterFormat]

    /// Creates a `gdImagePtr` from given file at `URL`.
    ///
    /// - Parameter decodable: The image representation as file necessary to decode an image instance
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    func decode(decodable: URL) throws -> gdImagePtr {
        for format in formats {
            if let result = try? FileDecoder(format: format).decode(decodable: decodable) {
                return result
            }
        }
        throw Error.invalidImage(reason: "No matching decoder for given image found")
    }
}

// MARK: - Encoding

extension EncodableRasterFormat {

    /// Function pointer to one of libgd's built-in FILE encoding functions
    fileprivate var encode: (_ image: gdImagePtr, _ file: UnsafeMutablePointer<FILE>, _ parameters: Int32) -> Void {
        switch self {
        case .bmp: return gdImageBmp
        case .jpg: return gdImageJpeg
        case .png: return gdImagePngEx
        // File ($1) and parameters ($2) are swapped on WBMP file import
        case .wbmp: return { gdImageWBMP($0, $2, $1) }
        // None-parametrizable formats (strips parameters)
        case .gif: return { image, file, _ in gdImageGif(image, file) }
        case .tiff: return { image, file, _ in gdImageTiff(image, file) }
        case .webp: return { image, file, _ in gdImageWebp(image, file) }
        }
    }
}

/// Defines a coder to be used on supported `EncodableRasterFormat` file encoding
private struct FileEncoder: Encoder {

    /// The output file description
    fileprivate let outputFile: File

    /// The raster format of the to be created/encoded file represention of images passed to this encoder
    fileprivate let format: EncodableRasterFormat

    /// Creates a file instance from given `gdImagePtr`.
    ///
    /// - Parameter image: The `gdImagePtr` to encode
    /// - Returns: The image file url of the written `image`.
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> URL {

        let fileManager: FileManager = .default
        let path: String = outputFile.url.path

        // Refuse to overwrite existing files if not explicitly specified
        guard outputFile.override || !fileManager.fileExists(atPath: path) else {
            throw Error.errorWritingFile(reason: "File at \(path) already exists. Refuse to override.")
        }

        // Open output file for writing binary
        guard let file = fopen(path, "wb") else {
            throw Error.errorWritingFile(reason: "Can not write file at path: \(path)")
        }

        // Write to the output file
        format.prepare(image: image)
        format.encode(image, file, format.encodingParameters)
        fclose(file)

        // Final validation
        guard fileManager.fileExists(atPath: path) else {
            throw Error.errorWritingFile(reason: "Failed to write file at path: \(path)")
        }

        return outputFile.url
    }
}

// MARK: - Image Extension

extension Image {

    /// Initializes a new `Image` instance from given image file in specified raster format.
    ///
    /// - Parameters:
    ///   - url: The image file
    ///   - format: The raster format of the image file (e.g. png, webp, ...)
    /// - Throws: `Error` if image file at `url` in raster `format` could not be decoded
    public convenience init(from url: URL, as format: DecodableRasterFormat) throws {
        try self.init(decode: url, using: FileDecoder(format: format))
    }

    /// Initializes a new `Image` instance from given image file in specified raster format.
    /// If formats are omitted, the file ending will be used to find a proper encoding - otherwise all raster formats will be evaluated.
    ///
    /// - Parameters:
    ///   - url: The image file
    ///   - formats: List of possible raster formats of the image data. Defaults to `.any`
    /// - Throws: `Error` if image file at `url` is not of any of the given raster `formats`
    public convenience init(from url: URL, as oneOf: [DecodableRasterFormat] = DecodableRasterFormat.any) throws {
        // Find the format based on the path extension and set it as the first to evaluate
        if let formatBasedOnExtension = DecodableRasterFormat(pathExtension: url.pathExtension) {
            try self.init(decode: url, using: CollectionFileDecoder(formats: [formatBasedOnExtension] + oneOf))
        } else {
            try self.init(decode: url, using: CollectionFileDecoder(formats: oneOf))
        }

    }

    /// Writes the image to given file url in specified raster format.
    ///
    /// - Parameters:
    ///   - url: The url of the file to write
    ///   - override: Whether or not to override a possibly existing file at `url`
    ///   - format: The raster format of the image to write. Defaults to `.png` with alpha channel and default compression.
    /// - Returns: The file url of the written image
    /// - Throws: `Error` if the writing `self` in specified raster format at given `url` failed
    @discardableResult public func write(to url: URL, override: Bool = false, as format: EncodableRasterFormat = .default) throws -> URL {
        return try encode(using: FileEncoder(outputFile: File(override: override, url: url), format: format))
    }
}
