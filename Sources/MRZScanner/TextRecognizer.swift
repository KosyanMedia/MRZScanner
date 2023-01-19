//
//  Created by Roman Mazeev on 13.07.2021.
//

import Vision
import CoreImage

struct TextRecognizer {

    let recognize: (CIImage, Configuration) async throws -> [Result]

    static func makeDefault() -> Self {
        .init(recognize: { image, configuration in
            try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { response, error in
                    guard let visionResults = response.results as? [VNRecognizedTextObservation] else {
                        if let error { continuation.resume(throwing: error) }
                        return
                    }

                    continuation.resume(returning: visionResults.map {
                        Result(results: $0.topCandidates(10).map(\.string), boundingRect: $0.boundingBox)
                    })
                }

                if let roi = configuration.regionOfInterest {
                    request.regionOfInterest = roi
                }
                if let minimumTextHeight = configuration.minimumTextHeight {
                    request.minimumTextHeight = minimumTextHeight
                }
                request.recognitionLevel = configuration.recognitionLevel
                request.usesLanguageCorrection = false

                do {
                    try VNImageRequestHandler(ciImage: image, orientation: configuration.orientation)
                        .perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
    }

    // MARK: - Nested types

    struct Configuration {
        let orientation: CGImagePropertyOrientation
        let regionOfInterest: CGRect?
        let minimumTextHeight: Float?
        let recognitionLevel: VNRequestTextRecognitionLevel
    }

    struct Result {
        let results: [String]
        let boundingRect: CGRect
    }
}
