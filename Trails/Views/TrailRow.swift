//
//  TrailRow.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailRow: View {
    @EnvironmentObject var vm: ViewModel
    
    let trail: Trail
    
    var body: some View {
        Button {
            vm.selectTrail(trail)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                TrailImage(trail: trail)
                    .overlay(alignment: .bottomTrailing) {
                        if trail.cycleway {
                            Image(systemName: "bicycle")
                                .font(.subheadline)
                                .padding(4)
                                .background(.thickMaterial)
                                .continuousRadius(5)
                                .padding(5)
                        }
                    }
                
                let padding = 10.0
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 5) {
                        Text(trail.name)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.headline)
                        Spacer(minLength: 0)
                        if vm.isFavourite(trail) {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, padding)
                    
                    HStack(spacing: 0) {
                        if vm.isCompleted(trail) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .padding(.trailing, 5)
                        } else if let metres = vm.getTrips(trail)?.metres, metres != 0 {
                            Text("\(vm.formatDistance(metres, unit: false, round: true))/")
                        }
                        Text("\(vm.formatDistance(trail.metres, unit: true, round: true)) • \(trail.days) days • ")
                        Image(systemName: "arrow.up.forward")
                            .padding(.trailing, 2)
                            .font(.caption.weight(.bold))
                        Text("\(vm.formatDistance(trail.ascent, unit: true, round: false))")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, padding)
                    .padding(.bottom, 5)
                    
                    Text(trail.headline)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, padding)
                }
                .padding(.vertical, padding)
            }
            .containerBackground(light: true)
            .continuousRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct TrailRow_Previews: PreviewProvider {
    static var previews: some View {
        TrailRow(trail: .example)
            .environmentObject(ViewModel())
    }
}
