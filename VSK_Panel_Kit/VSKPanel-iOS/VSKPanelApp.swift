import SwiftUI
import Combine
import UIKit

@main
struct VSKPanelApp: App {
    var body: some Scene {
        WindowGroup { RootView().preferredColorScheme(.dark) }
    }
}

struct PanelSettings: Codable {
    var sensitivity = 50.0
    var scopeSensitivity = 45.0
    var reticleSize = 18.0
    var reticleThickness = 2.0
    var reticleGap = 5.0
    var reticleColorHex = "#B56CFF"
    var showCenterDot = true
    var showCrosshair = true
}

@MainActor
final class PanelStore: ObservableObject {
    @Published var settings: PanelSettings { didSet { saveSettings() } }
    @Published var profiles: [String: PanelSettings] { didSet { saveProfiles() } }
    private let settingsKey = "vsk.settings.v1"
    private let profilesKey = "vsk.profiles.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(PanelSettings.self, from: data) {
            settings = decoded
        } else { settings = PanelSettings() }
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([String: PanelSettings].self, from: data) {
            profiles = decoded
        } else { profiles = [:] }
    }
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: settingsKey) }
    }
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) { UserDefaults.standard.set(data, forKey: profilesKey) }
    }
    func saveProfile(_ raw: String) -> Bool {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 32 else { return false }
        profiles[name] = settings
        return true
    }
    func loadProfile(_ name: String) { if let value = profiles[name] { settings = value } }
    func deleteProfile(_ name: String) { profiles.removeValue(forKey: name) }
    func reset() { settings = PanelSettings() }
}

struct RootView: View {
    @AppStorage("vsk.loggedIn.v1") private var loggedIn = false
    @AppStorage("vsk.username.v1") private var username = ""
    @StateObject private var store = PanelStore()
    var body: some View {
        Group {
            if loggedIn {
                MainView(store: store, username: username) { loggedIn = false }
            } else {
                LoginView { name in username = name; loggedIn = true }
            }
        }
        .tint(Color(hex: "#B56CFF"))
    }
}

struct LoginView: View {
    var onLogin: (String) -> Void
    @State private var username = ""
    @State private var password = ""
    @State private var error = ""
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "scope").font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color(hex: "#D8B4FE"))
                    .frame(width: 94, height: 94).background(Color(hex: "#2B1740"), in: RoundedRectangle(cornerRadius: 24))
                Text("VSK PANEL").font(.system(size: 30, weight: .black, design: .rounded))
                Text("SEU PAINEL, SUAS CONFIGURAÇÕES").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.55))
                VStack(spacing: 12) {
                    TextField("Nome de usuário", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().panelField()
                    SecureField("Senha (mínimo 6 caracteres)", text: $password).panelField()
                    if !error.isEmpty { Text(error).font(.footnote).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading) }
                    Button("ENTRAR") {
                        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard name.count >= 3 else { error = "O usuário precisa ter 3 caracteres."; return }
                        guard password.count >= 6 else { error = "A senha precisa ter 6 caracteres."; return }
                        onLogin(name)
                    }.buttonStyle(NeonButtonStyle())
                }.padding(.horizontal, 24)
                Text("Acesso local neste dispositivo. Não há conta online.")
                    .font(.caption2).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center)
                Spacer()
            }.padding()
        }
    }
}

struct MainView: View {
    @ObservedObject var store: PanelStore
    let username: String
    let onLogout: () -> Void
    var body: some View {
        ZStack {
            BackgroundView()
            TabView {
                DashboardView(store: store, username: username).tabItem { Label("Início", systemImage: "square.grid.2x2.fill") }
                SettingsView(store: store).tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }
                ReticleView(store: store).tabItem { Label("Mira", systemImage: "scope") }
                ProfilesView(store: store).tabItem { Label("Perfis", systemImage: "person.crop.rectangle.stack") }
            }
            .toolbarBackground(Color(hex: "#100B17"), for: .tabBar).toolbarBackground(.visible, for: .tabBar)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VSK PANEL").font(.system(size: 15, weight: .black, design: .rounded))
                    Text("Olá, \(username)").font(.caption).foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Button(action: onLogout) { Image(systemName: "rectangle.portrait.and.arrow.right").padding(10).background(.white.opacity(0.08), in: Circle()) }
                .accessibilityLabel("Sair")
            }.padding(.horizontal, 18).padding(.vertical, 10).background(Color(hex: "#100B17"))
        }
    }
}

