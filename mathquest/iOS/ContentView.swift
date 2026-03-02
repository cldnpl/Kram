import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            NavigationStack {
                CameraView()
            }
            .tabItem { Label("Camera", systemImage: "camera.fill") }
            .tag(1)
            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
