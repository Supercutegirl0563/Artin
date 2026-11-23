
//
//  DynamicIslandTest.swift
//  Artin
//
//  Created by Alvin Phyo Htet on 15/11/26.
//

import SwiftUI
import UIKit
import NotchMyProblem

struct DynamicIslandTest: View {
    
    @State private var isExpanded = false
    
    @State private var BrushList: [String] = ["Pen", "Marker", "Eraser"]
    
    @State private var selectedBrush: String? = nil
    
    @State private var HapticPlaying: Bool = false
    
    @State private var BrushThickeness: Double = 12
    
    @State private var BrushOpacity: Double = 0.85
    
    @State private var selectedControlRow = 0
    @State private var controlRowFrames: [Int: CGRect] = [:]
    @State private var activeGestureRow: Int?
    @State private var previousDragTranslation = CGSize.zero
    @State private var verticalSelectionApplied = false
    @State private var dragAxis = 0
    @State private var brushSwipeRemainder: CGFloat = 0
    @State private var horizontalHapticRemainder: CGFloat = 0
    @State private var horizontalHapticTick = 0
    @State private var paletteSelectionHapticTick = 0
    @State private var isShowingAppleColorPicker = false
    @State private var didChangeCustomColor = false
    @State private var selectedBrushColor: Color = .blue
    @State private var paletteColors: [Color] = [.yellow, .cyan, .pink, .green, .white]
    @State private var selectedPaletteIndex = 0
    @State private var isCustomColorSelected = false
    @State private var paletteSwipeRemainder: CGFloat = 0
    @State private var newPaletteColor: Color = .blue
    
