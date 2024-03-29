//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI
import MessageUI

struct InfoView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: ViewModel
    @State var showShareSheet = false
    @State var showEmailSheet = false
    
    let welcome: Bool
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    VStack(spacing: 10) {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .continuousRadius(70 * 0.2237)
                            .shadow()
                        Text(Constants.name)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                    }
                    .horizontallyCentred()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        InfoRow(systemName: "signpost.right", title: "Adventure Awaits", description: "Discover \(vm.trails.count) long-distance walking trails through the UK's most breathtaking landscapes.")
                        InfoRow(systemName: "point.topleft.down.curvedto.point.bottomright.up", title: "Plan Your Trip", description: "Measure the length of your next trip and view its elevation profile.")
                        InfoRow(systemName: "arrow.triangle.turn.up.right.circle", title: "Get Directions", description: "Long press on your destination.")
                        InfoRow(systemName: "checkmark.circle", title: "Track Your Progress", description: "Mark sections of a trail as completed.")
                        InfoRow(systemName: "ruler", title: "Distance Unit") {
                            MeasurementSystemPicker(speed: false)
                                .frame(width: 250)
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .padding(.top, 5)
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: 450)
                .horizontallyCentred()
            }
            .safeAreaInset(edge: .bottom) {
                Group {
                    if welcome {
                        Button {
                            dismiss()
                        } label: {
                            Text("Continue")
                                .bigButton()
                        }
                    } else {
                        Menu {
                            if MFMailComposeViewController.canSendMail() {
                                Button {
                                    showEmailSheet = true
                                } label: {
                                    Label("Send us Feedback", systemImage: "envelope")
                                }
                            }
                            Button {
                                vm.writeReview()
                            } label: {
                                Label("Write a Review", systemImage: "quote.bubble")
                            }
                            Button {
                                vm.requestRating()
                            } label: {
                                Label("Rate \(Constants.name)", systemImage: "star")
                            }
                            Button {
                                showShareSheet = true
                            } label: {
                                Label("Share \(Constants.name)", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Text("Contribute...")
                                .bigButton()
                        }
                        .sharePopover(items: [Constants.appUrl], showsSharedAlert: true, isPresented: $showShareSheet)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
                .padding(.bottom, verticalSizeClass == .compact ? 0 : 20)
                .background(Color(.systemBackground))
                .frame(maxWidth: 450)
                .horizontallyCentred()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if welcome {
                        Text("")
                    } else {
                        DraggableTitle()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !welcome {
                        Button {
                            dismiss()
                        } label: {
                            DismissCross()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .interactiveDismissDisabled(welcome)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                InfoView(welcome: false)
                    .environmentObject(ViewModel())
            }
    }
}

struct InfoRow<Content: View>: View {
    let systemName: String
    let title: String
    let content: () -> Content
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.headline)
                content()
            }
            Spacer(minLength: 0)
        }
    }
    
    init(systemName: String, title: String, content: @escaping () -> Content) {
        self.systemName = systemName
        self.title = title
        self.content = content
    }
    
    init(systemName: String, title: String, description: String) where Content == Text {
        self.systemName = systemName
        self.title = title
        self.content = {
            Text(description)
                .foregroundColor(.secondary)
        }
    }
}
