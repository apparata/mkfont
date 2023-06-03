import SwiftUI
import MakeFontKit

struct MainView: View {
    
    @State var isTargeted: Bool = false
    
    @State var isShowingError: Bool = false
    @State var error: Error?

    var body: some View {
        VStack {
            dropArea("Drop .ttf/.otf files here.")
                .frame(width: 220, height: 140)
                .dropDestination(for: URL.self) { urls, location in
                    _ = location
                    Task {
                        do {
                            let url = try await FontGenerator().generate(urls)
                            NSWorkspace.shared.open(url)
                        } catch {
                            dump(error)
                            self.error = error
                            isShowingError = true
                        }
                    }
                    return true
                } isTargeted: { isTargeted in
                    self.isTargeted = isTargeted
                }
            Text("Filenames must be on the form `FontFamily-Style.ttf`")
                .lineLimit(2)
                .frame(width: 200)
                .foregroundColor(.secondary)
            Spacer()
            HStack {
                AlwaysOnTopCheckbox()
                Spacer()
            }
        }
        .padding()
        .background(AlwaysOnTop())
        .alert(error?.localizedDescription ?? "Error: Something went wrong.", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        }
    }
    
    @ViewBuilder func dropArea(_ title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isTargeted ? Color.white.opacity(0.8) : Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 4], dashPhase: 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(title)
        }
    }
}
