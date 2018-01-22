#if os(Linux)
	import Glibc
	import Cgdlinux
#else
	import Darwin
	import Cgdmac
#endif

import Foundation

// In case you were wondering: it's a class rather than a struct because we need
// deinit to free the internal GD pointer, and that's only available to classes.
public class Image {
	public enum FlipMode {
		case horizontal, vertical, both
	}

	private var internalImage: gdImagePtr

	public var size: Size {
		return Size(width: internalImage.pointee.sx, height: internalImage.pointee.sy)
	}

	public init?(width: Int, height: Int) {
		internalImage = gdImageCreateTrueColor(Int32(width), Int32(height))
	}

	private init(gdImage: gdImagePtr) {
		self.internalImage = gdImage
	}

	public func resizedTo(width: Int, height: Int, applySmoothing: Bool = true) -> Image? {
		applyInterpolation(enabled: applySmoothing, currentSize: size, newSize: Size(width: width, height: height))

		guard let output = gdImageScale(internalImage, UInt32(width), UInt32(height)) else { return nil }
		return Image(gdImage: output)
	}

	public func resizedTo(width: Int, applySmoothing: Bool = true) -> Image? {
		let currentSize = size
		let heightAdjustment = Double(width) / Double(currentSize.width)
		let newSize = Size(width: Int32(width), height: Int32(Double(currentSize.height) * Double(heightAdjustment)))

		applyInterpolation(enabled: applySmoothing, currentSize: currentSize, newSize: newSize)

		guard let output = gdImageScale(internalImage, UInt32(newSize.width), UInt32(newSize.height)) else { return nil }
		return Image(gdImage: output)
	}

	public func resizedTo(height: Int, applySmoothing: Bool = true) -> Image? {
		let currentSize = size
		let widthAdjustment = Double(height) / Double(currentSize.height)
		let newSize = Size(width: Int32(Double(currentSize.width) * Double(widthAdjustment)), height: Int32(height))

		applyInterpolation(enabled: applySmoothing, currentSize: currentSize, newSize: newSize)

		guard let output = gdImageScale(internalImage, UInt32(newSize.width), UInt32(height)) else { return nil }
		return Image(gdImage: output)
	}

	public func applyInterpolation(enabled: Bool, currentSize: Size, newSize: Size) {
		guard enabled else {
			gdImageSetInterpolationMethod(internalImage, GD_NEAREST_NEIGHBOUR)
			return
		}

		if currentSize > newSize {
			gdImageSetInterpolationMethod(internalImage, GD_SINC)
		} else if currentSize < newSize {
			gdImageSetInterpolationMethod(internalImage, GD_MITCHELL)
		} else {
			gdImageSetInterpolationMethod(internalImage, GD_NEAREST_NEIGHBOUR)
		}
	}

	public func fill(from: Point, color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
		let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageFill(internalImage, Int32(from.x), Int32(from.y), internalColor)
	}

	public func drawLine(from: Point, to: Point, color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
        let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageLine(internalImage, Int32(from.x), Int32(from.y), Int32(to.x), Int32(to.y), internalColor)
	}

	public func set(pixel: Point, to color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
        let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageSetPixel(internalImage, Int32(pixel.x), Int32(pixel.y), internalColor)
	}

	public func get(pixel: Point) -> Color {
		let color = gdImageGetTrueColorPixel(internalImage, Int32(pixel.x), Int32(pixel.y))
        let a = Double((color >> 24) & 0xFF)
        let r = Double((color >> 16) & 0xFF)
        let g = Double((color >> 8) & 0xFF)
        let b = Double(color & 0xFF)

        return Color(red: r / 255, green: g / 255, blue: b / 255, alpha: 1 - (a / 127))
	}

	public func strokeEllipse(center: Point, size: Size, color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
        let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageEllipse(internalImage, Int32(center.x), Int32(center.y), Int32(size.width), Int32(size.height), internalColor)
	}

	public func fillEllipse(center: Point, size: Size, color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
        let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageFilledEllipse(internalImage, Int32(center.x), Int32(center.y), Int32(size.width), Int32(size.height), internalColor)
	}

	public func strokeRectangle(topLeft: Point, bottomRight: Point, color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
        let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageRectangle(internalImage, Int32(topLeft.x), Int32(topLeft.y), Int32(bottomRight.x), Int32(bottomRight.y), internalColor)
	}

	public func fillRectangle(topLeft: Point, bottomRight: Point, color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
        let internalColor = gdImageColorAllocateAlpha(internalImage, red, green, blue, alpha)
		defer { gdImageColorDeallocate(internalImage, internalColor) }

		gdImageFilledRectangle(internalImage, Int32(topLeft.x), Int32(topLeft.y), Int32(bottomRight.x), Int32(bottomRight.y), internalColor)
	}

	public func flip(_ mode: FlipMode) {
		switch mode {
		case .horizontal:
			gdImageFlipHorizontal(internalImage)
		case .vertical:
			gdImageFlipVertical(internalImage)
		case .both:
			gdImageFlipBoth(internalImage)
		}
	}

	public func pixelate(blockSize: Int) {
		gdImagePixelate(internalImage, Int32(blockSize), GD_PIXELATE_AVERAGE.rawValue)
	}

	public func blur(radius: Int) {
		if let result = gdImageCopyGaussianBlurred(internalImage, Int32(radius), -1) {
			gdImageDestroy(internalImage)
			internalImage = result
		}
	}

	public func colorize(using color: Color) {
        let red = Int32(color.redComponent * 255.0)
        let green = Int32(color.greenComponent * 255.0)
        let blue = Int32(color.blueComponent * 255.0)
        let alpha = 127 - Int32(color.alphaComponent * 127.0)
		gdImageColor(internalImage, red, green, blue, alpha)
	}

	public func desaturate() {
		gdImageGrayScale(internalImage)
	}

	deinit {
		// always destroy our internal image resource
		gdImageDestroy(internalImage)
	}
}

// MARK: Encoding & Decoding

extension Image {

    /// Initializes a new `Image` instance using given `decoder` to decode given `Decodable` image representation.
    ///
    /// - Parameters:
    ///    - decodable: The `Decodable` that represents an image.
    ///    - decoder: The `Decoder` that can decode given `Decodable` image representation.
    /// - Returns: An `Image` instance of the image represented by `Decodable`.
    /// - Throws: `Error` if the image representation of `Decodable` could not be decoded.
    internal convenience init<T: Decoder>(decode decodable: T.Decodable, using decoder: T) throws {
        self.init(gdImage: try decoder.decode(decodable: decodable))
    }

    /// Exports the image as `Encodable` using given `encoder` for image encoding
    ///
    /// - Parameter encoder: The `Encoder` to use for encoding the image (`self`) as `Encodable`.
    /// - Returns: The `Encodable` that represents the image (`self`)
    /// - Throws: `Error` if the encoding of `self` using given `encoder` failed.
    internal func encode<T: Encoder>(using encoder: T) throws -> T.Encodable {
        return try encoder.encode(image: internalImage)
    }
}
