//
//  CameraViewController.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//

import UIKit
import AVFoundation
import CoreImage
import Combine

class CameraViewController: UIViewController {
    var faceDetector: FaceDetector?
    weak var vm: FaceVerificationViewModel? {
        didSet {
            vm?.isUsingFrontCamera.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error):
                    print("Received error: \(error)")
                }
            } receiveValue: { isFront in
                self.cameraPosition = isFront ? .front : .back
            }
            .store(in: &subscriptions)
        }
    }
    
    var subscriptions = Set<AnyCancellable>()
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    let session = AVCaptureSession()
        
    var cameraPosition: AVCaptureDevice.Position = .front {
        didSet {
            self.configureCaptureDevice()
        }
    }
    
    let videoOutputQueue = DispatchQueue(
        label: "Video Output Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        faceDetector?.viewDelegate = self
        
        self.view.frame.size.width = UIScreen.main.bounds.size.width - 32
        self.view.frame.size.height = 400
        

        configureCaptureSession()
        
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            self?.session.startRunning()
//        }
    }
 
    
    // MARK: - Setup video capture
    private func configureCaptureSession() {
        // Define the capture device we want to use
        configureCaptureDevice()
        
        // Create the video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(faceDetector, queue: videoOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // Add the video output to the capture session
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        // Configure the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds

        if let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }
    
    
    private func configureCaptureDevice() {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: cameraPosition
        ) else {
            print("No \(cameraPosition) video camera available")
            return
        }
        
        // Connect the camera to the capture session input
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            if let inputs = session.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    session.removeInput(input)
                }
            }
            
            session.addInput(cameraInput)
        } catch {
            print(error.localizedDescription)
        }
        
        session.commitConfiguration()
    }
}

// MARK: FaceDetectorDelegate methods

extension CameraViewController: FaceDetectorDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
        guard let previewLayer = previewLayer else {
            return CGRect.zero
        }
        
        return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
    }
}