    var body: some View {
        
        GeometryReader { geo in
            
            ZStack {
                
                // Background
                Color(
                    red: 145.0 / 255.0,
                    green: 187.0 / 255.0,
                    blue: 255.0 / 255.0
                )
                .ignoresSafeArea()
                
                if let rect = NotchMyProblem.shared.adjustedExclusionRect {
                    
                    let lineWidth: CGFloat = 6
                    let padding: CGFloat = 1
                    
                    let width = rect.width + padding * 2 + (isExpanded ? 220 : 0)
                    let height = rect.height + padding * 2 + (isExpanded ? 340 : 0)
                    
                    let ringColor = Color.white.opacity(0.2)
                    
                    let islandShape = RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                    
                    ZStack {
                        
                        // Visible Dynamic Island
                        islandShape
                            .fill(Color.black)
                            .frame(
                                width: width + 5,
                                height: height + 5
                            )
                            .overlay {
                                
                                // Blue outer ring
                                islandShape
                                    .stroke(
                                        ringColor,
                                        lineWidth: lineWidth
                                    )
                            }
                            .shadow(
                                color: ringColor.opacity(0.8),
                                radius: 9
                            )
                            .shadow(
                                color: .black.opacity(0.2),
                                radius: 8,
                                y: 5
                            )
                        
                        // Content inside Dynamic Island
                        VStack(spacing: 8) {
                            
                            // Brush selection
                            
                            GeometryReader { outerGeo in
                                let itemWidth = outerGeo.size.width / 3
                                let edgePadding = max(0, (outerGeo.size.width - itemWidth) / 2)
                                let centerPoint = outerGeo.frame(in: .global).midX
                                
                                ScrollViewReader { proxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 0) {
                                            ForEach(BrushList, id: \.self) { brush in
                                                GeometryReader { itemGeo in
                                                    let itemMidX = itemGeo.frame(in: .global).midX
                                                    let isCentered = abs(centerPoint - itemMidX) < (itemWidth / 2)
                                                    
                                                    BrushOptionView(brush: brush, isCentered: isCentered, itemWidth: itemWidth) {
                                                        selectedControlRow = 0
                                                        withAnimation(.snappy(duration: 0.25)) {
                                                            selectedBrush = brush
                                                        }
                                                    }
                                                }
                                                .frame(width: itemWidth, height: 50)
                                                .id(brush)
                                                .opacity(isExpanded ? 1 : 0)
                                                .disabled(!isExpanded)
                                            }
                                        }
                                        .scrollTargetLayout()
                                    }
                                    .contentMargins(.horizontal, edgePadding, for: .scrollContent)
                                    .scrollTargetBehavior(.viewAligned)
                                    .scrollPosition(id: $selectedBrush, anchor: .center)
                                    .sensoryFeedback(.selection, trigger: selectedBrush) { oldValue, newValue in
                                        oldValue != nil && newValue != nil && isExpanded
                                    }
                                    .onChange(of: isExpanded) { _, expanded in
                                        if expanded {
                                            let target = selectedBrush ?? "Marker"
                                            selectedBrush = nil
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                selectedBrush = target
                                                proxy.scrollTo(target, anchor: .center)
                                            }
                                        }
                                    }
                                    .onChange(of: outerGeo.size.width) { _, newWidth in
                                        if isExpanded, newWidth > 0, let current = selectedBrush {
                                            proxy.scrollTo(current, anchor: .center)
                                        }
                                    }
                                    .onAppear {
                                        if selectedBrush == nil {
                                            selectedBrush = "Marker"
                                        }
                                    }
                                }
                            }
                            .frame(height: 48)
                            .background(Color.white.opacity(0.14), in: Capsule())
                            .overlay {
                                selectionRectangle(for: 0)
//                                    .padding(.horizontal, -6)
//                                    .padding(.vertical, -5)
                            }
                            .contentShape(Capsule())
                            .background(controlRowFrame(for: 0))
                            
                            // Brush thickness
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Thickness")
                                        Spacer()
                                        Text("\(Int(BrushThickeness)) pt")
                                            .monospacedDigit()
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white)

                                    Slider(value: $BrushThickeness, in: 1...70, onEditingChanged: { isEditing in
                                        if isEditing {
                                            selectedControlRow = 1
                                        }
                                    })
                                    .tint(.yellow)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background {
                                selectionRectangle(for: 1)
                            }
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            .background(controlRowFrame(for: 1))
                            
                            // Brush opacity
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Opacity")
                                        Spacer()
                                        Text("\(Int(BrushOpacity * 100))%")
                                            .monospacedDigit()
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white)

                                    Slider(value: $BrushOpacity, in: 0...1, onEditingChanged: { isEditing in
                                        if isEditing {
                                            selectedControlRow = 2
                                        }
                                    })
                                    .tint(.yellow)
                                }

                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background {
                                selectionRectangle(for: 2)
                            }
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            .background(controlRowFrame(for: 2))
                            // Preview
                            HStack(spacing: 12) {
                                BrushStrokePreview(
                                    color: selectedBrushColor,
                                    opacity: BrushOpacity,
                                    thickness: BrushThickeness
                                )
                                .frame(width: 80, height: 80)
                                // Color palette and custom color picker
                                VStack(spacing: 12) {
                                    ScrollViewReader { paletteScrollProxy in
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(paletteColors.indices, id: \.self) { index in
                                                    Button {
                                                        selectedControlRow = 3
                                                        if selectedPaletteIndex != index || isCustomColorSelected {
                                                            paletteSelectionHapticTick += 1
                                                        }
                                                        selectedPaletteIndex = index
                                                        isCustomColorSelected = false
                                                        selectedBrushColor = paletteColors[index]
                                                    } label: {
                                                        Circle()
                                                            .fill(paletteColors[index])
                                                            .frame(width: 28, height: 28)
                                                            .overlay {
                                                                Circle()
                                                                    .stroke(
                                                                        Color.blue.opacity(!isCustomColorSelected && selectedPaletteIndex == index ? 1 : 0),
                                                                        lineWidth: 3
                                                                    )
                                                                    .padding(-4)
                                                            }
                                                    }
                                                    .buttonStyle(.plain)
                                                    .padding(.vertical, 7)
                                                    .id(index)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: 180)
                                        .onChange(of: selectedPaletteIndex) { _, index in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                paletteScrollProxy.scrollTo(index, anchor: .center)
                                            }
                                        }
                                    }

                                    Button {
                                        selectedControlRow = 3
                                        isCustomColorSelected = true
                                        isShowingAppleColorPicker = true
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .stroke(
                                                    AngularGradient(
                                                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
                                                        center: .center
                                                    ),
                                                    lineWidth: 4
                                                )
                                                .frame(width: 36, height: 36)
                                            Circle()
                                                .stroke(
                                                    Color.blue.opacity(isCustomColorSelected ? 1 : 0),
                                                    lineWidth: 3
                                                )
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 44, height: 44)
                                    .accessibilityLabel("Add custom color")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background {
                                selectionRectangle(for: 3)
                                    .padding(.horizontal, -6)
                                    .padding(.vertical, -8)
                                    .offset(y: 10)
                            }
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            .background(controlRowFrame(for: 3))
                            
                        }
                        .frame(
                            width: width - 10,
                            height: height - 10
                        )
                        .multilineTextAlignment(.center)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7),
                            value: isExpanded
                        )
                    }
                    .position(
                        x: rect.midX,
                        y: (rect.minY - 2) + padding + height / 2
                    )
                }
            }
            .coordinateSpace(name: "toolboxRows")
            .onPreferenceChange(ControlRowFramesKey.self) { controlRowFrames = $0 }
            .statusBarHidden(true)
            .sensoryFeedback(.selection, trigger: selectedControlRow) { oldValue, newValue in
                oldValue != newValue && newValue != 3
            }
            .sensoryFeedback(.selection, trigger: paletteSelectionHapticTick)
            .sensoryFeedback(.selection, trigger: horizontalHapticTick)
            .simultaneousGesture(
                TapGesture().onEnded {
                    if isExpanded, selectedControlRow == 3, isCustomColorSelected {
                        isShowingAppleColorPicker = true
                    }
                }
            )
            .onChange(of: newPaletteColor) { _, newColor in
                selectedBrushColor = newColor
                didChangeCustomColor = true
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("toolboxRows"))
                    .onChanged { value in
                        guard isExpanded else { return }

                        let translation = value.translation
                        let deltaX = translation.width - previousDragTranslation.width

                        if dragAxis == 0 {
                            activeGestureRow = controlRowFrames.first {
                                $0.value.contains(value.startLocation)
                            }?.key
                            if let activeGestureRow {
                                selectedControlRow = activeGestureRow
                            }

                            if abs(translation.width) > 8, abs(translation.width) > abs(translation.height) {
                                dragAxis = 1
                            } else if abs(translation.height) > 8, abs(translation.height) > abs(translation.width) {
                                dragAxis = 2
                            }
                        }

                        if dragAxis == 2,
                           abs(translation.height) >= 30,
                           !verticalSelectionApplied {
                            let direction = translation.height > 0 ? 1 : -1
                            if selectedControlRow == 3, direction > 0, !isCustomColorSelected {
                                isCustomColorSelected = true
                            } else if selectedControlRow == 3, direction < 0, isCustomColorSelected {
                                isCustomColorSelected = false
                            } else {
                                selectedControlRow = (selectedControlRow + direction + 4) % 4
                                if selectedControlRow == 3,
                                   selectedPaletteIndex < 0,
                                   !isCustomColorSelected {
                                    selectedPaletteIndex = 0
                                }
                            }
                            verticalSelectionApplied = true
                        } else if dragAxis == 1 {
                            let activeRow = activeGestureRow ?? selectedControlRow
                            selectedControlRow = activeRow
                            if activeRow == 0 {
                                brushSwipeRemainder += deltaX
                                if abs(brushSwipeRemainder) >= 40 {
                                    let brushDirection = brushSwipeRemainder < 0 ? 1 : -1
                                    let currentIndex = BrushList.firstIndex(of: selectedBrush ?? "Marker") ?? 0
                                    let nextIndex = min(BrushList.count - 1, max(0, currentIndex + brushDirection))
                                    selectedBrush = BrushList[nextIndex]
                                    brushSwipeRemainder = 0
                                }
                            } else if activeRow == 1 {
                                BrushThickeness = min(70, max(1, BrushThickeness + deltaX * 0.7))
                            } else if activeRow == 2 {
                                BrushOpacity = min(1, max(0, BrushOpacity + deltaX / 200))
                            } else {
                                paletteSwipeRemainder += deltaX
                                while abs(paletteSwipeRemainder) >= 40 {
                                    let paletteDirection = paletteSwipeRemainder < 0 ? 1 : -1
                                    let previousPaletteIndex = selectedPaletteIndex
                                    let wasCustomColorSelected = isCustomColorSelected
                                    let nextPaletteIndex: Int
                                    if isCustomColorSelected {
                                        nextPaletteIndex = paletteDirection > 0 ? 0 : paletteColors.count - 1
                                    } else {
                                        nextPaletteIndex = min(
                                            paletteColors.count - 1,
                                            max(0, selectedPaletteIndex + paletteDirection)
                                        )
                                    }

                                    guard wasCustomColorSelected || nextPaletteIndex != previousPaletteIndex else {
                                        paletteSwipeRemainder = 0
                                        break
                                    }

                                    selectedPaletteIndex = nextPaletteIndex
                                    isCustomColorSelected = false
                                    selectedBrushColor = paletteColors[selectedPaletteIndex]
                                    paletteSelectionHapticTick += 1
                                    paletteSwipeRemainder += CGFloat(paletteDirection) * 40
                                }
                            }

                            if activeRow == 1 || activeRow == 2 {
                                horizontalHapticRemainder += abs(deltaX)
                                if horizontalHapticRemainder >= 10 {
                                    horizontalHapticTick += 1
                                    horizontalHapticRemainder = 0
                                }
                            }
                        }

                        previousDragTranslation = translation
                    }
                    .onEnded { _ in
                        previousDragTranslation = .zero
                        verticalSelectionApplied = false
                        dragAxis = 0
                        activeGestureRow = nil
                        brushSwipeRemainder = 0
                        paletteSwipeRemainder = 0
                        horizontalHapticRemainder = 0
                    }
            )
            .onTapGesture(count: 3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $isShowingAppleColorPicker, onDismiss: finishCustomColorSelection) {
            AppleColorPicker(color: $newPaletteColor)
                .ignoresSafeArea()
        }
    }
    
    private func finishCustomColorSelection() {
        selectedBrushColor = newPaletteColor
        if didChangeCustomColor {
            paletteColors.append(newPaletteColor)
            if paletteColors.count > 15 {
                paletteColors.remove(at: 5)
                if selectedPaletteIndex > 5 {
                    selectedPaletteIndex -= 1
                }
            }
        }
        isCustomColorSelected = true
        didChangeCustomColor = false
    }
    
    private func controlRowFrame(for row: Int) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: ControlRowFramesKey.self,
                value: [row: geometry.frame(in: .named("toolboxRows"))]
            )
        }
    }
    
    @ViewBuilder
    private func selectionRectangle(for row: Int) -> some View {
        let isSelected = isExpanded && selectedControlRow == row
        
        if row == 0 {
            Capsule()
                .fill(Color.blue.opacity(0))
                .overlay {
                    Capsule()
                        .stroke(Color.blue.opacity(isSelected ? 0.9 : 0), lineWidth: 3)
                }
        } else {
            Rectangle()
                .fill(Color.blue.opacity(0))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(isSelected ? 0.9 : 0), lineWidth: 3)
                }
        }
    }
}

