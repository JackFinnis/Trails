//
//  WaypointButton.swift
//  Trails
//
//  Created by Jack Finnis on 27/05/2023.
//

import SwiftUI
import MapKit

struct WaypointButton: View {
    @EnvironmentObject var vm: ViewModel
    
    let annotation: MKAnnotation
    let title: String
    let type: WaypointType
    
    var body: some View {
        Button {
            vm.mapView?.selectAnnotation(annotation, animated: true)
            vm.ensureMapVisible()
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                }
                .foregroundColor(.primary)
                Spacer(minLength: 0)
                Image(systemName: "map")
                    .font(.title3)
                    .padding(.top, 5)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .containerBackground(light: true)
        }
    }
}
