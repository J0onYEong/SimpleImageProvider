//
//  SimpleImage.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/25/25.
//

import SwiftUI

public struct SimpleImage: View {
    // Source of truth
    @StateObject var imageSource: ImageSource
    
    public init(url: String, size: CGSize?, fadeOutduration: TimeInterval = 0.2) {
        let source = ImageSource(
            url: url,
            size: size,
            fadeOutduration: fadeOutduration
        )
        self._imageSource = StateObject(wrappedValue: source)
    }

    public var body:  some View {
        if let loadedImage = imageSource.image {
            Image(uiImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Text("")
                .onAppear { imageSource.loadImage() }
        }
    }
}
