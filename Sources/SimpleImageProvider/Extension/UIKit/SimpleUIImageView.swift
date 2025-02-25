//
//  SimpleUIImageView.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

public extension UIImageView {
    func load(url: String, size: CGSize?, fadeOutDuration: TimeInterval = 0.2) {
        Task {
            let loadedImage = await DefaultImageProvider.shared
                .requestImage(url: url, size: size)
            if let loadedImage {
                await MainActor.run {
                    UIView.transition(
                        with: self,
                        duration: fadeOutDuration,
                        options: .transitionCrossDissolve
                    ) { self.image = loadedImage }
                }
            }
        }
    }
}