struct DashboardView: View {
    @ObservedObject var store: PanelStore
    let username: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PAINEL DE CONTROLE").font(.caption.weight(.bold)).foregroundStyle(Color(hex: "#D8B4FE"))
                    Text("Tudo pronto, \(username).").font(.system(size: 27, weight: .black, design: .rounded))
                    Text("Ajuste preferências e salve seus perfis neste iPhone.").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }.panelCard()
                HStack(spacing: 12) {
                    MetricCard(title: "Sensibilidade", value: "\(Int(store.settings.sensitivity))", icon: "hand.draw")
                    MetricCard(title: "Tamanho da mira", value: "\(Int(store.settings.reticleSize))", icon: "scope")
                }
                VStack(alignment: .leading, spacing: 15) {
                    Text("SEU PAINEL").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.55))
                    NavigationActionRow(icon: "slider.horizontal.3", title: "Sensibilidade", subtitle: "Valores salvos automaticamente")
                    NavigationActionRow(icon: "scope", title: "Personalizar mira", subtitle: "Cor, tamanho e formato")
                    NavigationActionRow(icon: "person.crop.rectangle.stack", title: "Perfis salvos", subtitle: "\(store.profiles.count) perfil(is)")
                }.panelCard()
                Text("As opções ficam no app e não alteram diretamente o jogo.").font(.caption2).foregroundStyle(.white.opacity(0.42))
            }.padding(16)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: PanelStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("AJUSTES").font(.system(size: 25, weight: .black, design: .rounded))
                VStack(spacing: 22) {
                    ValueSlider(title: "Sensibilidade geral", value: $store.settings.sensitivity, range: 0...100)
                    ValueSlider(title: "Sensibilidade da mira", value: $store.settings.scopeSensitivity, range: 0...100)
                    Divider().overlay(.white.opacity(0.12))
                    Toggle("Exibir linhas da mira", isOn: $store.settings.showCrosshair)
                    Toggle("Exibir ponto central", isOn: $store.settings.showCenterDot)
                }.panelCard()
                Button(role: .destructive) { store.reset() } label: { Text("Restaurar configurações padrão") }.buttonStyle(.bordered)
            }.padding(16)
        }
    }
}

struct ReticleView: View {
    @ObservedObject var store: PanelStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("PERSONALIZAR MIRA").font(.system(size: 23, weight: .black, design: .rounded))
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(Color(hex: "#171020"))
                    GridPattern().stroke(.white.opacity(0.05), lineWidth: 1)
                    ReticleShape(settings: store.settings)
                        .stroke(Color(hex: store.settings.reticleColorHex), style: StrokeStyle(lineWidth: store.settings.reticleThickness, lineCap: .round))
                        .frame(width: 180, height: 180)
                    if store.settings.showCenterDot {
                        Circle().fill(Color(hex: store.settings.reticleColorHex)).frame(width: 5, height: 5)
                    }
                }.frame(height: 260).clipShape(RoundedRectangle(cornerRadius: 24))
                VStack(spacing: 20) {
                    ValueSlider(title: "Tamanho", value: $store.settings.reticleSize, range: 8...42)
                    ValueSlider(title: "Espessura", value: $store.settings.reticleThickness, range: 1...6)
                    ValueSlider(title: "Espaçamento", value: $store.settings.reticleGap, range: 0...14)
                    HStack {
                        Text("Cor da mira").font(.subheadline.weight(.semibold))
                        Spacer()
                        ColorPicker("Escolher cor", selection: Binding(
                            get: { Color(hex: store.settings.reticleColorHex) },
                            set: { store.settings.reticleColorHex = $0.toHex() }
                        ), supportsOpacity: false).labelsHidden()
                    }
                    Toggle("Exibir linhas", isOn: $store.settings.showCrosshair)
                    Toggle("Ponto central", isOn: $store.settings.showCenterDot)
                }.panelCard()
                Text("A mira é exibida dentro desta tela.").font(.caption).foregroundStyle(.white.opacity(0.45))
            }.padding(16)
        }
    }
}

