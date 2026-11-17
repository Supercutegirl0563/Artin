
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
                            GeometryReader { geometry in
                                let itemWidth = geometry.size.width / 3
                                let edgePadding = (geometry.size.width - itemWidth) / 2

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 0) {
                                        ForEach(BrushList, id: \.self) { brush in
                                            Text(brush)
                                                .fontWeight(selectedBrush == brush ? .bold : .regular)
                                                .foregroundStyle(selectedBrush == brush ? .yellow : .white.opacity(0.6))
                                                .frame(width: itemWidth)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    withAnimation {
                                                        selectedBrush = brush
                                                    }
                                                }
                                                .opacity(isExpanded ? 1 : 0)
                                                .disabled(!isExpanded)
                                        }
                                    }
                                    .scrollTargetLayout()
                                }
                                .contentMargins(.horizontal, edgePadding, for: .scrollContent)
                                .scrollTargetBehavior(.viewAligned)
                                .scrollPosition(id: $selectedBrush, anchor: .center)
                                .sensoryFeedback(.selection, trigger: selectedBrush) // Triggers on both drag and tap
                                .onAppear {
                                    DispatchQueue.main.async {
                                        selectedBrush = "Marker"
                                    }
                                }
                            }
                            .frame(height: 50)

                            
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

#Preview {
    DynamicIslandTest()
}
