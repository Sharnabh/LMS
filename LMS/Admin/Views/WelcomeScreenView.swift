//
//  WelcomeScreenView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 01/04/25.
//

import SwiftUI

struct WelcomeScreenView: View {
    @State private var isShowingLogin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color("AccentColor")
                    .ignoresSafeArea()
                
                VStack {
                    // Wave shape
                    WaveShape()
                        .fill(Color.white)
                        .frame(height: UIScreen.main.bounds.height * 0.9)
                        .offset(y: UIScreen.main.bounds.height * 0.1)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    
                    Text("Welcome")
                        .font(.system(size: 40, weight: .bold))
                        .padding(.horizontal, 20)
                    
                    Text("A new way to explore the world of literature!")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        isShowingLogin = true
                    }) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
            .navigationDestination(isPresented: $isShowingLogin) {
                ContentView()
            }
        }
    }
}


#Preview {
    WelcomeScreenView()
}
