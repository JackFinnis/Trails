//
//  DismissCross.swift
//  Change
//
//  Created by Jack Finnis on 20/10/2022.
//

import SwiftUI

struct DismissCross: View {
    let toolbar: Bool
    
    var body: some View {
        Image(systemName: "xmark.circle.fill")
            .font(toolbar ? .title2 : .title)
            .foregroundStyle(.secondary, Color(.tertiarySystemFill))
    }
}
