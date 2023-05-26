//
//  LineChart.swift
//  Trails
//
//  Created by Jack Finnis on 24/05/2023.
//

import SwiftUI

struct ElevationChart: View {
    @EnvironmentObject var vm: ViewModel
    
    let profile: ElevationProfile
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing) {
                Text(String(Int(profile.maxElevation)) + " m")
                Spacer()
                Text(String(Int(profile.minElevation)) + " m")
            }
            .frame(height: 100)
            VStack(alignment: .trailing) {
                GeometryReader { geo in
                    Path { path in
                        path.move(to: profile.points.first!)
                        profile.points.forEach {
                            path.addLine(to: $0)
                        }
                    }
                    .transform(CGAffineTransform(scaleX: geo.size.width, y: geo.size.height))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .rotation3DEffect(.degrees(180), axis: (1, 0, 0))
                }
                .padding(1)
                .frame(height: 100)
                .background(alignment: .leading) {
                    Capsule().fill(Color(.placeholderText))
                        .frame(width: 1)
                }
                .background(alignment: .bottom) {
                    Capsule().fill(Color(.placeholderText))
                        .frame(height: 1)
                        .padding(.leading, 1)
                }
                HStack {
                    Text("0 km")
                    Spacer()
                    Text(vm.formatDistance(profile.distance, showUnit: true, round: false))
                }
            }
        }
        .foregroundColor(.secondary)
        .font(.caption2.bold())
    }
}
