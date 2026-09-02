import SwiftUI

@main
struct DotPrototypeApp: App {
    var body: some Scene {
        WindowGroup("dot") {
            AppRootView()
                .frame(width: 390, height: 844)
        }
        .defaultSize(width: 390, height: 844)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

enum ClockFormat: String, CaseIterable, Identifiable {
    case twelve = "12-hour"
    case twentyFour = "24-hour"

    var id: String { rawValue }

    func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = self == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}

enum DoseState: Equatable {
    case withinLimits
    case wait(hours: Int)
    case limitReached

    var title: String {
        switch self {
        case .withinLimits: "Within your limits"
        case let .wait(hours): "Wait \(hours) hr"
        case .limitReached: "Limit reached"
        }
    }

    var symbol: String {
        switch self {
        case .withinLimits: "checkmark.circle"
        case .wait: "clock"
        case .limitReached: "exclamationmark.triangle"
        }
    }
}

struct Medication: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var dose: String
    var maxInRolling24Hours: Int
    var minimumGapHours: Int
    var state: DoseState
    var lastTaken: String
}

enum HomeVariant: Int, CaseIterable {
    case focusDot
    case directAction
    case todayFirst

    var label: String {
        switch self {
        case .focusDot: "A · Focus dot"
        case .directAction: "B · Direct action"
        case .todayFirst: "C · Today first"
        }
    }
}

@MainActor
struct AppRootView: View {
    @State private var isLaunching = true
    @State private var selectedTab = 0
    @State private var clockFormat: ClockFormat = .twelve
    @State private var homeVariant: HomeVariant = .focusDot
    @State private var medications = [
        Medication(name: "Metformin", dose: "500 mg", maxInRolling24Hours: 2, minimumGapHours: 6, state: .withinLimits, lastTaken: "6 hr ago"),
        Medication(name: "Paracetamol", dose: "500 mg", maxInRolling24Hours: 4, minimumGapHours: 4, state: .wait(hours: 1), lastTaken: "3 hr ago"),
        Medication(name: "Ibuprofen", dose: "200 mg", maxInRolling24Hours: 4, minimumGapHours: 6, state: .limitReached, lastTaken: "4 of 4 in rolling 24 hr")
    ]

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            if isLaunching {
                LaunchAnimationView {
                    withAnimation(.easeOut(duration: 0.35)) {
                        isLaunching = false
                    }
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case 1:
                            StatusScreen(medications: $medications)
                        case 2:
                            SettingsScreen(clockFormat: $clockFormat)
                        default:
                            HomeScreen(
                                medications: $medications,
                                clockFormat: $clockFormat,
                                variant: $homeVariant,
                                openStatus: { selectedTab = 1 }
                            )
                        }
                    }
                    DotTabBar(selectedTab: $selectedTab)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(nil)
    }
}

struct LaunchAnimationView: View {
    let onFinished: () -> Void
    @State private var stage = 0

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            GeometryReader { proxy in
                ForEach(0..<34, id: \.self) { index in
                    Circle()
                        .fill(Color.primary)
                        .frame(width: CGFloat(2 + index % 4), height: CGFloat(2 + index % 4))
                        .opacity(stage == 2 ? 0 : (index % 3 == 0 ? 0.8 : 0.35))
                        .position(
                            x: stage == 0 ? CGFloat((index * 47) % 260) + 65 : proxy.size.width / 2 + CGFloat((index % 11) - 5) * 15,
                            y: stage == 0 ? CGFloat((index * 71) % 230) + 300 : proxy.size.height / 2 + CGFloat((index % 5) - 2) * 10
                        )
                        .animation(.easeInOut(duration: 0.8).delay(Double(index % 7) * 0.02), value: stage)
                }
            }
            VStack(spacing: 1) {
                Text("dot")
                    .font(.system(size: 80, weight: .black))
                    .tracking(-5)
                Text("by latte")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(1.2)
                    .opacity(stage == 2 ? 1 : 0)
            }
            .opacity(stage >= 1 ? 1 : 0)
            .scaleEffect(stage == 1 ? 0.94 : 1)
            .animation(.easeOut(duration: 0.55), value: stage)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("dot by latte")
        .task {
            try? await Task.sleep(for: .milliseconds(700))
            stage = 1
            try? await Task.sleep(for: .milliseconds(850))
            stage = 2
            try? await Task.sleep(for: .milliseconds(700))
            onFinished()
        }
    }
}

struct DotWordmark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text("dot")
                .font(.system(size: 29, weight: .black))
                .tracking(-1.5)
            Text("by latte")
                .font(.system(size: 9, weight: .medium))
                .tracking(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("dot by latte")
    }
}

struct ScreenHeader: View {
    let trailingSymbol: String?
    let trailingAction: (() -> Void)?

