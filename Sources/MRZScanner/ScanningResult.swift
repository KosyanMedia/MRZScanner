//
//  Created by Roman Mazeev on 29/12/2022.
//

import CoreGraphics
import MRZParser

public struct ScanningResult: Sendable, Equatable {
    public let data: MRZResult
    public let boundingRects: ScannedBoundingRects
}

public struct ScanningResultError: Error {
    public let boundingRects: ScannedBoundingRects?

    init(boundingRects: ScannedBoundingRects? = nil) {
        self.boundingRects = boundingRects
    }
}

public struct ScannedBoundingRects: Sendable, Equatable {

    public let valid: [CGRect]
    public let invalid: [CGRect]

    public init(valid: [CGRect], invalid: [CGRect]) {
        self.valid = valid
        self.invalid = invalid
    }

    public func convertedTo(imageSize: CGSize) -> Self {
        .init(
            valid: valid.map { $0.convert(to: .imageRect, imageSize: imageSize) },
            invalid: invalid.map { $0.convert(to: .imageRect, imageSize: imageSize) }
        )
    }
}
