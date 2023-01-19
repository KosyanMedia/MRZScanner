//
//  Created by Roman Mazeev on 13.07.2021.
//

import MRZParser

struct MRZValidator {

    let getValidatedResults: (_ lines: [[String]]) -> [Result]

    static func makeDefault() -> Self {
        .init(getValidatedResults: { lines in
            var validLines: [Result] = []

            for validMRZCode in MRZFormat.allCases where validLines.count < validMRZCode.linesCount {
                for (index, lines) in lines.enumerated() where validLines.count < validMRZCode.linesCount {
                    let spaceFreeLines = lines.lazy.map { $0.filter { !$0.isWhitespace } }
                    if let mostLikelyLine = spaceFreeLines.first(where: { $0.count == validMRZCode.lineLength }) {
                        validLines.append(.init(result: mostLikelyLine, index: index))
                    }
                }

                if validLines.count != validMRZCode.linesCount {
                    validLines = []
                }
            }

            return validLines
        })
    }

    // MARK: - Nested types

    struct Result {
        /// MRZLine
        let result: String
        /// MRZLine boundingRect index
        let index: Int
    }
}