    var body: some View {
        HStack {
            DotWordmark()
            Spacer()
            if let trailingSymbol {
                Button(action: { trailingAction?() }) {
                    Image(systemName: trailingSymbol)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }
}

struct HomeScreen: View {
    @Binding var medications: [Medication]
    @Binding var clockFormat: ClockFormat
    @Binding var variant: HomeVariant
    let openStatus: () -> Void
    @State private var showingLogSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScreenHeader(trailingSymbol: "gearshape", trailingAction: nil)
                Text(clockFormat.string(from: Date()))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                Group {
                    switch variant {
                    case .focusDot:
                        FocusDotHome(showLog: { showingLogSheet = true })
                    case .directAction:
                        DirectActionHome(medications: medications, showLog: { showingLogSheet = true })
                    case .todayFirst:
                        TodayFirstHome(medications: medications, showLog: { showingLogSheet = true }, openStatus: openStatus)
                    }
                }
                .frame(maxHeight: .infinity)
            }
#if DEBUG
            PrototypeSwitcher(variant: $variant)
                .padding(.bottom, 12)
#endif
        }
        .sheet(isPresented: $showingLogSheet) {
            LogDoseSheet(medications: $medications, clockFormat: clockFormat)
                .frame(width: 390, height: 560)
        }
    }
}

struct FocusDotHome: View {
    let showLog: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Button(action: showLog) {
                ZStack {
                    Circle().fill(Color.primary).frame(width: 88, height: 88)
                    Circle().fill(Color(nsColor: .windowBackgroundColor)).frame(width: 14, height: 14)
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log a dose")
            Text("Log a dose")
                .font(.system(size: 17, weight: .semibold))
            Text("Dot checks only the limits you entered.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct DirectActionHome: View {
    let medications: [Medication]
    let showLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What do you need?")
                .font(.system(size: 34, weight: .bold))
            if let first = medications.first {
                Label("Last logged: \(first.name), \(first.lastTaken)", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: showLog) {
                Label("Log a dose", systemImage: "plus.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
}

struct TodayFirstHome: View {
    let medications: [Medication]
    let showLog: () -> Void
    let openStatus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today").font(.system(size: 34, weight: .bold))
                Spacer()
                Button("View all", action: openStatus).buttonStyle(.link)
            }
            ForEach(medications.prefix(2)) { medication in
                CompactMedicationRow(medication: medication)
            }
            Spacer()
            Button(action: showLog) {
                Label("Log a dose", systemImage: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
}

struct PrototypeSwitcher: View {
    @Binding var variant: HomeVariant

    var body: some View {
        HStack(spacing: 14) {
            Button(action: previous) { Image(systemName: "chevron.left") }
            Text(variant.label).font(.system(size: 12, weight: .semibold)).frame(width: 112)
            Button(action: next) { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(Color(nsColor: .windowBackgroundColor))
        .background(Color.primary, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Prototype layout switcher")
    }

    private func previous() {
        let count = HomeVariant.allCases.count
        variant = HomeVariant(rawValue: (variant.rawValue - 1 + count) % count) ?? .focusDot
    }

    private func next() {
        variant = HomeVariant(rawValue: (variant.rawValue + 1) % HomeVariant.allCases.count) ?? .focusDot
    }
}

struct LogDoseSheet: View {
    @Binding var medications: [Medication]
    let clockFormat: ClockFormat
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: Medication.ID?
    @State private var didLog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(.secondary.opacity(0.35)).frame(width: 36, height: 5).frame(maxWidth: .infinity)
            Text(didLog ? "Dose logged" : "Choose a medicine")
                .font(.system(size: 28, weight: .bold))
            if didLog {
                Label("Recorded at \(clockFormat.string(from: Date()))", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text("The status is based only on the limits you entered.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Spacer()
                PrimaryButton(title: "View status", symbol: "list.bullet") { dismiss() }
            } else {
                ForEach(medications) { medication in
                    Button(action: { selectedID = medication.id }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(medication.name).font(.system(size: 17, weight: .semibold))
                                Text(medication.dose).font(.system(size: 13)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedID == medication.id ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                        }
                        .padding(16)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                PrimaryButton(title: "Log dose now", symbol: "checkmark") { logDose() }
                    .disabled(selectedID == nil)
                    .opacity(selectedID == nil ? 0.35 : 1)
            }
        }
        .padding(20)
        .onAppear { selectedID = medications.first?.id }
    }

    private func logDose() {
        guard let selectedID, let index = medications.firstIndex(where: { $0.id == selectedID }) else { return }
        medications[index].lastTaken = "Just now"
        medications[index].state = .wait(hours: medications[index].minimumGapHours)
        withAnimation { didLog = true }
    }
}

struct StatusScreen: View {
    @Binding var medications: [Medication]
    @State private var showingAddMedication = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(trailingSymbol: nil, trailingAction: nil)
            VStack(alignment: .leading, spacing: 14) {
                Text("Status")
                    .font(.system(size: 34, weight: .bold))
                HStack(spacing: 16) {
                    ProfileCircle(initial: "M", name: "Me", selected: true)
                    ProfileCircle(initial: "S", name: "Son", selected: false)
                    ProfileCircle(initial: "+", name: "Add", selected: false)
                }
                Text("Rolling 24 hours")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                ForEach(medications) { medication in
                    MedicationStatusRow(medication: medication)
                }
                Button(action: { showingAddMedication = true }) {
                    Label("Add medication", systemImage: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5])))
                }
                .buttonStyle(.plain)
                Text("Dot checks only the limits you entered. It does not provide dosing advice.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            Spacer()
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationSheet(medications: $medications)
                .frame(width: 390, height: 680)
        }
    }
}

struct ProfileCircle: View {
    let initial: String
    let name: String
    let selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(initial)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 52, height: 52)
                .foregroundStyle(selected ? Color(nsColor: .windowBackgroundColor) : .primary)
                .background(selected ? Color.primary : Color.primary.opacity(0.06), in: Circle())
                .overlay(Circle().stroke(Color.primary.opacity(selected ? 0 : 0.25), lineWidth: 1))
            Text(name).font(.system(size: 13, weight: selected ? .semibold : .regular))
        }
    }
}

struct MedicationStatusRow: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: medication.state.symbol)
                .font(.system(size: 21, weight: .medium))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(medication.name) \(medication.dose)")
                    .font(.system(size: 16, weight: .semibold))
                Text(medication.lastTaken)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(medication.state.title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.primary.opacity(0.07), in: Capsule())
        }
        .padding(14)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.16)))
        .accessibilityElement(children: .combine)
    }
}

