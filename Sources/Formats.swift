import Foundation

/// Decodable raster formats
///
/// - bmp: https://en.wikipedia.org/wiki/bmp_file_format
/// - gif: https://en.wikipedia.org/wiki/gif
/// - jpg: https://en.wikipedia.org/wiki/jpeg
/// - png: https://en.wikipedia.org/wiki/portable_network_graphics
/// - tiff: https://en.wikipedia.org/wiki/tiff
/// - tga: https://en.wikipedia.org/wiki/truevision_tga
/// - wbmp: https://en.wikipedia.org/wiki/wbmp
/// - webp: https://en.wikipedia.org/wiki/webp
/// - any: Evaluates all of the above mentioned formats on decoding
public enum DecodableRasterFormat {
    case bmp
    case gif
    case jpg
    case png
    case tiff
    case tga
    case wbmp
    case webp
    case any // Wildcard
}

/// Encodable raster formats
///
/// - bmp: https://en.wikipedia.org/wiki/bmp_file_format
/// - gif: https://en.wikipedia.org/wiki/gif
/// - jpg: https://en.wikipedia.org/wiki/jpeg
/// - png: https://en.wikipedia.org/wiki/portable_network_graphics
/// - tiff: https://en.wikipedia.org/wiki/tiff
/// - wbmp: https://en.wikipedia.org/wiki/wbmp
/// - webp: https://en.wikipedia.org/wiki/webp
/// - any: Evaluates all of the above mentioned formats on export
public enum EncodableRasterFormat {
    case bmp(compression: Bool)
    case gif
    case jpg(quality: Int32)
    case png
    case tiff
    case wbmp(index: Int32)
    case webp
}
