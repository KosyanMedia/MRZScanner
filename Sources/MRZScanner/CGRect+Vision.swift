//
//  Created by Roman Mazeev on 29/12/2022.
//

import CoreGraphics
import Vision

public extension CGRect {

    enum RectConvertationType {
        case imageRect
        case normalizedRect
    }

    func convert(to type: RectConvertationType, imageSize: CGSize) -> CGRect {
        switch type {
        case .imageRect:
            return VNImageRectForNormalizedRect(self, Int(imageSize.width), Int(imageSize.height))
        case .normalizedRect:
            return VNNormalizedRectForImageRect(self, Int(imageSize.width), Int(imageSize.height))
        }
    }
}
