import SwiftUI
import Playgrounds

struct ContentView: View {
    var body: some View {
        DrawingCanvas()
            .background(.white)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
