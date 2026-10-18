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

  func testArrowsMoveByCellAndRowInImageGrid() {
    History.shared.kindFilter = .image
    defer { History.shared.kindFilter = nil }
    XCTAssertEqual(KeyChord(.leftArrow, []), .moveToPrevious)
    XCTAssertEqual(KeyChord(.rightArrow, []), .moveToNext)
    XCTAssertEqual(KeyChord(.upArrow, []), .moveToPreviousRow)
    XCTAssertEqual(KeyChord(.downArrow, []), .moveToNextRow)
  }

  func testPlainLeftRightAreLeftToSearchFieldInList() {
    History.shared.kindFilter = nil
    XCTAssertEqual(KeyChord(.leftArrow, []), .unknown)
    XCTAssertEqual(KeyChord(.rightArrow, []), .unknown)
    XCTAssertEqual(KeyChord(.downArrow, []), .moveToNext)
  }

  func testShiftCommandTCyclesKindFilterBackward() {
    XCTAssertEqual(KeyChord(.t, [.command, .shift]), .previousKindFilter)
  }
}
