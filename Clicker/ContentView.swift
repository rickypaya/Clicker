import SwiftUI
import Combine

// MARK: - Game Models

// Main game state that holds all data
class GameState: ObservableObject {
    @Published var coffees: Double = 0
    @Published var coffeesPerTap: Double = 1
    @Published var coffeesPerSecond: Double = 0
    @Published var globalMultiplier: Double = 1
    
    @Published var tapUpgrades: [TapUpgrade] = []
    @Published var idleUpgrades: [IdleUpgrade] = []
    @Published var multiplierUpgrades: [MultiplierUpgrade] = []
    
    private var idleTimer: Timer?
    
    init() {
        setupInitialUpgrades()
        startIdleProduction()
    }
    
    // Initialize default upgrades
    private func setupInitialUpgrades() {
        //tap upgrades increase amount per tap
        tapUpgrades = [
            TapUpgrade(id: 1, name: "Better Beans", baseCost: 20, powerIncrease: 1, owned: 0),
            TapUpgrade(id: 2, name: "Foam Art Skills", baseCost: 200, powerIncrease: 5, owned: 0),
            TapUpgrade(id: 3, name: "Signature Recipies", baseCost: 2000, powerIncrease: 25, owned: 0),
            TapUpgrade(id: 4, name: "Secret Ingredient", baseCost: 20000, powerIncrease: 100, owned: 0)
        ]
        
        //idle upgrades increase amount per second idle
        idleUpgrades = [
            IdleUpgrade(id: 1, name: "Hire Barista", baseCost: 50, coffeesPerSecond: 1, owned: 0),
            IdleUpgrade(id: 2, name: "Espresso Machine", baseCost: 500, coffeesPerSecond: 10, owned: 0),
            IdleUpgrade(id: 3, name: "Roasting Station", baseCost: 5000, coffeesPerSecond: 100, owned: 0),
            IdleUpgrade(id: 4, name: "Drive-Thru Window", baseCost: 50000, coffeesPerSecond: 1000, owned: 0),
            IdleUpgrade(id: 5, name: "Coffee Factory", baseCost: 500000, coffeesPerSecond: 10000, owned: 0)
        ]
        
        //multiplier upgrades multiply number of production per tap
        multiplierUpgrades = [
            MultiplierUpgrade(id: 1, name: "Happy Hour", baseCost: 5000, multiplier: 2.0, owned: 0),
            MultiplierUpgrade(id: 2, name: "Premium Beans", baseCost: 50000, multiplier: 5.0, owned: 0),
            MultiplierUpgrade(id: 3, name: "Franchise Model", baseCost: 500000, multiplier: 10.0, owned: 0),
            MultiplierUpgrade(id: 4, name: "Global Brand", baseCost: 5000000, multiplier: 50, owned: 0),
        ]
    }
    
    // Start idle coffee production
    private func startIdleProduction() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.addIdleCoffees()
        }
    }
    
    // Core game actions
    func tapCoffee() {
        let earnedCoffees = coffeesPerTap * globalMultiplier
        coffees += earnedCoffees
    }
    
    private func addIdleCoffees() {
        let earnedCoffees = coffeesPerSecond * globalMultiplier
        coffees += earnedCoffees
    }
    
    // Calculate current stats based on owned upgrades
    func updateStats() {
        coffeesPerTap = 1 + tapUpgrades.reduce(0) { $0 + (Double($1.owned) * $1.powerIncrease) }
        coffeesPerSecond = idleUpgrades.reduce(0) { $0 + (Double($1.owned) * $1.coffeesPerSecond) }
        globalMultiplier = 1 + multiplierUpgrades.reduce(0) { $0 + (Double($1.owned) * ($1.multiplier - 1)) }
    }
}

// MARK: - Upgrade Models

protocol Upgrade {
    var id: Int { get }
    var name: String { get }
    var baseCost: Double { get }
    var owned: Int { get set }
    var currentCost: Double { get }
}

struct TapUpgrade: Upgrade, Identifiable {
    let id: Int
    let name: String
    let baseCost: Double
    let powerIncrease: Double
    var owned: Int = 0
    
    var currentCost: Double {
        baseCost * pow(1.15, Double(owned))
    }
}

struct IdleUpgrade: Upgrade, Identifiable {
    let id: Int
    let name: String
    let baseCost: Double
    let coffeesPerSecond: Double
    var owned: Int = 0
    
    var currentCost: Double {
        baseCost * pow(1.15, Double(owned))
    }
}

struct MultiplierUpgrade: Upgrade, Identifiable {
    let id: Int
    let name: String
    let baseCost: Double
    let multiplier: Double
    var owned: Int = 0
    
    var currentCost: Double {
        baseCost * pow(1.2, Double(owned))
    }
}

// MARK: - Main Game View

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        TabView {
            // Main clicker screen
            MainGameView()
                .tabItem {
                    Image(systemName: "hand.tap")
                    Text("Tap")
                }
                .environmentObject(gameState)
            
            // Upgrades screen
            UpgradesView()
                .tabItem {
                    Image(systemName: "arrow.up.circle")
                    Text("Upgrades")
                }
                .environmentObject(gameState)
        }
    }
}

// MARK: - Main Game Screen

