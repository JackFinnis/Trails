//
//  BigLabel.swift
//  News
//
//  Created by Jack Finnis on 13/01/2023.
//

import SwiftUI

struct BigLabel: View {
    let systemName: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            VStack(spacing: 5) {
                Text(title)
                    .font(.title3.bold())
                Text(message)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .allowsHitTesting(false)
    }
}
