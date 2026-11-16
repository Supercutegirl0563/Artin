import SwiftUI
import PencilKit

struct DrawingCanvas: UIViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PKCanvasView {

        let canvas = PKCanvasView()

        canvas.backgroundColor = .white
        canvas.drawingPolicy = .anyInput

        canvas.tool = PKInkingTool(
            .pen,
            color: .black,
            width: 5
        )

        // Connect the tool picker
        let toolPicker = context.coordinator.toolPicker

        toolPicker.addObserver(canvas)
        toolPicker.setVisible(true, forFirstResponder: canvas)

        // Make the canvas receive input
        DispatchQueue.main.async {
            canvas.becomeFirstResponder()
        }

        return canvas
    }

    func updateUIView(
        _ uiView: PKCanvasView,
        context: Context
    ) {
    }

    // Coordinator keeps the tool picker alive
    class Coordinator: NSObject {

        let toolPicker = PKToolPicker()

    }
}
