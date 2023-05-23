//
//  TrailRow.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailRow: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vm: ViewModel
    
    let trail: Trail
    
    var body: some View {
        Button {
            vm.selectTrail(trail)
            vm.sheetDetent = .medium
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                TrailImage(trail: trail)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(trail.name)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.headline)
                    
                    HStack(spacing: 0) {
                        if vm.isCompleted(trail) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .padding(.trailing, 5)
                        } else if let metres = vm.getTrips(trail: trail)?.metres, metres > 0 {
                            Text("\(vm.formatDistance(metres, showUnit: false, round: true))/")
                        }
                        Text("\(vm.formatDistance(trail.metres, showUnit: true, round: true)) • \(trail.days) days")
                        
                        if let ascent = trail.ascent {
                            Text(" • ")
                            Image(systemName: "arrow.up")
                                .padding(.trailing, 2)
                                .font(.caption2.weight(.bold))
                            Text("\(vm.formatDistance(ascent, showUnit: true, round: false))")
                        }
                        Spacer(minLength: 0)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                    
                    Text(trail.headline)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .overlay(alignment: .topTrailing) {
                    if vm.isFavourite(trail) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                .padding(10)
            }
            .background(Color(colorScheme == .light ? .white : .secondarySystemBackground))
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
