//
//  FaceBoundingBoxView.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 04/06/23.
//

import SwiftUI


struct FaceBoundingBoxView: View {
    @ObservedObject private(set) var vm: FaceVerificationViewModel
    
    var body: some View {
        switch vm.faceGeometryState {
        case .faceNotFound:
            Rectangle().fill(Color.clear)
        case .faceFound(let faceGeometryModel):
            Rectangle()
                .path(in: CGRect(
                    x: faceGeometryModel.boundingBox.origin.x,
                    y: faceGeometryModel.boundingBox.origin.y,
                    width: faceGeometryModel.boundingBox.width,
                    height: faceGeometryModel.boundingBox.height
                ))
                .stroke(vm.hasDetectedValidFace ? Color.green : Color.red, lineWidth: 2.0)
        case .errored:
            Rectangle().fill(Color.clear)
        }
    }
}
