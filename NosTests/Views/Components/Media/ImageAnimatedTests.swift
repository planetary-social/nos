import SDWebImage
import SDWebImageWebPCoder
import XCTest

final class ImageAnimatedTests: XCTestCase {
    func test_gif_isAnimated() throws {
        // thanks to grlux on pixabay for the gif! https://pixabay.com/gifs/fonts-typography-quotes-design-5397/
        let url = try XCTUnwrap(Bundle.current.url(forResource: "fonts-animated", withExtension: "gif"))
        let data = try Data(contentsOf: url)

        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertFalse(image.sd_isAnimated)  // ideally this would return true
        XCTAssertNil(image.images)  // ideally this would be non-nil

        let sdImage = try XCTUnwrap(SDAnimatedImage(data: data))
        XCTAssertTrue(sdImage.sd_isAnimated)
        XCTAssertTrue(sdImage.sd_isAnimated)
        XCTAssertTrue(sdImage.animatedImageFrameCount > 1)
        XCTAssertTrue(sdImage.sd_imageFrameCount > 1)

        let decodedImage = try XCTUnwrap(SDImageCodersManager.shared.decodedImage(with: data))
        XCTAssertTrue(decodedImage.sd_isAnimated)
        XCTAssertNotNil(decodedImage.images)
    }

    func test_webp_isAnimated() throws {
        // try commenting out the next two lines and watch this fail
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)

        let url = try XCTUnwrap(Bundle.current.url(forResource: "elmo-animated", withExtension: "webp"))
        let data = try Data(contentsOf: url)

        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertFalse(image.sd_isAnimated)  // ideally this would return true
        XCTAssertNil(image.images)  // ideally this would be non-nil

        let sdImage = try XCTUnwrap(SDAnimatedImage(data: data))
        XCTAssertTrue(sdImage.sd_isAnimated)
        XCTAssertTrue(sdImage.animatedImageFrameCount > 1)
        XCTAssertTrue(sdImage.sd_imageFrameCount > 1)

        let decodedImage = try XCTUnwrap(SDImageCodersManager.shared.decodedImage(with: data))
        XCTAssertTrue(decodedImage.sd_isAnimated)
        XCTAssertNotNil(decodedImage.images)
    }
}
