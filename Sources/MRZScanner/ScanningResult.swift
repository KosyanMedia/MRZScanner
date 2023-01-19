//
//  Created by Roman Mazeev on 29/12/2022.
//

import CoreGraphics
import MRZParser

public struct ScanningResult: Sendable, Equatable {
    public let data: MRZResult
    public let boundingRects: ScanedBoundingRects
}

public struct ScanningResultError: Error {
    public let boundingRects: ScanedBoundingRects?

    init(boundingRects: ScanedBoundingRects? = nil) {
        self.boundingRects = boundingRects
    }
}

public struct ScanedBoundingRects: Sendable, Equatable {

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
