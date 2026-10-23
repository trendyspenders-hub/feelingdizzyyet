import AppKit
import Foundation

let fm = FileManager.default
struct InstallFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
func installPanel(source: URL, destination: URL, injectFailure: Bool = false) throws -> URL {
    let names = ["Feeling Dizzy Yet.jsx", "FeelingDizzyYet"]
    for name in names {
        guard fm.fileExists(atPath: source.appendingPathComponent(name).path) else {
            throw InstallFailure(message: "Installer payload is incomplete. Download the full DMG again.")
        }
    }
    try fm.createDirectory(at: destination, withIntermediateDirectories: true)
    let stamp = UUID().uuidString
    let stage = destination.appendingPathComponent(".fdy-stage-" + stamp)
    let backup = destination.appendingPathComponent("FeelingDizzyYet.backup-" + stamp)
    try fm.createDirectory(at: stage, withIntermediateDirectories: false)
    defer { try? fm.removeItem(at: stage) }
    // Copy everything before changing the previous installation.
    for name in names { try fm.copyItem(at: source.appendingPathComponent(name), to: stage.appendingPathComponent(name)) }
    try fm.createDirectory(at: backup, withIntermediateDirectories: false)
    var saved: [String] = [], placed: [String] = []
    do {
        for name in names {
            let target = destination.appendingPathComponent(name)
            if fm.fileExists(atPath: target.path) {
                try fm.moveItem(at: target, to: backup.appendingPathComponent(name)); saved.append(name)
            }
        }
        for name in names {
            try fm.moveItem(at: stage.appendingPathComponent(name), to: destination.appendingPathComponent(name)); placed.append(name)
            if injectFailure { throw InstallFailure(message: "Injected rollback test") }
        }
        return backup
    } catch {
        var rollbackFailed = false
        for name in placed { do { try fm.removeItem(at: destination.appendingPathComponent(name)) } catch { rollbackFailed = true } }
        for name in saved { do { try fm.moveItem(at: backup.appendingPathComponent(name), to: destination.appendingPathComponent(name)) } catch { rollbackFailed = true } }
        let detail = rollbackFailed ? "Rollback was incomplete. Restore your files from: \(backup.path)" : "Previous matching panel files were restored."
        throw InstallFailure(message: "Installation stopped: \(error.localizedDescription)\n\n\(detail)")
    }
}
func selfTest() throws {
    let root = fm.temporaryDirectory.appendingPathComponent("FDY-test-" + UUID().uuidString)
    defer { try? fm.removeItem(at: root) }
    let source = root.appendingPathComponent("source"), dest = root.appendingPathComponent("destination")
    for (dir, value) in [(source, "NEW"), (dest, "OLD")] {
        try fm.createDirectory(at: dir.appendingPathComponent("FeelingDizzyYet"), withIntermediateDirectories: true)
        try value.write(to: dir.appendingPathComponent("Feeling Dizzy Yet.jsx"), atomically: true, encoding: .utf8)
        try value.write(to: dir.appendingPathComponent("FeelingDizzyYet/marker"), atomically: true, encoding: .utf8)
    }
    do { _ = try installPanel(source: source, destination: dest, injectFailure: true); throw InstallFailure(message: "Rollback injection did not fail") }
    catch { guard try String(contentsOf: dest.appendingPathComponent("Feeling Dizzy Yet.jsx"), encoding: .utf8) == "OLD" else { throw InstallFailure(message: "Rollback lost the previous panel") } }
    guard try String(contentsOf: dest.appendingPathComponent("FeelingDizzyYet/marker"), encoding: .utf8) == "OLD" else { throw InstallFailure(message: "Rollback lost the companion") }
    _ = try installPanel(source: source, destination: dest)
    guard try String(contentsOf: dest.appendingPathComponent("Feeling Dizzy Yet.jsx"), encoding: .utf8) == "NEW" else { throw InstallFailure(message: "Install test failed") }
    print("PASS native installer staged-copy and injected-failure rollback tests")
}
func message(_ title: String, _ body: String) {
    let a = NSAlert(); a.messageText = title; a.informativeText = body
    if let icon = Bundle.main.url(forResource: "FeelingDizzyYet", withExtension: "icns") { a.icon = NSImage(contentsOf: icon) }
    a.addButton(withTitle: "OK"); a.runModal()
}
func runInstaller() throws {
    let prefs = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Preferences/Adobe/After Effects")
    let versions = (try? fm.contentsOfDirectory(at: prefs, includingPropertiesForKeys: [.isDirectoryKey]))?.filter {
        $0.lastPathComponent.range(of: "^[0-9]+\\.[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil && (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }.sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending } ?? []
    guard !versions.isEmpty else { message("Open After Effects once", "Open and close After Effects, then run this installer again. No existing preferences version was found for this Mac user. Manual-install files are also included in the DMG."); return }
    let choice = NSAlert(); choice.messageText = "FEELING DIZZY YET"
    choice.informativeText = "Install the After Effects panel and 102 tools for this Mac user. Close After Effects first. Matching existing files will be moved to a dated backup. Premiere is installed separately by opening the CCX in this DMG."
    let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 350, height: 30)); picker.addItems(withTitles: versions.map { "After Effects " + $0.lastPathComponent }); choice.accessoryView = picker
    if let icon = Bundle.main.url(forResource: "FeelingDizzyYet", withExtension: "icns") { choice.icon = NSImage(contentsOf: icon) }
    choice.addButton(withTitle: "Install After Effects"); choice.addButton(withTitle: "Cancel")
    guard choice.runModal() == .alertFirstButtonReturn else { return }
    guard let resources = Bundle.main.resourceURL else { throw InstallFailure(message: "App resources missing") }
    let target = versions[picker.indexOfSelectedItem].appendingPathComponent("Scripts/ScriptUI Panels")
    let backup = try installPanel(source: resources.appendingPathComponent("After Effects"), destination: target)
    message("Installation complete", "Restart After Effects, then open Window > Feeling Dizzy Yet.\n\nInstalled in:\n\(target.path)\n\nPrevious matching files, if present, are retained in:\n\(backup.path)\n\nThis copy/rollback test does not verify Adobe editing or rendering.")
}
if CommandLine.arguments.contains("--self-test") {
    do { try selfTest() } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
} else {
    let app = NSApplication.shared; app.setActivationPolicy(.regular); app.activate(ignoringOtherApps: true)
    do { try runInstaller() } catch { message("Could not install", error.localizedDescription) }
}
