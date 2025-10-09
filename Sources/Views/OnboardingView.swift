import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var calendarManager: CalendarManager
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    let totalPages = 5
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.35),
                    Color(red: 0.1, green: 0.05, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: finishOnboarding) {
                        Text("Skip")
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                Spacer()
                
                // Page content - Manual page switching for macOS
                Group {
                    if currentPage == 0 {
                        WelcomePage()
                    } else if currentPage == 1 {
                        FeaturePage(
                            icon: "timer.circle.fill",
                            title: "Focus Sessions",
                            description: "Stay productive with timed work sessions and automatic breaks",
                            features: [
                                "Customizable work/break durations",
                                "Floating timer display",
                                "Keyboard shortcuts for quick control"
                            ]
                        )
                    } else if currentPage == 2 {
                        FeaturePage(
                            icon: "calendar.badge.clock",
                            title: "Calendar Integration",
                            description: "Smart scheduling around your meetings",
                            features: [
                                "See upcoming meetings",
                                "Auto-pause for meetings",
                                "Find optimal focus time slots"
                            ],
                            action: {
                                if !calendarManager.hasAccess {
                                    calendarManager.requestCalendarAccess()
                                }
                            },
                            actionLabel: calendarManager.hasAccess ? "Calendar Connected ✓" : "Connect Calendar"
                        )
                    } else if currentPage == 3 {
                        SettingsPage(settings: settings)
                    } else if currentPage == 4 {
                        FinalPage(onGetStarted: finishOnboarding)
                    }
                }
                .frame(maxHeight: 600)
                .transition(.opacity)
                
                Spacer()
                
                // Page indicator and navigation
                VStack(spacing: 20) {
                    // Custom page dots
                    HStack(spacing: 12) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: { withAnimation { currentPage -= 1 } }) {
                                Text("Back")
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < totalPages - 1 {
                                withAnimation { currentPage += 1 }
                            } else {
                                finishOnboarding()
                            }
                        }) {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                                .fontWeight(.semibold)
                                .frame(width: 120)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: 400)
                }
                .padding(.bottom, 30)
            }
        }
        .frame(width: 600, height: 700)
    }
    
    private func finishOnboarding() {
        print("🎉 OnboardingView: finishOnboarding called")
        UserDefaults.app.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.app.set(Date(), forKey: "onboardingCompletedDate")
        
        print("🎉 OnboardingView: Setting isPresented to false")
        // Use DispatchQueue to ensure binding fires properly
        DispatchQueue.main.async {
            self.isPresented = false
            print("🎉 OnboardingView: isPresented set to false")
        }
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            // App icon or logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Welcome to Focusly")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Your productivity companion")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Text("Take control of your focus time with smart breaks,\ncalendar integration, and beautiful design.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 40)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Feature Page

struct FeaturePage: View {
    let icon: String
    let title: String
    let description: String
    let features: [String]
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(feature)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(.top, 20)
            
            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .fontWeight(.medium)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Settings Page

struct SettingsPage: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("Customize Your Experience")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Set your preferences for optimal productivity")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Scrollable settings to prevent clipping
            ScrollView {
                VStack(spacing: 12) {
                    // All items same width for consistency
                    Toggle(isOn: $settings.showTimeDisplay) {
                        HStack(spacing: 12) {
                            Image(systemName: "eye.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Floating Timer Display")
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer()
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .frame(height: 48)
                    
                    Toggle(isOn: $settings.breakNotifications) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Break Notifications")
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer()
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .frame(height: 48)
                    
                    // Launch at Login - User Consent
                    Toggle(isOn: $settings.launchAtLogin) {
                        HStack(spacing: 12) {
                            Image(systemName: "power")
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Launch at Login")
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                if settings.launchAtLogin {
                                    Text("May require approval in System Settings")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            Spacer()
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .frame(minHeight: 48)
                }
                .frame(maxWidth: 400)
            }
            .frame(maxHeight: 300)
            
            VStack(spacing: 8) {
                Text("Default: 50 min focus, 10 min break")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                
                Text("Customize durations in Settings after setup")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }
}

struct QuickSettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Text(value)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Final Page

struct FinalPage: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Ready to boost your productivity")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 20) {
                TipRow(
                    icon: "command",
                    text: "Use ⌘⌥T to start/stop timer anytime"
                )
                
                TipRow(
                    icon: "menubar.rectangle",
                    text: "Access Focusly from the menu bar"
                )
                
                TipRow(
                    icon: "gearshape",
                    text: "Customize anytime in Settings"
                )
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

