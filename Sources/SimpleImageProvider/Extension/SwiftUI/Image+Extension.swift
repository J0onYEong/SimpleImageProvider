//
//  Image+Extension.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import SwiftUI

class ImageLoader: @unchecked Sendable, ObservableObject {
    @Published var uiImage: UIImage?
    
    let url: String
    let size: CGSize?
    let fadeOutduration: TimeInterval
    
    init(url: String, size: CGSize?, fadeOutduration: TimeInterval) {
        
        self.url = url
        self.size = size
        self.fadeOutduration = fadeOutduration
        
        loadImage()
    }
    
    func loadImage() {
        
        Task {
            
            let image = await SimpleImageProvider.shared
                .requestImage(url: url, size: size)
            
            await MainActor.run { [weak self] in
                
                guard let self else { return }
                
                withAnimation(.easeInOut(duration: fadeOutduration)) {
                    
                    uiImage = image
                }
            }
        }
    }
}

public struct SimpleImage: View {
    
    @StateObject var imageLoader: ImageLoader
    
    public init(url: String, size: CGSize?, fadeOutduration: TimeInterval = 0.2) {
        
        let loader = ImageLoader(url: url, size: size, fadeOutduration: fadeOutduration)
        self._imageLoader = StateObject(wrappedValue: loader)
    }

    public var body:  some View {
        
        if let uiImage = imageLoader.uiImage {
            
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
        } else {
            
            Text("")
        }
    }
}
