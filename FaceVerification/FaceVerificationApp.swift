//
//  FaceVerificationApp.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//

import SwiftUI

@main
struct FaceVerificationApp: App {
    var body: some Scene {
        WindowGroup {
            FaceVerificationView(vm: .init())
        }
    }
}
