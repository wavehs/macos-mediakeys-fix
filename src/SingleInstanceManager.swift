import Cocoa

public final class SingleInstanceManager {
    public static let shared = SingleInstanceManager()
    
    private let lockPath = "/tmp/com.user.mediakeysfix.lock"
    private var lockFileDescriptor: Int32 = -1
    private let notificationName = NSNotification.Name("com.user.mediakeysfix.showWindow")
    
    private init() {}
    
    /// Tries to acquire the single-instance lock.
    /// Returns true if this is the primary instance.
    /// Returns false if another instance is already running (activates it and notifies to show window).
    public func acquireOrActivateExisting() -> Bool {
        let fd = open(lockPath, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else {
            return true // Fallback if error creating file
        }
        
        let result = flock(fd, LOCK_EX | LOCK_NB)
        if result == 0 {
            // Lock acquired! We are the only instance.
            lockFileDescriptor = fd
            
            // Record our PID
            let pidStr = "\(getpid())\n"
            ftruncate(fd, 0)
            lseek(fd, 0, SEEK_SET)
            _ = pidStr.withCString { write(fd, $0, strlen($0)) }
            
            // Listen for show-window requests from any future launch attempts
            setupNotificationListener()
            return true
        } else {
            // Another instance is already running!
            close(fd)
            
            // 1. Send inter-process notification to show window
            DistributedNotificationCenter.default().postNotificationName(
                notificationName,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            
            // 2. Bring existing application window to front
            if let pidData = try? String(contentsOfFile: lockPath, encoding: .utf8),
               let pid = Int32(pidData.trimmingCharacters(in: .whitespacesAndNewlines)),
               let runningApp = NSRunningApplication(processIdentifier: pid) {
                activateApp(runningApp)
            } else if let bundleID = Bundle.main.bundleIdentifier,
                      let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first(where: { $0.processIdentifier != getpid() }) {
                activateApp(runningApp)
            }
            
            return false
        }
    }
    
    private func activateApp(_ app: NSRunningApplication) {
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
    
    private func setupNotificationListener() {
        DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { _ in
            MainWindowController.shared.show()
        }
    }
}
