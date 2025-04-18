import SwiftUI

struct AppOnboardingView: View {
    @Binding var isOnboardingPresented: Bool
    
    var body: some View {
        TabView {
            // First page
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                
                Text("Welcome to Tip Easy")
                    .font(.largeTitle)
                    .bold()
                
                Text("Calculate tips quickly and easily")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(action: {
                    // Just move to next page
                }) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Second page
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "percent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Easy Tip Calculation")
                    .font(.largeTitle)
                    .bold()
                
                Text("Choose from presets or create custom tip percentages")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(action: {
                    // Just move to next page
                }) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Third page
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                
                Text("Track Your Expenses")
                    .font(.largeTitle)
                    .bold()
                
                Text("Save calculations with photos and view your history")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(action: {
                    isOnboardingPresented = false
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

// Add to the bottom of OnboardingView.swift
#Preview {
    AppOnboardingView(isOnboardingPresented: .constant(true))
}
