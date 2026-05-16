import Testing
@testable import ToggleNotchCore

private let full120 = DisplayModeInfo(
    width: 1512,
    height: 982,
    pixelWidth: 3024,
    pixelHeight: 1964,
    refreshRate: 120
)

private let full60 = DisplayModeInfo(
    width: 1512,
    height: 982,
    pixelWidth: 3024,
    pixelHeight: 1964,
    refreshRate: 60
)

private let hidden120 = DisplayModeInfo(
    width: 1512,
    height: 945,
    pixelWidth: 3024,
    pixelHeight: 1890,
    refreshRate: 120
)

private let hidden60 = DisplayModeInfo(
    width: 1512,
    height: 945,
    pixelWidth: 3024,
    pixelHeight: 1890,
    refreshRate: 60
)

@Test func fullModeMapsToHiddenMode() throws {
    let selector = ModeSelector()
    let target = try selector.modeToHide(current: full120, available: [full120, hidden120])

    #expect(target == hidden120)
}

@Test func hiddenModeMapsBackToFullMode() throws {
    let selector = ModeSelector()
    let target = try selector.modeToShow(current: hidden120, available: [full120, hidden120], savedMode: nil)

    #expect(target == full120)
}

@Test func refreshRatePreferenceKeeps120HzWhenAvailable() throws {
    let selector = ModeSelector()
    let target = try selector.modeToHide(current: full120, available: [full120, full60, hidden60, hidden120])

    #expect(target == hidden120)
}

@Test func savedModeIsPreferredWhenAvailable() throws {
    let selector = ModeSelector()
    let target = try selector.modeToShow(current: hidden120, available: [full120, full60, hidden120], savedMode: full60)

    #expect(target == full60)
}

@Test func missingPairedModeThrowsControlledError() {
    let selector = ModeSelector()

    #expect(throws: ModeSelectionError.noPairedLowerMode(full120)) {
        try selector.modeToHide(current: full120, available: [full120])
    }
}

@Test func stateDetectionDistinguishesHiddenAndFull() {
    let selector = ModeSelector()
    let modes = [full120, hidden120]

    #expect(selector.state(current: full120, available: modes) == .full)
    #expect(selector.state(current: hidden120, available: modes) == .hidden)
}
