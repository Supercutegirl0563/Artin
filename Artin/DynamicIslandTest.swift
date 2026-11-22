
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
    
    @State private var BrushThickeness: Double = 45
    
    @State private var BrushOpacity: Double = 0.5
    
    @State private var selectedControlRow = 0
    @State private var previousDragTranslation = CGSize.zero
    @State private var verticalSelectionApplied = false
    @State private var dragAxis = 0
    @State private var brushSwipeRemainder: CGFloat = 0
    @State private var horizontalHapticRemainder: CGFloat = 0
    @State private var horizontalHapticTick = 0
    @State private var isColorPickerPresented = false
    @State private var pickerHue = 0.0
    @State private var colorPickerHapticTick = 0
    @State private var selectedColorRGB = RGBColor(red: 1, green: 0, blue: 0)
    
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
                    
                    let lineWidth: CGFloat = 8
                    let padding: CGFloat = 1
                    
                    let width = rect.width + padding * 2 + (isExpanded && !isColorPickerPresented ? 100 : 0)
                    let height = rect.height + padding * 2 + (isExpanded && !isColorPickerPresented ? 280 : 0)
                    
                    let ringColor = Color(
                        red: 45.0 / 255.0,
                        green: 105.0 / 255.0,
                        blue: 210.0 / 255.0
                    )
                    
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
                                        lineWidth: lineWidth - 4
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
                            .overlay {
                                if isColorPickerPresented {
                                    ColorPickerRing(hue: pickerHue)
                                        .frame(width: 220, height: 220)
                                }
                            }
                        
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
                                                    
                                                    Text(brush)
                                                        .font(.body)
                                                    // Instant font weight and color (no animation wrapper delaying the swap)
                                                        .fontWeight(isCentered ? .bold : .regular)
                                                        .foregroundStyle(isCentered ? .yellow : .white.opacity(0.6))
                                                        .frame(width: itemWidth, height: 50)
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
                            .frame(height: 50)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ringColor.opacity(isExpanded && selectedControlRow == 0 ? 0.5 : 0))
                            }
                            .contentShape(Rectangle())
                            
                            // Brush thickness
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Thickness")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                    
                                    Slider(value: $BrushThickeness, in: 0...70)
                                        .tint(.yellow)
                                }
                                
//                                CirclePreview(circleSize: BrushThickeness, circleOpacity: 1)
                            }
                            .padding(.horizontal, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ringColor.opacity(selectedControlRow == 1 ? 0.5 : 0))
                            }
                            .contentShape(Rectangle())
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            
                            // Brush opacity
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Opacity")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                    
                                    Slider(value: $BrushOpacity, in: 0...1)
                                        .tint(.yellow)
                                }

                            }
                            .padding(.horizontal, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ringColor.opacity(selectedControlRow == 2 ? 0.5 : 0))
                            }
                            .contentShape(Rectangle())
                            .opacity(isExpanded ? 1 : 0)
                            .disabled(!isExpanded)
                            
                            CirclePreview(
                                circleSize: BrushThickeness,
                                circleOpacity: BrushOpacity,
                                circleColor: selectedColorRGB.color
                            )
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .offset(y: 10)
                                        .fill(ringColor.opacity(selectedControlRow == 3 ? 0.5 : 0))
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedControlRow = 3
                                    isExpanded = false
                                    isColorPickerPresented = true
                                }
                                .opacity(isExpanded ? 1 : 0)
                                .disabled(!isExpanded)
                            
                        }
                        .frame(
                            width: width - 10,
                            height: height - 10
                        )
                        .multilineTextAlignment(.center)
                        .opacity(isColorPickerPresented ? 0 : 1)
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
            .sensoryFeedback(.selection, trigger: colorPickerHapticTick)
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard isExpanded || isColorPickerPresented else { return }

                        let translation = value.translation
                        let deltaX = translation.width - previousDragTranslation.width

                        if dragAxis == 0 {
                            if abs(translation.width) > 8, abs(translation.width) > abs(translation.height) {
                                dragAxis = 1
                            } else if abs(translation.height) > 8, abs(translation.height) > abs(translation.width) {
                                dragAxis = 2
                            }
                        }

                        if isColorPickerPresented {
                            if dragAxis == 1 {
                                pickerHue = (pickerHue + Double(deltaX / 300)).wrappedHue
                                horizontalHapticRemainder += abs(deltaX)
                                if horizontalHapticRemainder >= 10 {
                                    colorPickerHapticTick += 1
                                    horizontalHapticRemainder = 0
                                }
                            }
                        } else if dragAxis == 2,
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
                            } else {
                                if selectedControlRow == 1 {
                                    BrushThickeness = min(70, max(0, BrushThickeness + deltaX * 0.7))
                                } else if selectedControlRow == 2 {
                                    BrushOpacity = min(1, max(0, BrushOpacity + deltaX / 200))
                                }

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
                        brushSwipeRemainder = 0
                        horizontalHapticRemainder = 0
                    }
            )
            .onTapGesture(count: 2) {
                guard isColorPickerPresented else { return }

                let color = UIColor(
                    hue: CGFloat(pickerHue),
                    saturation: 1,
                    brightness: 1,
                    alpha: 1
                )
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: nil)
                selectedColorRGB = RGBColor(
                    red: Double(red),
                    green: Double(green),
                    blue: Double(blue)
                )

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isColorPickerPresented = false
                    isExpanded = true
                }
            }
            .onTapGesture(count: 3) {
                guard !isColorPickerPresented else { return }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct CirclePreview: View {
    let circleSize: CGFloat
    let circleOpacity: Double
    let circleColor: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .offset(y: 10)
            .fill(Color.white.opacity(0.15))
            .frame(width: 70, height: 70)
            .overlay {
                Circle()
                    .fill(circleColor.opacity(circleOpacity))
                    .frame(width: circleSize, height: circleSize)
                    .offset(y: 10)
            }
    }
}

private struct ColorPickerRing: View {
    let hue: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )

            Capsule()
                .fill(.white)
                .frame(width: 5, height: 28)
                .shadow(color: .black.opacity(0.8), radius: 3)
                .offset(y: -101)
                .rotationEffect(.degrees(hue * 360))
        }
        .frame(width: 220, height: 220)
    }
}

private struct RGBColor {
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

private extension Double {
    var wrappedHue: Double {
        let remainder = truncatingRemainder(dividingBy: 1)
        return remainder >= 0 ? remainder : remainder + 1
    }
}

#Preview {
    DynamicIslandTest()
}
