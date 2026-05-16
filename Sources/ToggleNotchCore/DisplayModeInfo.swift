import Foundation

public struct DisplayModeInfo: Codable, Equatable, Hashable, Sendable {
    public var width: Int
    public var height: Int
    public var pixelWidth: Int
    public var pixelHeight: Int
    public var refreshRate: Double
    public var ioFlags: UInt32

    public init(
        width: Int,
        height: Int,
        pixelWidth: Int,
        pixelHeight: Int,
        refreshRate: Double,
        ioFlags: UInt32 = 0
    ) {
        self.width = width
        self.height = height
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.refreshRate = refreshRate
        self.ioFlags = ioFlags
    }

    public var description: String {
        let refresh = refreshRate == 0 ? "unknownHz" : String(format: "%.2fHz", refreshRate)
        return "\(width)x\(height) logical, \(pixelWidth)x\(pixelHeight) pixels, \(refresh)"
    }
}