struct ProfilesView: View {
    @ObservedObject var store: PanelStore
    @State private var name = ""
    @State private var message = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("PERFIS").font(.system(size: 25, weight: .black, design: .rounded))
                VStack(spacing: 12) {
                    TextField("Nome do novo perfil", text: $name).textInputAutocapitalization(.words).panelField()
                    Button("Salvar configurações atuais") {
                        if store.saveProfile(name) { message = "Perfil salvo."; name = "" }
                        else { message = "Informe um nome com até 32 caracteres." }
                    }.buttonStyle(NeonButtonStyle())
                    if !message.isEmpty { Text(message).font(.caption).foregroundStyle(Color(hex: "#D8B4FE")) }
                }.panelCard()
                if store.profiles.isEmpty {
                    Text("Nenhum perfil salvo ainda.").foregroundStyle(.white.opacity(0.55))
                } else {
                    ForEach(store.profiles.keys.sorted(), id: \.self) { profileName in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profileName).font(.headline)
                                Text("Sensibilidade \(Int(store.profiles[profileName]?.sensitivity ?? 0)) • Mira \(Int(store.profiles[profileName]?.reticleSize ?? 0))")
                                    .font(.caption).foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            Button { store.loadProfile(profileName); message = "Perfil carregado." } label: { Image(systemName: "arrow.down.to.line").padding(8) }
                            Button(role: .destructive) { store.deleteProfile(profileName) } label: { Image(systemName: "trash").padding(8) }
                        }.panelCard()
                    }
                }
            }.padding(16)
        }
    }
}

struct ValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(value))").font(.system(.subheadline, design: .monospaced).weight(.bold)).foregroundStyle(Color(hex: "#D8B4FE"))
            }
            Slider(value: $value, in: range, step: 1)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color(hex: "#D8B4FE"))
            Text(value).font(.system(size: 28, weight: .black, design: .rounded))
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.55))
        }.frame(maxWidth: .infinity, alignment: .leading).panelCard()
    }
}

struct NavigationActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color(hex: "#D8B4FE")).frame(width: 34, height: 34)
                .background(Color(hex: "#2B1740"), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.35))
        }
    }
}

struct BackgroundView: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: "#0B0810"), Color(hex: "#170D22"), Color(hex: "#0B0810")], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }
}

struct ReticleShape: Shape {
    var settings: PanelSettings
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard settings.showCrosshair else { return path }
        let c = CGPoint(x: rect.midX, y: rect.midY), s = settings.reticleSize, g = settings.reticleGap
        path.move(to: CGPoint(x: c.x-g-s, y: c.y)); path.addLine(to: CGPoint(x: c.x-g, y: c.y))
        path.move(to: CGPoint(x: c.x+g, y: c.y)); path.addLine(to: CGPoint(x: c.x+g+s, y: c.y))
        path.move(to: CGPoint(x: c.x, y: c.y-g-s)); path.addLine(to: CGPoint(x: c.x, y: c.y-g))
        path.move(to: CGPoint(x: c.x, y: c.y+g)); path.addLine(to: CGPoint(x: c.x, y: c.y+g+s))
        return path
    }
}
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        stride(from: 0.0, through: rect.width, by: 24).forEach { x in p.move(to: CGPoint(x:x,y:0)); p.addLine(to: CGPoint(x:x,y:rect.height)) }
        stride(from: 0.0, through: rect.height, by: 24).forEach { y in p.move(to: CGPoint(x:0,y:y)); p.addLine(to: CGPoint(x:rect.width,y:y)) }
        return p
    }
}
struct NeonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14, weight: .black, design: .rounded).bold())
            .frame(maxWidth: .infinity).padding(.vertical, 16).foregroundStyle(.white)
            .background(configuration.isPressed ? Color(hex: "#7137A3") : Color(hex: "#7E3DB4"), in: RoundedRectangle(cornerRadius: 14))
    }
}
extension View {
    func panelCard() -> some View {
        padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    func panelField() -> some View {
        padding(14).background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        if clean.count == 6 {
            self.init(.sRGB, red: Double((value >> 16) & 255)/255, green: Double((value >> 8) & 255)/255, blue: Double(value & 255)/255, opacity: 1)
        } else { self.init(red: 0.71, green: 0.42, blue: 1) }
    }
    func toHex() -> String {
        let c = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}
