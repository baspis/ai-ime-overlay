import SwiftUI

enum ConversionPanelState: Equatable {
    case idle
    case converting
    case ready
    case error(String)
}

@MainActor
final class ConversionPanelModel: ObservableObject {
    @Published var romajiInput = ""
    @Published var previewText = ""
    @Published var state: ConversionPanelState = .idle

    var canCommit: Bool {
        if case .ready = state, !previewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    func reset() {
        romajiInput = ""
        previewText = ""
        state = .idle
    }

    func beginConverting() {
        state = .converting
    }

    func finishConverting(with result: String) {
        previewText = result
        state = .ready
    }

    func failConverting(message: String) {
        state = .error(message)
    }
}

struct ConversionPanelView: View {
    @ObservedObject var model: ConversionPanelModel
    var onConvert: () -> Void
    var onCommit: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Romaji Converter")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Romaji")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Type romaji here", text: $model.romajiInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                    if model.previewText.isEmpty && !isConverting {
                        Text("Converted text appears here")
                            .foregroundStyle(.tertiary)
                            .padding(8)
                    } else {
                        Text(model.previewText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    if isConverting {
                        ProgressView()
                            .controlSize(.small)
                            .padding(8)
                    }
                }
                .frame(minHeight: 56)
            }

            if case .error(let message) = model.state {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 16) {
                Label("Convert", systemImage: "return")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("⌃↩")
                    .font(.caption.monospaced())
                Spacer()
                Label("Insert", systemImage: "arrow.down.to.line")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("↩")
                    .font(.caption.monospaced())
                Spacer()
                Label("Close", systemImage: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("esc")
                    .font(.caption.monospaced())
            }

            HStack {
                Spacer()
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(16)
        .frame(width: 420)
    }

    private var isConverting: Bool {
        if case .converting = model.state { return true }
        return false
    }
}
