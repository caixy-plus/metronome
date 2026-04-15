import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // 设置固定窗口大小 - 手机比例 (400x700)
    let windowSize = NSSize(width: 400, height: 800)
    let windowFrame = NSRect(
      x: self.frame.origin.x,
      y: self.frame.origin.y,
      width: windowSize.width,
      height: windowSize.height
    )
    self.setFrame(windowFrame, display: true)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // 禁止调节窗口大小
    self.minSize = windowSize
    self.maxSize = windowSize
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.backgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
