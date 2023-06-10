//
//  PhotoPreview.swift
//  FaceVerification
//
//  Created by M Alfin Syahruddin on 03/06/23.
//

import SwiftUI

struct PhotoPreview: View {
    var img: UIImage?
    
    var body: some View {
        ZStack {
            Color(hex: "40BAFF")
                .ignoresSafeArea()
            
            VStack {
                Text("Photo Preview")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let img = img {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 400)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(16)
        }
    }
}

struct PhotoPreview_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPreview()
    }
}
