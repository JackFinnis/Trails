//
//  ShareView.swift
//  Rivers
//
//  Created by Jack Finnis on 25/06/2022.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension View {
    func shareSheet(items: [Any], isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            let view = ShareView(items: items).ignoresSafeArea()
            if #available(iOS 16, *) {
                view.presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                view
            }
        }
    }
}
