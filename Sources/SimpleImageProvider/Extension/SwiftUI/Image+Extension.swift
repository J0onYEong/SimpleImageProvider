//
//  Image+Extension.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import SwiftUI

class ImageSource: @unchecked Sendable, ObservableObject {
    // State
    @Published var image: UIImage?
    
    // Config
    private let url: String
    private let size: CGSize?
    private let fadeOutduration: TimeInterval
    
    init(url: String, size: CGSize?, fadeOutduration: TimeInterval) {
        self.url = url
        self.size = size
        self.fadeOutduration = fadeOutduration
    }
    
    func loadImage() {
        image = nil
        Task {
            let image = await DefaultImageProvider.shared
                .requestImage(url: url, size: size)
            await MainActor.run { [weak self] in
                guard let self else { return }
                withAnimation(.easeInOut(duration: fadeOutduration)) {
                    self.image = image
                }
            }
        }
    }
}
