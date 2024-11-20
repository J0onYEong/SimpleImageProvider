//
//  Image+Extension.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import SwiftUI

class ImageLoader: @unchecked Sendable, ObservableObject {
    @Published var uiImage: UIImage?

    init(url: String, size: CGSize?) {
        
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

struct UIImageToImageModifier: ViewModifier {
    
    @StateObject var imageLoader: ImageLoader
    
    init(url: String, size: CGSize?) {
        
        self._imageLoader = StateObject(wrappedValue: ImageLoader(url: url, size: size))
    }

    func body(content: Content) -> some View {
        
        if let uiImage = imageLoader.uiImage {
            
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
        } else {
            
            content
        }
    }
}

extension View {
    func simpleImage(url: String, size: CGSize?) -> some View {
        self.modifier(UIImageToImageModifier(url: url, size: size))
    }
}
