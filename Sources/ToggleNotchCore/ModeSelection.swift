import Foundation

public enum ModeSelectionError: Error, Equatable, CustomStringConvertible {
    case noPairedLowerMode(DisplayModeInfo)
    case noPairedHigherMode(DisplayModeInfo)

    public var description: String {
        switch self {
        case .noPairedLowerMode(let mode):
            "No lower-height notch display mode found for \(mode.description)."
        case .noPairedHigherMode(let mode):
            "No higher-height notch display mode found for \(mode.description)."
        }
    }
}

public enum NotchModeState: String, Equatable, Sendable {
    case hidden
    case full
    case unsupported
}

public struct ModeSelector: Sendable {
    public init() {}

    public func modeToHide(current: DisplayModeInfo, available modes: [DisplayModeInfo]) throws -> DisplayModeInfo {
        let candidates = pairedModes(for: current, in: modes)
            .filter { $0.height < current.height && $0.pixelHeight < current.pixelHeight }

        guard let best = bestMode(from: candidates, relativeTo: current, preferTallest: true) else {
            throw ModeSelectionError.noPairedLowerMode(current)
        }

        return best
    }

    public func modeToShow(
        current: DisplayModeInfo,
        available modes: [DisplayModeInfo],
        savedMode: DisplayModeInfo?
    ) throws -> DisplayModeInfo {
        if let savedMode, containsEquivalent(savedMode, in: modes) {
            return savedMode
        }

        let candidates = pairedModes(for: current, in: modes)
            .filter { $0.height > current.height && $0.pixelHeight > current.pixelHeight }

        guard let best = bestMode(from: candidates, relativeTo: current, preferTallest: true) else {
            throw ModeSelectionError.noPairedHigherMode(current)
        }

        return best
    }

    public func state(current: DisplayModeInfo, available modes: [DisplayModeInfo]) -> NotchModeState {
        let paired = pairedModes(for: current, in: modes)
        guard paired.contains(where: { $0.height != current.height || $0.pixelHeight != current.pixelHeight }) else {
            return .unsupported
        }

        let maxHeight = paired.map(\.height).max() ?? current.height
        let maxPixelHeight = paired.map(\.pixelHeight).max() ?? current.pixelHeight
        return current.height < maxHeight && current.pixelHeight < maxPixelHeight ? .hidden : .full
    }

    public func containsEquivalent(_ mode: DisplayModeInfo, in modes: [DisplayModeInfo]) -> Bool {
        modes.contains { equivalent($0, mode) }
    }

    public func equivalent(_ lhs: DisplayModeInfo, _ rhs: DisplayModeInfo) -> Bool {
        lhs.width == rhs.width
            && lhs.height == rhs.height
            && lhs.pixelWidth == rhs.pixelWidth
            && lhs.pixelHeight == rhs.pixelHeight
            && abs(lhs.refreshRate - rhs.refreshRate) < 0.01
    }

    private func pairedModes(for current: DisplayModeInfo, in modes: [DisplayModeInfo]) -> [DisplayModeInfo] {
        modes.filter { candidate in
            candidate.width == current.width
                && candidate.pixelWidth == current.pixelWidth
                && sameScaleFamily(candidate, current)
        }
    }

    private func sameScaleFamily(_ lhs: DisplayModeInfo, _ rhs: DisplayModeInfo) -> Bool {
        guard lhs.width > 0, lhs.height > 0, rhs.width > 0, rhs.height > 0 else {
            return false
        }

        let lhsScaleX = Double(lhs.pixelWidth) / Double(lhs.width)
        let rhsScaleX = Double(rhs.pixelWidth) / Double(rhs.width)
        let lhsScaleY = Double(lhs.pixelHeight) / Double(lhs.height)
        let rhsScaleY = Double(rhs.pixelHeight) / Double(rhs.height)

        return abs(lhsScaleX - rhsScaleX) < 0.01
            && abs(lhsScaleY - rhsScaleY) < 0.01
    }

    private func bestMode(
        from candidates: [DisplayModeInfo],
        relativeTo current: DisplayModeInfo,
        preferTallest: Bool
    ) -> DisplayModeInfo? {
        candidates.sorted { lhs, rhs in
            let lhsRefreshDistance = abs(lhs.refreshRate - current.refreshRate)
            let rhsRefreshDistance = abs(rhs.refreshRate - current.refreshRate)
            if abs(lhsRefreshDistance - rhsRefreshDistance) >= 0.01 {
                return lhsRefreshDistance < rhsRefreshDistance
            }

            if lhs.height != rhs.height {
                return preferTallest ? lhs.height > rhs.height : lhs.height < rhs.height
            }

            if lhs.pixelHeight != rhs.pixelHeight {
                return preferTallest ? lhs.pixelHeight > rhs.pixelHeight : lhs.pixelHeight < rhs.pixelHeight
            }

            return lhs.pixelWidth < rhs.pixelWidth
        }.first
    }
}
