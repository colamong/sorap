import AppKit
import Sauce
import XCTest
@testable import Maccy

@MainActor
class KeyChordTests: XCTestCase {
  func testTabAndOptionRightSelectNextBoard() {
    XCTAssertEqual(KeyChord(.tab, []), .nextBoard)
    XCTAssertEqual(KeyChord(.rightArrow, [.option]), .nextBoard)
  }

  func testOptionLeftSelectsPreviousBoard() {
    XCTAssertEqual(KeyChord(.leftArrow, [.option]), .previousBoard)
  }

  func testShiftTabAndCommandTCycleKindFilterForward() {
    XCTAssertEqual(KeyChord(.tab, [.shift]), .nextKindFilter)
    XCTAssertEqual(KeyChord(.t, [.command]), .nextKindFilter)
  }

  func testShiftCommandTCyclesKindFilterBackward() {
    XCTAssertEqual(KeyChord(.t, [.command, .shift]), .previousKindFilter)
  }
}
