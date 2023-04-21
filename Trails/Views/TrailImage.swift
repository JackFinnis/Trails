//
//  TrailImage.swift
//  Trails
//
//  Created by Jack Finnis on 19/04/2023.
//

import SwiftUI

struct TrailImage: View {
    let trail: Trail
    
    var body: some View {
        GeometryReader { geo in
            AsyncImage(url: trail.photoUrl, transaction: Transaction(animation: .default)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemFill)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .frame(height: 120)
    }
}

struct TrailImage_Previews: PreviewProvider {
    static var previews: some View {
        TrailImage(trail: .example)
    }
}
