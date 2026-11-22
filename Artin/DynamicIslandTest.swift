
//
//  DynamicIslandTest.swift
//  Artin
//
//  Created by Alvin Phyo Htet on 15/11/26.
//

import SwiftUI
import NotchMyProblem

struct DynamicIslandTest: View {
    
    @State private var isExpanded = false
    
    @State private var BrushList: [String] = ["Pen", "Marker", "Eraser"]
    
    @State private var selectedBrush: String? = nil
    
    @State private var HapticPlaying: Bool = false
    
    @State private var BrushThickeness: Double = 12
    
    @State private var BrushOpacity: Double = 0.85
    
    @State private var selectedControlRow = 0
    @State private var previousDragTranslation = CGSize.zero
    @State private var verticalSelectionApplied = false
    @State private var dragAxis = 0
    @State private var brushSwipeRemainder: CGFloat = 0
    @State private var horizontalHapticRemainder: CGFloat = 0
    @State private var horizontalHapticTick = 0
    @State private var selectedBrushColor: Color = .blue
    @State private var paletteColors: [Color] = [.yellow, .cyan, .pink, .green, .white]
    @State private var selectedPaletteIndex = -1
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
                    let height = rect.height + padding * 2 + (isExpanded ? 300 : 0)
                    
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
                                                    
                                                    HStack(spacing: 5) {
                                                        Image(systemName: brush == "Eraser" ? "eraser.fill" : (brush == "Marker" ? "highlighter" : "pencil") )
                                                        Text(brush)
                                                    }
                                                        .font(.body)
                                                        .fontWeight(isCentered ? .semibold : .regular)
                                                        .foregroundStyle(isCentered ? .black : .white.opacity(0.65))
                                                        .frame(width: itemWidth, height: 44)
                                                        .background(isCentered ? Color.yellow : Color.clear, in: Capsule())
                                                    // GPU-driven scale that tracks finger movement at 120fps with zero lag
                                                        .visualEffect { content, proxy in
                                                            let frame = proxy.frame(in: .scrollView)
                                                            let scrollMidX = proxy.bounds(of: .scrollView)?.midX ?? 0
                                                            let distance = abs(scrollMidX - frame.midX)
                                                            let progress = max(0, 1 - (distance / itemWidth))
                                                            return content.scaleEffect(1.0 + (0.15 * progress))
                                                        }
                                                        .contentShape(Rectangle())
                                                        .onTapGesture {
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
                            .contentShape(Capsule())
                            
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

                                    Slider(value: $BrushThickeness, in: 1...70)
                                        .tint(.yellow)
                                }
                            }
                            .padding(.horizontal, 12)
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            
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

                                    Slider(value: $BrushOpacity, in: 0...1)
                                        .tint(.yellow)
                                }

                            }
                            .padding(.horizontal, 12)
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            
                            HStack(spacing: 12) {
                                BrushStrokePreview(
                                    color: selectedBrushColor,
                                    opacity: BrushOpacity,
                                    thickness: BrushThickeness
                                )
                                .frame(width: 80, height: 80)

                                VStack(spacing: 12) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(paletteColors.indices, id: \.self) { index in
                                                Button {
                                                    selectedPaletteIndex = index
                                                    selectedBrushColor = paletteColors[index]
                                                } label: {
                                                    Circle()
                                                        .fill(paletteColors[index])
                                                        .frame(width: 28, height: 28)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: 164)

                                    ColorPicker("Add custom color", selection: $newPaletteColor, supportsOpacity: false)
                                        .labelsHidden()
                                        .opacity(0.02)
                                        .overlay {
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
                                                Image(systemName: "plus")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundStyle(.white)
                                            }
                                            .allowsHitTesting(false)
                                        }
                                        .frame(width: 36, height: 36)
                                        .accessibilityLabel("Add custom color")
                                        .onChange(of: newPaletteColor) { _, newColor in
                                            selectedBrushColor = newColor
                                            paletteColors.append(newColor)
                                            selectedPaletteIndex = paletteColors.count - 1
                                        }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 12)
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            
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
            .statusBarHidden(true)
            .sensoryFeedback(.selection, trigger: selectedControlRow)
            .sensoryFeedback(.selection, trigger: horizontalHapticTick)
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard isExpanded else { return }

                        let translation = value.translation
                        let deltaX = translation.width - previousDragTranslation.width

                        if dragAxis == 0 {
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
                            selectedControlRow = (selectedControlRow + direction + 4) % 4
                            verticalSelectionApplied = true
                        } else if dragAxis == 1 {
                            if selectedControlRow == 0 {
                                brushSwipeRemainder += deltaX
                                if abs(brushSwipeRemainder) >= 40 {
                                    let brushDirection = brushSwipeRemainder < 0 ? 1 : -1
                                    let currentIndex = BrushList.firstIndex(of: selectedBrush ?? "Marker") ?? 0
                                    let nextIndex = min(BrushList.count - 1, max(0, currentIndex + brushDirection))
                                    selectedBrush = BrushList[nextIndex]
                                    brushSwipeRemainder = 0
                                }
                            } else if selectedControlRow == 1 {
                                BrushThickeness = min(70, max(1, BrushThickeness + deltaX * 0.7))
                            } else if selectedControlRow == 2 {
                                BrushOpacity = min(1, max(0, BrushOpacity + deltaX / 200))
                            } else {
                                paletteSwipeRemainder += deltaX
                                if abs(paletteSwipeRemainder) >= 40 {
                                    let paletteDirection = paletteSwipeRemainder < 0 ? 1 : -1
                                    if selectedPaletteIndex < 0 {
                                        selectedPaletteIndex = paletteDirection > 0 ? 0 : paletteColors.count - 1
                                    } else {
                                        selectedPaletteIndex = min(
                                            paletteColors.count - 1,
                                            max(0, selectedPaletteIndex + paletteDirection)
                                        )
                                    }
                                    selectedBrushColor = paletteColors[selectedPaletteIndex]
                                    paletteSwipeRemainder = 0
                                }
                            }

                            horizontalHapticRemainder += abs(deltaX)
                            if horizontalHapticRemainder >= 10 {
                                horizontalHapticTick += 1
                                horizontalHapticRemainder = 0
                            }
                        }

                        previousDragTranslation = translation
                    }
                    .onEnded { _ in
                        previousDragTranslation = .zero
                        verticalSelectionApplied = false
                        dragAxis = 0
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
