//
//  TrailImage.swift
//  Trails
//
//  Created by Jack Finnis on 19/04/2023.
//

import SwiftUI

struct TrailImage: View {
    @StateObject var imageHelper = ImageHelper.shared
    
    let trail: Trail
    
    var body: some View {
        GeometryReader { geo in
            if let uiImage = imageHelper.images[trail.photoUrl] {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Color(.systemFill)
            }
        }
        .animation(.default, value: imageHelper.images)
        .frame(height: 120)
        .task {
            await imageHelper.fetchImage(url: trail.photoUrl)
        }
    }
}

struct TrailImage_Previews: PreviewProvider {
    static var previews: some View {
        TrailImage(trail: .example)
    }
}

@MainActor
class ImageHelper: ObservableObject {
    static let shared = ImageHelper()
    
    @Published var images = [URL: UIImage]()
    
    func fetchImage(url: URL) async {
        guard images[url] == nil else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            images[url] = UIImage(data: data)
        } catch {}
    }
}
