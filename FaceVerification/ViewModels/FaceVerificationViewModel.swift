//
//  FaceVerificationViewModel.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//


import Combine
import CoreGraphics
import UIKit
import Vision

final class FaceVerificationViewModel: ObservableObject {
    
    @Published var showPhotoPreview: Bool = false
        
    // MARK: - Publishers of derived state
    @Published private(set) var hasDetectedValidFace: Bool = false
    
    // MARK: - Publishers of Vision data directly
    @Published private(set) var faceDetectedState: FaceDetectedState = .noFaceDetected
    @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel> = .faceNotFound {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel> = .faceNotFound {
        didSet {
            processUpdatedFaceQuality()
        }
    }
    
    // MARK: - Is Acceptable Properties
    @Published private(set) var isAcceptableRoll: Bool = false {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptablePitch: Bool = false {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    @Published private(set) var isAcceptableYaw: Bool = false {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    
    @Published private(set) var isAcceptableBounds: FaceBoundsState = .unknown {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    
    @Published private(set) var isAcceptableQuality: Bool = false {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    
    @Published private(set) var photo: UIImage? {
        didSet {
            if photo?.cgImage != nil {
                self.showPhotoPreview = true
            }
        }
    }
    
    
    // MARK: - Public properties
    let shutterReleased = PassthroughSubject<Void, Never>()
    let isUsingFrontCamera = CurrentValueSubject<Bool, Never>(true)

    var instructionLabel: String {
        switch self.faceDetectedState {
        case .faceDetectionErrored:
            return "Telah terjadi error."
        case .noFaceDetected:
            return "Tidak ada wajah terdeteksi."
        case .faceDetected:
            if self.hasDetectedValidFace {
                return "Silakan ambil foto Anda."
            } else if self.isAcceptableBounds == .detectedFaceTooSmall {
                return "Dekatkan kamera ke wajah Anda."
            } else if self.isAcceptableBounds == .detectedFaceTooLarge {
                return "Jauhkan kamera dari wajah Anda."
            } else if self.isAcceptableBounds == .detectedFaceOffCentre {
                return "Posisikan wajah Anda ke tengah."
            } else if !self.isAcceptableRoll || !self.isAcceptablePitch || !self.isAcceptableYaw {
                return "Posisikan wajah Anda tegak lurus ke kamera."
            } else if !self.isAcceptableQuality {
                return "Kualitas gambar kurang baik."
            } else {
                return "Tidak dapat mengambil foto wajah."
            }
        }
    }
    
    
    // MARK: - Private variables
    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 400)
    let camerViewOffsetY: CGFloat = 200
    
    // MARK: Actions
    func perform(action: FaceVerificationViewModelAction) {
        switch action {
        case .windowSizeDetected(let windowRect):
            handleWindowSizeChanged(toRect: windowRect)
        case .noFaceDetected:
            publishNoFaceObserved()
        case .faceObservationDetected(let faceObservation):
            publishFaceObservation(faceObservation)
        case .faceQualityObservationDetected(let faceQualityObservation):
            publishFaceQualityObservation(faceQualityObservation)
        case .takePhoto:
            takePhoto()
        case .switchCamera:
            switchCamera()
        case .savePhoto(let image):
            savePhoto(image)
        }
    }
    
    // MARK: Action handlers
    
    private func handleWindowSizeChanged(toRect: CGRect) {
        faceLayoutGuideFrame = CGRect(
            x: toRect.midX - faceLayoutGuideFrame.width / 2,
            y: toRect.midY - faceLayoutGuideFrame.height / 2,
            width: faceLayoutGuideFrame.width,
            height: faceLayoutGuideFrame.height
        )
    }
    
    private func publishNoFaceObserved() {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .noFaceDetected
            faceGeometryState = .faceNotFound
        }
    }
    
    private func publishFaceObservation(_ faceGeometryModel: FaceGeometryModel) {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .faceDetected
            faceGeometryState = .faceFound(faceGeometryModel)
        }
    }
    
    private func publishFaceQualityObservation(_ faceQualityModel: FaceQualityModel) {
        DispatchQueue.main.async { [self] in
            faceDetectedState = .faceDetected
            faceQualityState = .faceFound(faceQualityModel)
        }
    }
    
    private func takePhoto() {
        shutterReleased.send()
    }
    
    
    private func switchCamera() {
        isUsingFrontCamera.send(!isUsingFrontCamera.value)
    }
    
    private func savePhoto(_ photo: UIImage) {
        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        
        DispatchQueue.main.async { [self] in
            self.photo = photo
        }
    }
    
}

// MARK: Private instance methods

extension FaceVerificationViewModel {
    func invalidateFaceGeometryState() {
        isAcceptableRoll = false
        isAcceptablePitch = false
        isAcceptableYaw = false
        
        isAcceptableBounds = .unknown
    }
    
    func processUpdatedFaceGeometry() {
        switch faceGeometryState {
        case .faceNotFound:
            invalidateFaceGeometryState()
        case .errored(let error):
            print(error.localizedDescription)
            invalidateFaceGeometryState()
        case .faceFound(let faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            
            let roll = faceGeometryModel.roll.doubleValue
            let pitch = faceGeometryModel.pitch.doubleValue
            let yaw = faceGeometryModel.yaw.doubleValue
            
            updateAcceptableBounds(using: boundingBox)
            updateAcceptableRollPitchYaw(using: roll, pitch: pitch, yaw: yaw)
        }
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 1.2 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
        } else if boundingBox.width * 3 < faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooSmall
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }
    
    func updateAcceptableRollPitchYaw(using roll: Double, pitch: Double, yaw: Double) {
        isAcceptableRoll = 1.2...1.6 ~= roll
        isAcceptablePitch = abs(CGFloat(pitch)) < 0.2
        isAcceptableYaw = abs(CGFloat(yaw)) < 0.15
    }
    
    func processUpdatedFaceQuality() {
        switch faceQualityState {
        case .faceNotFound:
            isAcceptableQuality = false
        case .errored(let error):
            print(error.localizedDescription)
            isAcceptableQuality = false
        case .faceFound(let faceQualityModel):
            if faceQualityModel.quality < 0.2 {
                isAcceptableQuality = false
            }
            isAcceptableQuality = true
        }
    }
    
    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
        isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableRoll &&
        isAcceptablePitch &&
        isAcceptableYaw &&
        isAcceptableQuality
    }
}


// MARK: - Types

enum FaceObservation<T> {
    case faceFound(T)
    case faceNotFound
    case errored(Error)
}

enum FaceVerificationViewModelAction {
    // View setup and configuration actions
    case windowSizeDetected(CGRect)
    
    // Face detection actions
    case noFaceDetected
    case faceObservationDetected(FaceGeometryModel)
    
    // Face Quality
    case faceQualityObservationDetected(FaceQualityModel)
    case takePhoto
    case switchCamera
    case savePhoto(UIImage)
}

enum FaceDetectedState {
    case faceDetected
    case noFaceDetected
    case faceDetectionErrored
}

enum FaceBoundsState {
    case unknown
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case detectedFaceAppropriateSizeAndPosition
}

struct FaceGeometryModel {
    let boundingBox: CGRect
    let roll: NSNumber
    let pitch: NSNumber
    let yaw: NSNumber
}

struct FaceQualityModel {
    let quality: Float
}

