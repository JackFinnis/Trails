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
            VStack(spacing: 0) {
                TrailImage(trail: trail)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading) {
                            Text(trail.name)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.headline)
                            HStack(spacing: 0) {
                                if vm.isFavourite(trail) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                        .padding(.trailing, 5)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                if vm.isCompleted(trail) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 5)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                } else if let metres = vm.getTrips(trail: trail)?.metres, metres > 0 {
                                    Text("\(vm.formatDistance(metres, showUnit: false, round: true))/")
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                Text("\(vm.formatDistance(trail.metres, showUnit: true, round: true)) • \(trail.days) days")
                                
                                if let ascent = trail.ascent {
                                    Text(" • ")
                                    Image(systemName: "arrow.up")
                                        .padding(.trailing, 2)
                                        .font(.caption2.weight(.bold))
                                    Text("\(vm.formatDistance(ascent, showUnit: true, round: false))")
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.trailing, 10)
                    
                    Text(trail.headline)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                .padding(10)
            }
        }
        .background(Color(.systemBackground))
        .buttonStyle(.plain)
        .continuousRadius(10)
    }
}

struct TrailRow_Previews: PreviewProvider {
    static var previews: some View {
        TrailRow(trail: .example)
            .environmentObject(ViewModel())
    }
}

