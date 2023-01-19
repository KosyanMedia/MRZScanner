//
//  Created by Roman Mazeev on 01/01/2023.
//

import AVFoundation
import SwiftUI
import MRZScanner
import MRZParser
import Vision
import Foundation

final class ViewModel: ObservableObject {

    private lazy var camera = Camera()
    private lazy var scanner: MRZScanner = .makeDefaultScanner()

    var captureSession: AVCaptureSession {
        camera.captureSession
    }

    // MARK: Scanning

    @Published var cameraRect: CGRect?
    @Published var boundingRects: ScanedBoundingRects?
    @Published var mrzRect: CGRect?
    @Published var mrzResult: MRZResult?

    private var scanningTask: Task<(), Error>?

    func startScanning() {
        scanningTask = Task {
            await camera.start()

            for try await image in camera.imageStream {
                await scan(image: image)
            }
        }
    }

    private func scan(image: CIImage) async {
        guard let cameraRect, let mrzRect else {
            return
        }

        
        let correctedMRZRect = correctCoordinates(to: .leftTop, rect: mrzRect)
        let roi = correctedMRZRect.convert(to: .normalizedRect, imageSize: cameraRect.size)

        do {
            let result = try await scanner.scanLive(
                image: image,
                orientation: .up,
                regionOfInterest: roi,
                minimumTextHeight: 0.1
            )
            Task { @MainActor in
                self.boundingRects = self.correctBoundingRects(to: .center, rects: result.boundingRects)
                self.mrzResult = result.data
            }
        } catch let error as ScanningResultError {
            Task { @MainActor in
                self.boundingRects = error.boundingRects
            }
        } catch {
            print(error)
        }
    }

    // MARK: - Correct CGRect origin from top left to center

    enum CorrectionType {
        case center
        case leftTop
    }

    private func correctBoundingRects(to type: CorrectionType, rects: ScanedBoundingRects) -> ScanedBoundingRects {
        guard let mrzRect else { fatalError("Camera rect must be set") }

        let convertedCoordinates = rects.convertedTo(imageSize: mrzRect.size)
        let correctedMRZRect = correctCoordinates(to: .leftTop, rect: mrzRect)

        func correctRects(_ rects: [CGRect]) -> [CGRect] {
            rects
                .map { correctCoordinates(to: type, rect: $0) }
                .map {
                    let point = CGPoint(
                        x: $0.origin.x + correctedMRZRect.minX,
                        y: $0.origin.y + correctedMRZRect.minY
                    )
                    return .init(origin: point, size: $0.size)
                }
        }

        return .init(valid: correctRects(convertedCoordinates.valid),  invalid: correctRects(convertedCoordinates.invalid))
    }

    private func correctCoordinates(to type: CorrectionType, rect: CGRect) -> CGRect {
        let x = type == .center ? rect.minX + rect.width / 2 : rect.minX - rect.width / 2
        let y = type == .center ? rect.minY + rect.height / 2 : rect.minY - rect.height / 2
        return CGRect(origin: .init(x: x, y: y), size: rect.size)
    }
}
