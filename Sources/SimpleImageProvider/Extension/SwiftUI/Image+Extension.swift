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

    init(url: String, size: CGSize?) {
        
        self.url = url
        self.size = size
        
        loadImage()
    }
    
    func loadImage() {
        
        Task {
            
            let image = await SimpleImageProvider.shared
                .requestImage(url: url, size: size)
            
            await MainActor.run { [weak self] in
                
                withAnimation {
                    
                    self?.uiImage = image
                }
            }
        }
    }
}

public struct SimpleImage: View {
    
    @StateObject var imageLoader: ImageLoader
    
    public init(url: String, size: CGSize?) {
        
        self._imageLoader = StateObject(wrappedValue: ImageLoader(url: url, size: size))
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
