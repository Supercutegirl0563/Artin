
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
    
    @State private var BrushThickeness: Double = 45
    
    @State private var BrushOpacity: Double = 0.5
    
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
                    
                    let width = rect.width + padding * 2 + (isExpanded ? 100 : 0)
                    let height = rect.height + padding * 2 + (isExpanded ? 280 : 0)
                    
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
                            
                            // Brush thickness
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Thickness")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                    
                                    Slider(value: $BrushThickeness, in: 0...45)
                                        .tint(.yellow)
                                }
                                
                                CirclePreview(circleSize: BrushThickeness, circleOpacity: 1)
                            }
                            .padding(.horizontal, 12)
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
                                CirclePreview(circleSize: 20, circleOpacity: BrushOpacity)
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
            .onTapGesture(count: 3) {
                
                print("Clicked")
                
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
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(circleOpacity))
                    .frame(width: circleSize, height: circleSize)
            }
    }
}

#Preview {
    DynamicIslandTest()
}
