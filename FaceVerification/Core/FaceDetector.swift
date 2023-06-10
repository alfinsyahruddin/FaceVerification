//
//  FaceDetector.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//

import AVFoundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

protocol FaceDetectorDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FaceDetector: NSObject {
    weak var viewDelegate: FaceDetectorDelegate?
    weak var vm: FaceVerificationViewModel? {
        didSet {
            vm?.shutterReleased.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error):
                    print("Received error: \(error)")
                }
            } receiveValue: { _ in
                self.isCapturingPhoto = true
            }
            .store(in: &subscriptions)
        }
    }
    
    var sequenceHandler = VNSequenceRequestHandler()
    var currentFrameBuffer: CVImageBuffer?
    var isCapturingPhoto = false
    
    var subscriptions = Set<AnyCancellable>()
    
    let imageProcessingQueue = DispatchQueue(
        label: "Image Processing Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods

extension FaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        if isCapturingPhoto {
            isCapturingPhoto = false
            savePhoto(from: imageBuffer)
        }
        
        // Detect Face Rectangle
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
        
        // Detect Capture Quality
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(completionHandler: detectedFaceQualityRequest)
        
        currentFrameBuffer = imageBuffer
        do {
            try sequenceHandler.perform(
                [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                on: imageBuffer,
                orientation: .leftMirrored
            )
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - Private methods

extension FaceDetector {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let vm = vm, let viewDelegate = viewDelegate else {
            return
        }
        
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
        else {
            vm.perform(action: .noFaceDetected)
            return
        }
        
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        
        let faceObservationModel = FaceGeometryModel(
            boundingBox: convertedBoundingBox,
            roll: result.roll ?? 0,
            pitch: result.pitch ?? 0,
            yaw: result.yaw ?? 0
        )
        
        vm.perform(action: .faceObservationDetected(faceObservationModel))
    }
    
    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
        guard let vm = vm else {
            return
        }
        
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
        else {
            vm.perform(action: .noFaceDetected)
            return
        }
        
        let faceQualityModel = FaceQualityModel(
            quality: result.faceCaptureQuality ?? 0
        )
        
        vm.perform(action: .faceQualityObservationDetected(faceQualityModel))
    }
    
    func savePhoto(from pixelBuffer: CVPixelBuffer) {
        guard let vm = vm else {
            return
        }
        
        imageProcessingQueue.async {
            let originalImage = CIImage(cvPixelBuffer: pixelBuffer)
     
            let coreImageWidth = originalImage.extent.width
            let coreImageHeight = originalImage.extent.height
            
            let desiredImageHeight = coreImageWidth * 4 / 3
            
            let yOrigin = (coreImageHeight - desiredImageHeight) / 2
            let photoRect = CGRect(x: 0, y: yOrigin, width: coreImageWidth, height: desiredImageHeight)
            
            let context = CIContext()
            if let cgImage = context.createCGImage(originalImage, from: photoRect) {
                
                let photo = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
                
                DispatchQueue.main.async {
                    vm.perform(action: .savePhoto(photo))
                }
            }
        }
    }
    
}
