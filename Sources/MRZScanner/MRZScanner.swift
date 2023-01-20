//
//  Created by Roman Mazeev on 12.07.2021.
//

import CoreImage
import Vision
import MRZParser

public struct MRZScanner {

    // MARK: - Properties

    private let scanSingle: (
        _ image: CIImage,
        _ orientation: CGImagePropertyOrientation,
        _ regionOfInterest: CGRect?,
        _ minimumTextHeight: Float?
    ) async throws -> MRZResult

    private let scanLive: (
        _ image: CIImage,
        _ orientation: CGImagePropertyOrientation,
        _ regionOfInterest: CGRect?,
        _ minimumTextHeight: Float?
    ) async throws -> ScanningResult

    // MARK: - Init

    public init(
        scanSingle: @escaping (CIImage, CGImagePropertyOrientation, CGRect?, Float?) async throws -> MRZResult,
        scanLive: @escaping (CIImage, CGImagePropertyOrientation, CGRect?, Float?) async throws -> ScanningResult
    ) {
        self.scanSingle = scanSingle
        self.scanLive = scanLive
    }

    // MARK: - Convenient methonds

    public static func makeDefaultScanner() -> Self {
        .makeDefault()
    }

    public func scanSingle(
        image: CIImage,
        orientation: CGImagePropertyOrientation,
        regionOfInterest: CGRect? = nil,
        minimumTextHeight: Float? = nil
    ) async throws -> MRZResult {
        try await scanSingle(image, orientation, regionOfInterest, minimumTextHeight)
    }

    public func scanLive(
        image: CIImage,
        orientation: CGImagePropertyOrientation,
        regionOfInterest: CGRect? = nil,
        minimumTextHeight: Float? = nil
    ) async throws -> ScanningResult {
        try await scanLive(image, orientation, regionOfInterest, minimumTextHeight)
    }
}

extension MRZScanner {

    static func makeDefault(
        textRecognizer: TextRecognizer = .makeDefault(),
        validator: MRZValidator = .makeDefault(),
        parser: MRZParser = .init(isOCRCorrectionEnabled: true)
    ) -> Self {
        var frequencyTracker = MRZFrequencyTracker(frequency: 2)

        return .init(
            scanSingle: { image, orientation, regionOfInterest, minimumTextHeight in
                let configuration = TextRecognizer.Configuration(
                    orientation: orientation,
                    regionOfInterest: regionOfInterest,
                    minimumTextHeight: minimumTextHeight,
                    recognitionLevel: .accurate
                )
                let recognizerResults = try await textRecognizer.recognize(image, configuration)
                let validatedResults = validator.getValidatedResults(recognizerResults.map(\.results))

                if let parsedResult = parser.parse(mrzLines: validatedResults.map(\.result)) {
                    return parsedResult
                } else {
                    throw ScanningResultError()
                }
            },
            scanLive: { image, orientation, regionOfInterest, minimumTextHeight in
                let configuration = TextRecognizer.Configuration(
                    orientation: orientation,
                    regionOfInterest: regionOfInterest,
                    minimumTextHeight: minimumTextHeight,
                    recognitionLevel: .fast
                )
                let recognizerResults = try await textRecognizer.recognize(image, configuration)
                let validatedResults = validator.getValidatedResults(recognizerResults.map(\.results))
                let lines = validatedResults.map(\.result)
                let boundingRects = getScannedBoundingRects(from: recognizerResults, validLines: validatedResults)

                if let parsedResult = parser.parse(mrzLines: lines), frequencyTracker.isResultStable(parsedResult) {
                    return ScanningResult(data: parsedResult, boundingRects: boundingRects)
                } else {
                    throw ScanningResultError(boundingRects: boundingRects)
                }
            }
        )
    }

    private static func getScannedBoundingRects(
        from results: [TextRecognizer.Result],
        validLines: [MRZValidator.Result]
    ) -> ScannedBoundingRects {
        let allBoundingRects = results.map(\.boundingRect)
        let validRectIndexes = Set(validLines.map(\.index))

        var validScannedBoundingRects: [CGRect] = []
        var invalidScannedBoundingRects: [CGRect] = []
        allBoundingRects.enumerated().forEach {
            if validRectIndexes.contains($0.offset) {
                validScannedBoundingRects.append($0.element)
            } else {
                invalidScannedBoundingRects.append($0.element)
            }
        }

        return .init(valid: validScannedBoundingRects, invalid: invalidScannedBoundingRects)
    }
}
