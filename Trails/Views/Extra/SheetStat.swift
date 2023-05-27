//
//  SheetStat.swift
//  Trails
//
//  Created by Jack Finnis on 27/05/2023.
//

import SwiftUI

struct SheetStat: View {
    let name: String
    let value: String
    let systemName: String
    var tint: Color = .secondary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .font(.caption2.weight(.bold))
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.footnote.weight(.bold))
                    .foregroundColor(tint)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
    }
}