struct CompactMedicationRow: View {
    let medication: Medication

    var body: some View {
        HStack {
            Image(systemName: medication.state.symbol).frame(width: 24)
            Text(medication.name).font(.system(size: 16, weight: .semibold))
            Spacer()
            Text(medication.state.title).font(.system(size: 13, weight: .medium))
        }
        .padding(14)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AddMedicationSheet: View {
    @Binding var medications: [Medication]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dose = ""
    @State private var unit = "mg"
    @State private var maxIn24Hours = 4
    @State private var minimumGap = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Cancel", action: { dismiss() }).buttonStyle(.plain)
                Spacer()
                Text("Add medication").font(.system(size: 20, weight: .bold))
                Spacer()
                Color.clear.frame(width: 48, height: 1)
            }
            Text("Use the pharmacist label or packet. Dot checks only the limits you enter here.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Dose amount", text: $dose).textFieldStyle(.roundedBorder)
                    Picker("Unit", selection: $unit) {
                        Text("mg").tag("mg")
                        Text("ml").tag("ml")
                        Text("tab").tag("tab")
                    }
                    .pickerStyle(.segmented)
                }
                Stepper("Maximum doses in rolling 24 hours: \(maxIn24Hours)", value: $maxIn24Hours, in: 1...24)
                Stepper("Minimum gap: \(minimumGap) hours", value: $minimumGap, in: 1...24)
            }
            .padding(16)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
            Spacer()
            PrimaryButton(title: "Save medication", symbol: "checkmark") { save() }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || dose.isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty || dose.isEmpty ? 0.35 : 1)
        }
        .padding(20)
    }

    private func save() {
        medications.append(
            Medication(
                name: name,
                dose: "\(dose) \(unit)",
                maxInRolling24Hours: maxIn24Hours,
                minimumGapHours: minimumGap,
                state: .withinLimits,
                lastTaken: "Not logged yet"
            )
        )
        dismiss()
    }
}

struct SettingsScreen: View {
    @Binding var clockFormat: ClockFormat
    @State private var reduceMotion = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(trailingSymbol: nil, trailingAction: nil)
            VStack(alignment: .leading, spacing: 18) {
                Text("Settings").font(.system(size: 34, weight: .bold))
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Time format").font(.system(size: 17, weight: .semibold))
                        Picker("Time format", selection: $clockFormat) {
                            ForEach(ClockFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    Divider()
                    SettingsRow(symbol: "circle.lefthalf.filled", title: "Appearance", value: "System · monochrome")
                    Divider()
                    Toggle(isOn: $reduceMotion) {
                        Label("Reduce motion", systemImage: "figure.walk.motion")
                    }
                    .toggleStyle(.switch)
                    .padding(16)
                }
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.18)))
                Text("Status always uses symbols and words as well as shape. Text size and VoiceOver follow your system settings.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            Spacer()
        }
    }
}

struct SettingsRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .font(.system(size: 15))
        .padding(16)
    }
}

struct PrimaryButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                .background(Color.primary, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct DotTabBar: View {
    @Binding var selectedTab: Int
    private let items = [
        ("Home", "circle"),
        ("Status", "checkmark.circle"),
        ("Settings", "gearshape")
    ]

    var body: some View {
        HStack {
            ForEach(items.indices, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Image(systemName: items[index].1).font(.system(size: 20, weight: .medium))
                        Text(items[index].0).font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundStyle(selectedTab == index ? Color.primary : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(items[index].0)
                .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}
