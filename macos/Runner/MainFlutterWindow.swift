import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = NSColor.clear
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = false
    self.contentView?.wantsLayer = true
    self.contentView?.layer?.isOpaque = false
    self.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    self.styleMask.insert(.fullSizeContentView)
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = false
    self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    self.level = .floating

    RegisterGeneratedPlugins(registry: flutterViewController)

    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.isOpaque = false
    flutterViewController.view.layer?.backgroundColor = NSColor.clear.cgColor

    super.awakeFromNib()
  }
}
