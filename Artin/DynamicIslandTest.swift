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
                    let height = rect.height + padding * 2 + (isExpanded ? 140 : 0)

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
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7),
                                value: isExpanded
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
