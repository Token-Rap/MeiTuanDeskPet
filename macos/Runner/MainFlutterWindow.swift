import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = false
    self.styleMask.insert(.fullSizeContentView)
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = false
    self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    self.level = .floating

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
