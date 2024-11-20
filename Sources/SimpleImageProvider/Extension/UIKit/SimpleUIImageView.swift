//
//  SimpleUIImageView.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

public class SimpleUIImageView: @unchecked Sendable {
    
    private weak var imageView: UIImageView?
    
    private init(view: UIImageView) {
        self.imageView = view
    }
    
    public func setImage(url: String, size: CGSize?) {
        
        Task { [weak self] in
            
            guard let self else { return }
            
            let image = await SimpleImageProvider.shared
                .requestImage(url: url, size: size)
            
            if let image, let imageView {
                
                await MainActor.run {
                    
                    UIView.transition(with: imageView, duration: 0.2) {
                        
                        imageView.image = image
                    }
                }
            }
        }
    }
}
