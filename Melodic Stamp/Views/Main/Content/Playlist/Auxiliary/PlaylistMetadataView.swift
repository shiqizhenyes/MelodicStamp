//
//  PlaylistMetadataView.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/30.
//

import Luminare
import SwiftUI
import SwiftUIIntrospect

struct PlaylistMetadataView: View {
    @Environment(\.luminareAnimation) private var animation

    @FocusState private var isTitleFocused: Bool

    var status: Playlist.Status

    @State private var isTitleHovering: Bool = false
    @State private var isImagePickerPresented: Bool = false
    @State private var isDescriptionSheetPresented: Bool = false

    var body: some View {
        HStack(spacing: 25) {
            Button {
                isImagePickerPresented = true
            } label: {
                artworkView()
                    .motionCard()
            }
            .buttonStyle(.alive)
            .fileImporter(
                isPresented: $isImagePickerPresented,
                allowedContentTypes: AttachedPicturesHandlerModel
                    .allowedContentTypes
            ) { result in
                switch result {
                case let .success(url):
                    guard url.startAccessingSecurityScopedResource() else { break }
                    defer { url.stopAccessingSecurityScopedResource() }

                    guard let image = NSImage(contentsOf: url) else { break }
                    status.segments.artwork.tiffRepresentation = image.tiffRepresentation
                    try? status.write(segments: [.artwork])
                case .failure:
                    break
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 5)
            .animation(nil, value: isTitleHovering)
            .animation(nil, value: isTitleFocused)

            VStack(alignment: .leading) {
                titleView()
                    .font(.title)

                Button {
                    isDescriptionSheetPresented = true
                } label: {
                    descriptionView()
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.alive)
                .sheet(isPresented: $isDescriptionSheetPresented) {
                    try? status.write(segments: [.info])
                } content: {
                    // In order to make safe area work, we need a wrapper
                    ScrollView {
                        LuminareTextEditor(text: status.segmentsBinding.info.description)
                            .luminareBordered(false)
                            .luminareHasBackground(false)
                            .scrollDisabled(true)
                    }
                    .scrollContentBackground(.hidden)
                    .scrollClipDisabled()
                    .presentationAttachmentBar(edge: .top, attachment: controls)
                    .presentationSizing(.fitted)
                    .frame(minWidth: 725, minHeight: 500, maxHeight: 1200)
                }
            }
        }
        .frame(height: 250)
        .animation(animation, value: isTitleHovering)
        .animation(animation, value: isTitleFocused)
    }

    @ViewBuilder private func artworkView() -> some View {
        if let artwork = status.segments.artwork.image {
            MusicCover(images: [artwork], cornerRadius: 8)
        } else {
            MusicCover(cornerRadius: 8)
        }
    }

    @ViewBuilder private func titleView() -> some View {
        HStack {
            TextField("Playlist Title", text: status.segmentsBinding.info.title)
                .bold()
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onSubmit {
                    isTitleFocused = false
                }

            if !isTitleFocused {
                HStack {
                    if isTitleHovering {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([status.url])
                        } label: {
                            HStack {
                                if let creationDate = try? status.url.attribute(.creationDate) as? Date {
                                    let formattedCreationDate = creationDate.formatted(
                                        date: .complete,
                                        time: .standard
                                    )
                                    Text("Created at \(formattedCreationDate)")
                                }

                                Image(systemSymbol: .folder)
                            }
                            .foregroundStyle(.placeholder)
                        }
                        .buttonStyle(.alive)
                    } else {
                        Text("\(status.count) Tracks")
                    }
                }
                .font(.body)
                .foregroundStyle(.placeholder)
                .transition(.blurReplace)
            }
        }
        .onHover { hover in
            isTitleHovering = hover
        }
        .onChange(of: isTitleFocused) { _, newValue in
            guard !newValue else { return }
            try? status.write(segments: [.info])
        }
    }

    @ViewBuilder private func descriptionView() -> some View {
        let description = status.segments.info.description

        if !description.isEmpty {
            Text(description)
        } else {
            Image(systemSymbol: .ellipsisCircleFill)
                .imageScale(.large)
                .padding(.vertical, 2)
        }
    }

    @ViewBuilder private func controls() -> some View {
        Group {
            Text("Playlist Description")
                .bold()

            Spacer()

            Button {
                isDescriptionSheetPresented = false
            } label: {
                Text("Done")
            }
            .foregroundStyle(.tint)
        }
        .buttonStyle(.alive)
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var segments: Playlist.Segments = PreviewEnvironments.samplePlaylistSegments

        PlaylistMetadataView(
            status: PreviewEnvironments.samplePlaylist.status
        )
    }
#endif
