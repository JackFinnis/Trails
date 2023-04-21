//
//  BigLabel.swift
//  Trails
//
//  Created by Jack Finnis on 18/04/2023.
//

import SwiftUI

struct BigLabel: View {
    let systemName: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            VStack(spacing: 5) {
                Text(title)
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .allowsHitTesting(false)
    }
}
