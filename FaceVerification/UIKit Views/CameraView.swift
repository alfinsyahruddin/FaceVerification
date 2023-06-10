//
//  CameraView.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController
    
    private(set) var vm: FaceVerificationViewModel
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let faceDetector = FaceDetector()
        faceDetector.vm = vm
        
        let viewController = CameraViewController()
        viewController.vm = vm
        viewController.faceDetector = faceDetector

        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }
}
