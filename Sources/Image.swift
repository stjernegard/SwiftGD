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
public final class Image {

    /// The underlying image to manage and process
	private var internalImage: gdImagePtr

    /// The size of the image in pixel
    public var size: Size {
        return Size(width: internalImage.pointee.sx, height: internalImage.pointee.sy)
    }

    /// Initializes a new image handling/representing given `gdImagePtr`
    ///
    /// - Parameter gdImage: The underlying image of the `Image` instance to be created.
    private init(gdImage: gdImagePtr) {
        internalImage = gdImage
    }

    /// Destroys the internal image resource
    deinit {
        gdImageDestroy(internalImage)
    }
}

// MARK: Generic True Color Image

extension Image {

    /// Initializes a new true color image of given size
    ///
    /// - Parameters:
    ///   - width: The width of the image
    ///   - height: The height of the image
    public convenience init(width: Int32, height: Int32) throws {
        try self.init(size: Size(width: width, height: height))
    }

    /// Initializes a new true color image of given size
    ///
    /// - Parameters:
    ///   - size: The size of the image
    public convenience init(size: Size) throws {
        guard let image = gdImageCreateTrueColor(size.width, size.height) else {
            throw Error.invalidImage(reason: "True color image of size \(size.width)x\(size.height) could not be created")
        }
        self.init(gdImage: image)
    }
}

// MARK: Image Coding

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

// MARK: - Drawing

extension Image {

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
}

// MARK: - Resizing

extension Image {

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

	public func resizedTo(width: Int32, height: Int32, applySmoothing: Bool = true) -> Image? {
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
}

// MARK: - Manipulating

extension Image {

    /// Describes the axis around which the image should be flipped
    ///
    /// - horizontal: Flips the image horizontally
    /// - vertical: Flips the image vertically
    /// - both: Flips the image around both axis, horizontally & vertically
    public enum FlipMode {
        case horizontal
        case vertical
        case both
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
}
