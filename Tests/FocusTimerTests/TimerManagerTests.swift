import XCTest
@testable import FocusTimer

final class TimerManagerTests: XCTestCase {
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
    }
    
    override func tearDown() {
        timerManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(timerManager.currentState, .idle)
        XCTAssertEqual(timerManager.timeRemaining, 0)
        XCTAssertEqual(timerManager.cycleCount, 0)
    }
}
