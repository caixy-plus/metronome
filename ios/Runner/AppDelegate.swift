import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var liveActivityHandler: LiveActivityHandlerProtocol?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // 设置 Dynamic Island MethodChannel
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.metronome/dynamic_island",
            binaryMessenger: controller.binaryMessenger
        )

        liveActivityHandler = createLiveActivityHandler()

        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "startLiveActivity":
                if let args = call.arguments as? [String: Any],
                   let bpm = args["bpm"] as? Int,
                   let beatsPerMeasure = args["beatsPerMeasure"] as? Int {
                    self.liveActivityHandler?.startActivity(bpm: bpm, beatsPerMeasure: beatsPerMeasure)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }

            case "updateLiveActivity":
                if let args = call.arguments as? [String: Any],
                   let currentBeat = args["currentBeat"] as? Int,
                   let beatsPerMeasure = args["beatsPerMeasure"] as? Int,
                   let isPlaying = args["isPlaying"] as? Bool {
                    self.liveActivityHandler?.updateActivity(
                        currentBeat: currentBeat,
                        beatsPerMeasure: beatsPerMeasure,
                        isPlaying: isPlaying
                    )
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }

            case "endLiveActivity":
                self.liveActivityHandler?.endActivity()
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

// MARK: - Live Activity Handler Protocol
protocol LiveActivityHandlerProtocol {
    func startActivity(bpm: Int, beatsPerMeasure: Int)
    func updateActivity(currentBeat: Int, beatsPerMeasure: Int, isPlaying: Bool)
    func endActivity()
}

// MARK: - Live Activity Attributes
struct MetronomeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentBeat: Int
        var beatsPerMeasure: Int
        var isPlaying: Bool
    }

    var bpm: Int
}

// MARK: - iOS 16.2+ Live Activity Handler
@available(iOS 16.2, *)
class LiveActivityHandler: LiveActivityHandlerProtocol {
    private var currentActivity: Activity<MetronomeActivityAttributes>?

    func startActivity(bpm: Int, beatsPerMeasure: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        endActivity()

        let attributes = MetronomeActivityAttributes(bpm: bpm)
        let initialState = MetronomeActivityAttributes.ContentState(
            currentBeat: 0,
            beatsPerMeasure: beatsPerMeasure,
            isPlaying: true
        )

        do {
            let activity = try Activity<MetronomeActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(currentBeat: Int, beatsPerMeasure: Int, isPlaying: Bool) {
        guard let activity = currentActivity else { return }

        let updatedState = MetronomeActivityAttributes.ContentState(
            currentBeat: currentBeat,
            beatsPerMeasure: beatsPerMeasure,
            isPlaying: isPlaying
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }

        let finalState = MetronomeActivityAttributes.ContentState(
            currentBeat: -1,
            beatsPerMeasure: 4,
            isPlaying: false
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        currentActivity = nil
    }
}

// MARK: - Fallback Handler for older iOS versions
class LiveActivityHandlerFallback: LiveActivityHandlerProtocol {
    func startActivity(bpm: Int, beatsPerMeasure: Int) {
        print("Live Activities require iOS 16.2 or newer")
    }

    func updateActivity(currentBeat: Int, beatsPerMeasure: Int, isPlaying: Bool) {
        // No-op
    }

    func endActivity() {
        // No-op
    }
}

// MARK: - Factory function to create appropriate handler
func createLiveActivityHandler() -> LiveActivityHandlerProtocol {
    if #available(iOS 16.2, *) {
        return LiveActivityHandler()
    } else {
        return LiveActivityHandlerFallback()
    }
}
