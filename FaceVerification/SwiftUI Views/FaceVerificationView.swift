//
//  ContentView.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//

import SwiftUI

struct FaceVerificationView: View {
    @ObservedObject var vm: FaceVerificationViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "40BAFF")
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    // Instruction
                    Image(vm.hasDetectedValidFace ? "checkmark" : "xmark")
                        .resizable()
                        .frame(width: 32, height: 32)
                    
                    Text(vm.instructionLabel)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(height: 140)

                
                Spacer()
                    .frame(height: 32)
                
                // Camera View
                VStack {
                    ZStack {
                        GeometryReader { geo in
                            CameraView(vm: vm)
                                .onAppear {
                                    vm.perform(action: .windowSizeDetected(geo.frame(in: .local)))
                                }
                        }
                        
                        FaceBoundingBoxView(vm: vm)
                    }
                }
                .frame(height: 400)
                .background(.black)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                
                
                Spacer()
                
                // Bottom Bar
                HStack {
                    Button(action: {
                        guard vm.photo?.cgImage != nil else { return }
                        vm.showPhotoPreview = true
                    }) {
                        if let img = vm.photo?.cgImage {
                            Image(uiImage: UIImage(cgImage: img, scale: 1, orientation: .upMirrored))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                        } else {
                            Image("placeholder")
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        vm.perform(action: .takePhoto)
                    }) {
                        Image("shutter")
                            .resizable()
                            .frame(width: 80, height: 80)
//                            .opacity(vm.hasDetectedValidFace ? 1 : 0.5)
                    }
                    .disabled(!vm.hasDetectedValidFace)
                    
                    Spacer()
                    
                    Button(action: {
                        vm.perform(action: .switchCamera)
                    }) {
                        Image("switch")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 36)
                .background(.white.opacity(0.15))
            }
            
        }
        .sheet(isPresented: $vm.showPhotoPreview) {
            if let img = vm.photo?.cgImage {
                PhotoPreview(img: UIImage(cgImage: img, scale: 1, orientation: .upMirrored))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FaceVerificationView(vm: .init())
    }
}


