//
//  EmailView.swift
//  Trails
//
//  Created by Jack Finnis on 21/03/2023.
//

import SwiftUI
import MessageUI

struct EmailView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients([recipient])
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: EmailView

        init(_ parent: EmailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

extension View {
    func emailSheet(recipient: String, subject: String, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            EmailView(recipient: recipient, subject: subject).ignoresSafeArea()
        }
    }
}