private struct AppleColorPicker: UIViewControllerRepresentable {
    @Binding var color: Color
    
    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let controller = UIColorPickerViewController()
        controller.delegate = context.coordinator
        controller.supportsAlpha = false
        controller.selectedColor = UIColor(color)
        return controller
    }
    
    func updateUIViewController(_ controller: UIColorPickerViewController, context: Context) {
        let selectedColor = UIColor(color)
        if !controller.selectedColor.isEqual(selectedColor) {
            controller.selectedColor = selectedColor
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(color: $color)
    }
    
    @MainActor
    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        @Binding private var color: Color
        
        init(color: Binding<Color>) {
            _color = color
        }
        
        func colorPickerViewController(
            _ viewController: UIColorPickerViewController,
            didSelect color: UIColor,
            continuously: Bool
        ) {
            self.color = Color(uiColor: color)
        }
    }
}

private struct BrushOptionView: View {
    let brush: String
    let isCentered: Bool
    let itemWidth: CGFloat
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: brush == "Eraser" ? "eraser.fill" : (brush == "Marker" ? "highlighter" : "pencil"))
            Text(brush)
        }
        .font(.body)
        .fontWeight(isCentered ? .semibold : .regular)
        .foregroundStyle(isCentered ? .black : .white.opacity(0.65))
        .frame(width: itemWidth, height: 44)
        .background(isCentered ? Color.yellow : Color.clear, in: Capsule())
        .padding(.vertical, 2)
        .visualEffect { content, proxy in
            let frame = proxy.frame(in: .scrollView)
            let scrollMidX = proxy.bounds(of: .scrollView)?.midX ?? 0
            let distance = abs(scrollMidX - frame.midX)
            let progress = max(0, 1 - distance / itemWidth)
            return content.scaleEffect(1 + 0.15 * progress)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

private struct ControlRowFramesKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

private struct BrushStrokePreview: View {
    let color: Color
    let opacity: Double
    let thickness: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.14))

                Canvas { context, size in
                    var strokePath = Path()
                    strokePath.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.79))
                    strokePath.addCurve(
                        to: CGPoint(x: size.width * 0.83, y: size.height * 0.20),
                        control1: CGPoint(x: size.width * 0.28, y: size.height * 0.72),
                        control2: CGPoint(x: size.width * 0.64, y: size.height * 0.29)
                    )
                    context.stroke(
                        strokePath,
                        with: .color(color.opacity(opacity)),
                        style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round)
                    )
                }
                .padding(8)
            }
        }
    }
}

#Preview {
    DynamicIslandTest()
}