struct MainGameView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            Image("coffee-shop-main")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .opacity(0.5)
            
            VStack(spacing: 30) {
                // Stats display
                StatsView()
                
                Spacer()
                
                // Main tap button
                TapButton()
                
                Spacer()
                
                // Quick stats
                HStack(spacing: 20) {
                    StatCard(title: "Per Tap", value: String(format: "%.1f", gameState.coffeesPerTap * gameState.globalMultiplier))
                    StatCard(title: "Per Second", value: String(format: "%.1f", gameState.coffeesPerSecond * gameState.globalMultiplier))
                    StatCard(title: "Multiplier", value: String(format: "%.1fx", gameState.globalMultiplier))
                }
            }
            .padding()
            .onReceive(gameState.$coffees) { _ in
                gameState.updateStats()
            }
        }
        
    }
}

struct StatsView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        VStack {
            Text("Coffees Made:")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(formatNumber(gameState.coffees))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

struct TapButton: View {
    @EnvironmentObject var gameState: GameState
    @State private var isPressed = false
    
    var body: some View {
        Button(action: { gameState.tapCoffee() }) {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: isPressed ? 180 : 200, height: isPressed ? 180 : 200)
                .overlay(
                    Text("☕️")
                        .font(.system(size: 60))
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.orange.opacity(0.7))
        .cornerRadius(10)
    }
}

// MARK: - Upgrades View

struct UpgradesView: View {
    var body: some View {
        NavigationView {
            
            ZStack {
                Image("coffee-shop-upgrades")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.8)
                
                VStack {
                    TabView {
                        TapUpgradesView()
                            .tabItem { Text("Tap Power") }
                        
                        IdleUpgradesView()
                            .tabItem { Text("Auto Earn") }
                        
                        MultiplierUpgradesView()
                            .tabItem { Text("Multipliers") }
                    }
                    .tabViewStyle(PageTabViewStyle())
                }
                .padding()
            }
            .navigationTitle("Upgrades")
        }
    }
}

struct TapUpgradesView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        UpgradeListView(
            title: "Tap Upgrades",
            description: "Increase coffees earned per tap",
            upgrades: gameState.tapUpgrades.map { AnyUpgrade($0) },
            purchaseAction: { index in
                purchaseTapUpgrade(index: index)
            }
        )
    }
    
    private func purchaseTapUpgrade(index: Int) {
        let upgrade = gameState.tapUpgrades[index]
        if gameState.coffees >= upgrade.currentCost {
            gameState.coffees -= upgrade.currentCost
            gameState.tapUpgrades[index].owned += 1
        }
    }
}

struct IdleUpgradesView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        UpgradeListView(
            title: "Idle Upgrades",
            description: "Earn coffees automatically",
            upgrades: gameState.idleUpgrades.map { AnyUpgrade($0) },
            purchaseAction: { index in
                purchaseIdleUpgrade(index: index)
            }
        )
    }
    
    private func purchaseIdleUpgrade(index: Int) {
        let upgrade = gameState.idleUpgrades[index]
        if gameState.coffees >= upgrade.currentCost {
            gameState.coffees -= upgrade.currentCost
            gameState.idleUpgrades[index].owned += 1
        }
    }
}

struct MultiplierUpgradesView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        UpgradeListView(
            title: "Multiplier Upgrades",
            description: "Boost all coin production",
            upgrades: gameState.multiplierUpgrades.map { AnyUpgrade($0) },
            purchaseAction: { index in
                purchaseMultiplierUpgrade(index: index)
            }
        )
    }
    
    private func purchaseMultiplierUpgrade(index: Int) {
        let upgrade = gameState.multiplierUpgrades[index]
        if gameState.coffees >= upgrade.currentCost {
            gameState.coffees -= upgrade.currentCost
            gameState.multiplierUpgrades[index].owned += 1
        }
    }
}

// Type-erased wrapper for upgrades
struct AnyUpgrade {
    let id: Int
    let name: String
    let baseCost: Double
    let owned: Int
    let currentCost: Double
    
    init<T: Upgrade>(_ upgrade: T) {
        self.id = upgrade.id
        self.name = upgrade.name
        self.baseCost = upgrade.baseCost
        self.owned = upgrade.owned
        self.currentCost = upgrade.currentCost
    }
}

struct UpgradeListView: View {
    @EnvironmentObject var gameState: GameState
    let title: String
    let description: String
    let upgrades: [AnyUpgrade]
    let purchaseAction: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(upgrades.enumerated()), id: \.element.id) { index, upgrade in
                        UpgradeCard(
                            upgrade: upgrade,
                            canAfford: gameState.coffees >= upgrade.currentCost,
                            onPurchase: { purchaseAction(index) }
                        )
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

struct UpgradeCard: View {
    let upgrade: AnyUpgrade
    let canAfford: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(upgrade.name)
                    .font(.headline)
                
                Text("Owned: \(upgrade.owned)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onPurchase) {
                Text(formatNumber(upgrade.currentCost))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(canAfford ? .white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color.blue : Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
            .disabled(!canAfford)
        }
        .padding()
        .background(Color.orange.opacity(0.8))
        .cornerRadius(12)
    }
}

// MARK: - Utility Functions

func formatNumber(_ number: Double) -> String {
    if number >= 1_000_000_000 {
        return String(format: "%.2fB", number / 1_000_000_000)
    } else if number >= 1_000_000 {
        return String(format: "%.2fM", number / 1_000_000)
    } else if number >= 1_000 {
        return String(format: "%.2fK", number / 1_000)
    } else {
        return String(format: "%.0f", number)
    }
}

// MARK: - App Entry Point

@main
struct IdleClickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
