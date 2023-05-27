//
//  TrailImage.swift
//  Trails
//
//  Created by Jack Finnis on 19/04/2023.
//

import SwiftUI

struct TrailImage: View {
    @State var uiImage: UIImage?
    
    let trail: Trail
    
    var body: some View {
        GeometryReader { geo in
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Color(.systemFill)
            }
        }
        .animation(.default, value: uiImage)
        .frame(height: 120)
        .task {
            await fetchImage()
        }
    }
    
    func fetchImage() async {
        guard uiImage == nil else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: trail.photoUrl)
            uiImage = UIImage(data: data)
        } catch {}
    }
}

struct TrailImage_Previews: PreviewProvider {
    static var previews: some View {
        TrailImage(trail: .example)
    }
}
