import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var textToSpeechHandler: NativeTextToSpeechHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "AudioGuidanceTextToSpeech"
    ) else { return }
    let channel = FlutterMethodChannel(
      name: "br.org.digitavox/audio_guidance_tts",
      binaryMessenger: registrar.messenger()
    )
    let handler = NativeTextToSpeechHandler()
    textToSpeechHandler = handler
    channel.setMethodCallHandler(handler.handle)
  }
}

private final class NativeTextToSpeechHandler: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  private var activeResult: FlutterResult?
  private var locale = "pt-BR"
  private var rateMultiplier: Float = 0.85
  private var pitch: Float = 1
  private var volume: Float = 1
  private var voiceIdentifier: String?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "tts_invalid_configuration", message: nil, details: nil))
        return
      }
      locale = arguments["locale"] as? String ?? "pt-BR"
      rateMultiplier = Float(arguments["rate"] as? Double ?? 0.85)
      pitch = Float(arguments["pitch"] as? Double ?? 1)
      volume = Float(arguments["volume"] as? Double ?? 1)
      voiceIdentifier = arguments["voice"] as? String
      result(nil)
    case "speak":
      guard
        let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(FlutterError(code: "tts_invalid_text", message: nil, details: nil))
        return
      }
      stopActiveSpeech()
      activeResult = result
      let utterance = AVSpeechUtterance(string: text)
      if let identifier = voiceIdentifier {
        utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
      } else {
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
      }
      utterance.rate = min(
        AVSpeechUtteranceMaximumSpeechRate,
        max(AVSpeechUtteranceMinimumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * rateMultiplier)
      )
      utterance.pitchMultiplier = min(2, max(0.5, pitch))
      utterance.volume = min(1, max(0, volume))
      synthesizer.speak(utterance)
    case "stop":
      stopActiveSpeech()
      result(nil)
    case "dispose":
      stopActiveSpeech()
      synthesizer.delegate = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    completeActiveSpeech()
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didCancel utterance: AVSpeechUtterance
  ) {
    completeActiveSpeech()
  }

  private func stopActiveSpeech() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    completeActiveSpeech()
  }

  private func completeActiveSpeech() {
    let result = activeResult
    activeResult = nil
    result?(nil)
  }
}
