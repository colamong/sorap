import CoreImage.CIFilterBuiltins
import XCTest
@testable import Maccy

final class CapturePromptTests: XCTestCase {
  func testReadsQRPayload() async {
    let payload = await CapturePrompt.readQRPayload(imageData: qrPNG("https://github.com/colamong/sorap"))
    XCTAssertEqual(payload, "https://github.com/colamong/sorap")
  }

  func testImageWithoutQRHasNoPayload() async {
    let image = NSImage(size: NSSize(width: 60, height: 60))
    image.lockFocus()
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: 60, height: 60).fill()
    image.unlockFocus()
    let payload = await CapturePrompt.readQRPayload(imageData: image.tiffRepresentation!)
    XCTAssertNil(payload)
  }

  private func qrPNG(_ message: String) -> Data {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(message.utf8)
    let image = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
    let rep = NSBitmapImageRep(ciImage: image)
    return rep.representation(using: .png, properties: [:])!
  }
}
