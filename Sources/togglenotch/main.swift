import CoreGraphics
import Foundation
import ToggleNotchCore

enum CLIError: Error, CustomStringConvertible {
    case usage
    case noBuiltinDisplay
    case currentModeUnavailable
    case modeUnavailable(DisplayModeInfo)
    case displayConfigurationFailed(CGError)

    var description: String {
        switch self {
        case .usage:
            usageText
        case .noBuiltinDisplay:
            "No built-in display found. ToggleNotch only targets the MacBook built-in display in v1."
        case .currentModeUnavailable:
            "Could not read the current display mode."
        case .modeUnavailable(let mode):
            "Could not find an available display mode matching \(mode.description)."
        case .displayConfigurationFailed(let error):
            "Display configuration failed with CoreGraphics error \(error.rawValue)."
        }
    }
}

let usageText = """
Usage: togglenotch <command>

Commands:
  hide      Switch the built-in display to the lower-height mode below the camera area.
  show      Restore the saved full-height mode, or choose the matching highest mode.
  toggle    Hide if full-height, show if hidden.
  status    Print the current mode and notch state.
  list      List available built-in display modes.
"""

struct DisplayController {
    let selector = ModeSelector()

    func builtinDisplayID() throws -> CGDirectDisplayID {
        let main = CGMainDisplayID()
        if CGDisplayIsBuiltin(main) != 0 {
            return main
        }

        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        var displays = Array(repeating: CGDirectDisplayID(), count: Int(count))
        let error = CGGetActiveDisplayList(count, &displays, &count)
        guard error == .success else {
            throw CLIError.noBuiltinDisplay
        }

        guard let builtin = displays.first(where: { CGDisplayIsBuiltin($0) != 0 }) else {
            throw CLIError.noBuiltinDisplay
        }
        return builtin
    }

    func currentMode(for displayID: CGDirectDisplayID) throws -> DisplayModeInfo {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            throw CLIError.currentModeUnavailable
        }
        return DisplayModeInfo(mode)
    }

    func availableModes(for displayID: CGDirectDisplayID) -> [DisplayModeInfo] {
        rawModes(for: displayID).map(DisplayModeInfo.init)
    }

    func apply(_ target: DisplayModeInfo, to displayID: CGDirectDisplayID) throws {
        guard let mode = rawModes(for: displayID).first(where: { selector.equivalent(DisplayModeInfo($0), target) }) else {
            throw CLIError.modeUnavailable(target)
        }

        var config: CGDisplayConfigRef?
        var error = CGBeginDisplayConfiguration(&config)
        guard error == .success else {
            throw CLIError.displayConfigurationFailed(error)
        }

        error = CGConfigureDisplayWithDisplayMode(config, displayID, mode, nil)
        guard error == .success else {
            CGCancelDisplayConfiguration(config)
            throw CLIError.displayConfigurationFailed(error)
        }

        error = CGCompleteDisplayConfiguration(config, .permanently)
        guard error == .success else {
            throw CLIError.displayConfigurationFailed(error)
        }
    }

    private func rawModes(for displayID: CGDirectDisplayID) -> [CGDisplayMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
        return (CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode]) ?? []
    }
}

extension DisplayModeInfo {
    init(_ mode: CGDisplayMode) {
        self.init(
            width: mode.width,
            height: mode.height,
            pixelWidth: mode.pixelWidth,
            pixelHeight: mode.pixelHeight,
            refreshRate: mode.refreshRate,
            ioFlags: mode.ioFlags
        )
    }
}

func run(arguments: [String]) throws {
    guard arguments.count == 2 else {
        throw CLIError.usage
    }

    let command = arguments[1]
    let controller = DisplayController()
    let displayID = try controller.builtinDisplayID()
    let current = try controller.currentMode(for: displayID)
    let modes = controller.availableModes(for: displayID)
    let selector = ModeSelector()
    let store = StateStore()

    switch command {
    case "hide":
        if selector.state(current: current, available: modes) == .hidden {
            print("Already hidden: \(current.description)")
            return
        }

        let target = try selector.modeToHide(current: current, available: modes)
        try store.save(ToggleNotchState(displayID: displayID, mode: current))
        try controller.apply(target, to: displayID)
        print("Hidden: switched from \(current.description) to \(target.description)")

    case "show":
        if selector.state(current: current, available: modes) == .full {
            print("Already full-height: \(current.description)")
            return
        }

        let saved = try store.load()
        let savedMode = saved?.displayID == displayID ? saved?.mode : nil
        let target = try selector.modeToShow(current: current, available: modes, savedMode: savedMode)
        try controller.apply(target, to: displayID)
        print("Shown: switched from \(current.description) to \(target.description)")

    case "toggle":
        switch selector.state(current: current, available: modes) {
        case .hidden:
            let saved = try store.load()
            let savedMode = saved?.displayID == displayID ? saved?.mode : nil
            let target = try selector.modeToShow(current: current, available: modes, savedMode: savedMode)
            try controller.apply(target, to: displayID)
            print("Shown: switched from \(current.description) to \(target.description)")
        case .full:
            let target = try selector.modeToHide(current: current, available: modes)
            try store.save(ToggleNotchState(displayID: displayID, mode: current))
            try controller.apply(target, to: displayID)
            print("Hidden: switched from \(current.description) to \(target.description)")
        case .unsupported:
            throw ModeSelectionError.noPairedLowerMode(current)
        }

    case "status":
        let state = selector.state(current: current, available: modes)
        print("Display: built-in \(displayID)")
        print("Mode: \(current.description)")
        print("State: \(state.rawValue)")

    case "list":
        print("Display: built-in \(displayID)")
        for mode in modes.sorted(by: modeSort) {
            let marker = selector.equivalent(mode, current) ? "*" : " "
            print("\(marker) \(mode.description)")
        }

    case "-h", "--help", "help":
        print(usageText)

    default:
        throw CLIError.usage
    }
}

func modeSort(_ lhs: DisplayModeInfo, _ rhs: DisplayModeInfo) -> Bool {
    if lhs.width != rhs.width { return lhs.width < rhs.width }
    if lhs.height != rhs.height { return lhs.height < rhs.height }
    if lhs.pixelWidth != rhs.pixelWidth { return lhs.pixelWidth < rhs.pixelWidth }
    if lhs.pixelHeight != rhs.pixelHeight { return lhs.pixelHeight < rhs.pixelHeight }
    return lhs.refreshRate > rhs.refreshRate
}

do {
    try run(arguments: CommandLine.arguments)
} catch {
    fputs("togglenotch: \(error)\n", stderr)
    exit(error is CLIError ? 64 : 1)
}
