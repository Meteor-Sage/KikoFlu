import Flutter
import UIKit
import AVKit
import CoreImage
import CFNetwork
import AudioToolbox
import CoreHaptics

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var floatingLyricManager: FloatingLyricManager?
  private var audioHapticsBridge: AudioHapticsBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    floatingLyricManager = FloatingLyricManager(controller: controller)
    audioHapticsBridge = AudioHapticsBridge(controller: controller)

    let screenAwakeChannel = FlutterMethodChannel(
      name: "com.meteor.kikoeruflutter/screen_awake",
      binaryMessenger: controller.binaryMessenger
    )
    screenAwakeChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "setKeepScreenOn":
        let args = call.arguments as? [String: Any]
        let enabled = args?["enabled"] as? Bool ?? false
        UIApplication.shared.isIdleTimerDisabled = enabled
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let systemProxyChannel = FlutterMethodChannel(
      name: "com.meteor.kikoeruflutter/system_proxy",
      binaryMessenger: controller.binaryMessenger
    )
    systemProxyChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
        return
      }
      switch call.method {
      case "getSystemProxy":
        result(self.systemProxy())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func systemProxy() -> String? {
    guard let settings = CFNetworkCopySystemProxySettings()?.takeUnretainedValue()
      as NSDictionary? else {
      return nil
    }

    var entries: [String] = []
    // iOS exposes the HTTP proxy keys here; Dart uses this entry as the
    // HTTPS fallback as well. The HTTPS-specific keys are macOS-only.
    appendProxy(
      to: &entries,
      settings: settings,
      hostKey: kCFNetworkProxiesHTTPProxy,
      portKey: kCFNetworkProxiesHTTPPort,
      enabledKey: kCFNetworkProxiesHTTPEnable,
      scheme: "http"
    )
    return entries.isEmpty ? nil : entries.joined(separator: ";")
  }

  private func appendProxy(
    to entries: inout [String],
    settings: NSDictionary,
    hostKey: CFString,
    portKey: CFString,
    enabledKey: CFString,
    scheme: String
  ) {
    if let enabled = settings[enabledKey] as? NSNumber, !enabled.boolValue {
      return
    }
    guard let host = settings[hostKey] as? String,
          let port = (settings[portKey] as? NSNumber)?.intValue,
          !host.isEmpty,
          port > 0 else {
      return
    }
    entries.append("\(scheme)=\(host):\(port)")
  }
}

class AudioHapticsBridge {
    private let channel: FlutterMethodChannel
    private var engine: CHHapticEngine?
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var streamAnalysisGeneration = 0
    private var loggedHapticsCapability = false
    private var loggedCoreHapticsFailure = false
    private var loggedFallbackPulse = false
    private var loggedReadableAlias = false
    private var loggedAssetReaderFallback = false

    init(controller: FlutterViewController) {
        channel = FlutterMethodChannel(
            name: "com.meteor.kikoeruflutter/audio_haptics",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "analyze":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "bad_args", message: "Missing audio path", details: nil))
                return
            }
            let frameMs = args["frameMs"] as? Int ?? 50
            let maxDurationMs = args["maxDurationMs"] as? Int ?? 10_800_000
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let analysis = try self.analyzeAudio(
                        path: path,
                        frameMs: frameMs,
                        maxDurationMs: maxDurationMs
                    )
                    DispatchQueue.main.async {
                        result(analysis)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "analysis_failed",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }
        case "pulse":
            let args = call.arguments as? [String: Any]
            let intensity = args?["intensity"] as? Double ?? 0.5
            let durationMs = args?["durationMs"] as? Int ?? 40
            pulse(intensity: intensity, durationMs: durationMs)
            result(nil)
        case "silence":
            result(nil)
        case "stop":
            streamAnalysisGeneration += 1
            result(nil)
        case "startFileStreamAnalysis":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "bad_args", message: "Missing audio path", details: nil))
                return
            }
            let frameMs = args["frameMs"] as? Int ?? 50
            let maxDurationMs = args["maxDurationMs"] as? Int ?? 10_800_000
            let startPositionMs = args["startPositionMs"] as? Int ?? 0
            let finalPath = args["finalPath"] as? String
            let analysisToken = args["analysisToken"] as? Int ?? 0
            streamAnalysisGeneration += 1
            let generation = streamAnalysisGeneration
            DispatchQueue.global(qos: .utility).async {
                self.streamAnalyzeFile(
                    path: path,
                    finalPath: finalPath,
                    frameMs: frameMs,
                    maxDurationMs: maxDurationMs,
                    startPositionMs: startPositionMs,
                    generation: generation,
                    analysisToken: analysisToken,
                    growingFile: false
                )
            }
            result(nil)
        case "startGrowingFileAnalysis":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "bad_args", message: "Missing audio path", details: nil))
                return
            }
            let frameMs = args["frameMs"] as? Int ?? 50
            let maxDurationMs = args["maxDurationMs"] as? Int ?? 10_800_000
            let startPositionMs = args["startPositionMs"] as? Int ?? 0
            let finalPath = args["finalPath"] as? String
            let analysisToken = args["analysisToken"] as? Int ?? 0
            streamAnalysisGeneration += 1
            let generation = streamAnalysisGeneration
            DispatchQueue.global(qos: .utility).async {
                self.streamAnalyzeFile(
                    path: path,
                    finalPath: finalPath,
                    frameMs: frameMs,
                    maxDurationMs: maxDurationMs,
                    startPositionMs: startPositionMs,
                    generation: generation,
                    analysisToken: analysisToken,
                    growingFile: true
                )
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func analyzeAudio(
        path: String,
        frameMs: Int,
        maxDurationMs: Int,
        startFrame: Int = 0,
        maxEnergyFrames: Int? = nil
    ) throws -> [String: Any] {
        let readableURL = readableAudioURL(path: path)
        defer {
            if readableURL.shouldRemove {
                try? FileManager.default.removeItem(at: readableURL.url)
            }
        }
        if readableURL.shouldRemove && !loggedReadableAlias {
            sendDiagnostic("iOS 分析文件没有可识别扩展名，已创建临时别名: \(readableURL.url.lastPathComponent)")
            loggedReadableAlias = true
        }
        do {
            return try analyzeAudioFile(
                url: readableURL.url,
                frameMs: frameMs,
                maxDurationMs: maxDurationMs,
                startFrame: startFrame,
                maxEnergyFrames: maxEnergyFrames
            )
        } catch {
            if !loggedAssetReaderFallback {
                sendDiagnostic("iOS AVAudioFile 分析失败，尝试兼容解码路径: \(error.localizedDescription)")
                loggedAssetReaderFallback = true
            }
            return try analyzeAudioAsset(
                url: readableURL.url,
                frameMs: frameMs,
                maxDurationMs: maxDurationMs,
                startFrame: startFrame,
                maxEnergyFrames: maxEnergyFrames
            )
        }
    }

    private func analyzeAudioFile(
        url: URL,
        frameMs: Int,
        maxDurationMs: Int,
        startFrame: Int,
        maxEnergyFrames: Int?
    ) throws -> [String: Any] {
        let file = try AVAudioFile(forReading: url)
        let sourceFormat = file.processingFormat
        let sampleRate = sourceFormat.sampleRate
        let channels = max(1, Int(sourceFormat.channelCount))
        let resolvedFrameMs = max(20, min(frameMs, 200))
        let frameLength = max(256, Int(sampleRate * Double(resolvedFrameMs) / 1000.0))
        let maxFrames = AVAudioFramePosition(sampleRate * Double(maxDurationMs) / 1000.0)
        let totalFrames = min(file.length, maxFrames)
        let resolvedStartFrame = max(0, startFrame)
        let startAudioFrame = AVAudioFramePosition(resolvedStartFrame * frameLength)
        let durationMs = Int(Double(file.length) / sampleRate * 1000.0)

        if startAudioFrame >= totalFrames {
            return [
                "frameMs": resolvedFrameMs,
                "startFrame": resolvedStartFrame,
                "durationMs": durationMs,
                "energies": [],
            ]
        }

        file.framePosition = startAudioFrame
        let bufferCapacity = AVAudioFrameCount(frameLength)
        let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: bufferCapacity)!
        var energies: [Double] = []
        var framesReadTotal = startAudioFrame

        while framesReadTotal < totalFrames &&
            (maxEnergyFrames == nil || energies.count < maxEnergyFrames!) {
            let framesRemaining = totalFrames - framesReadTotal
            let framesToRead = min(bufferCapacity, AVAudioFrameCount(framesRemaining))
            try file.read(into: buffer, frameCount: framesToRead)
            let framesRead = Int(buffer.frameLength)
            if framesRead <= 0 { break }

            var sumSquares = 0.0
            var sampleCount = 0

            if let floatData = buffer.floatChannelData {
                for channel in 0..<channels {
                    let samples = floatData[channel]
                    for i in 0..<framesRead {
                        let sample = Double(samples[i])
                        sumSquares += sample * sample
                    }
                }
                sampleCount = framesRead * channels
            } else if let intData = buffer.int16ChannelData {
                for channel in 0..<channels {
                    let samples = intData[channel]
                    for i in 0..<framesRead {
                        let sample = Double(samples[i]) / Double(Int16.max)
                        sumSquares += sample * sample
                    }
                }
                sampleCount = framesRead * channels
            }

            let rms = sampleCount > 0 ? sqrt(sumSquares / Double(sampleCount)) : 0
            energies.append(min(1.0, rms * 2.8))
            framesReadTotal += AVAudioFramePosition(framesRead)
        }

        return [
            "frameMs": resolvedFrameMs,
            "startFrame": resolvedStartFrame,
            "durationMs": durationMs,
            "energies": energies,
        ]
    }

    private func analyzeAudioAsset(
        url: URL,
        frameMs: Int,
        maxDurationMs: Int,
        startFrame: Int,
        maxEnergyFrames: Int?
    ) throws -> [String: Any] {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            throw AudioHapticsAnalysisError.noAudioTrack
        }

        let trackInfo = audioTrackInfo(track: track)
        let sampleRate = trackInfo.sampleRate
        if sampleRate <= 0 {
            throw AudioHapticsAnalysisError.invalidSampleRate
        }

        let channels = max(1, trackInfo.channels)
        let resolvedFrameMs = max(20, min(frameMs, 200))
        let frameLength = max(256, Int(sampleRate * Double(resolvedFrameMs) / 1000.0))
        let maxFrames = AVAudioFramePosition(sampleRate * Double(maxDurationMs) / 1000.0)
        let assetDurationSeconds = validSeconds(asset.duration)
            ?? validSeconds(track.timeRange.duration)
            ?? 0
        let assetFrames = AVAudioFramePosition(assetDurationSeconds * sampleRate)
        let totalFrames = min(assetFrames, maxFrames)
        let resolvedStartFrame = max(0, startFrame)
        let startAudioFrame = AVAudioFramePosition(resolvedStartFrame * frameLength)
        let durationMs = Int(assetDurationSeconds * 1000.0)

        if startAudioFrame >= totalFrames {
            return [
                "frameMs": resolvedFrameMs,
                "startFrame": resolvedStartFrame,
                "durationMs": durationMs,
                "energies": [],
            ]
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw AudioHapticsAnalysisError.readerOutputUnavailable
        }
        reader.add(output)

        let timeScale = CMTimeScale(max(1, min(Int(Int32.max), Int(sampleRate.rounded()))))
        let startTime = CMTime(seconds: Double(startAudioFrame) / sampleRate, preferredTimescale: timeScale)
        let durationTime = CMTime(seconds: Double(totalFrames - startAudioFrame) / sampleRate, preferredTimescale: timeScale)
        reader.timeRange = CMTimeRange(start: startTime, duration: durationTime)

        guard reader.startReading() else {
            throw reader.error ?? AudioHapticsAnalysisError.readerStartFailed
        }

        var energies: [Double] = []
        var pendingSumSquares = 0.0
        var pendingSampleCount = 0
        var pendingFrameSamples = 0

        while reader.status == .reading &&
            (maxEnergyFrames == nil || energies.count < maxEnergyFrames!) {
            guard let sampleBuffer = output.copyNextSampleBuffer() else {
                break
            }
            try appendEnergies(
                from: sampleBuffer,
                fallbackChannels: channels,
                frameLength: frameLength,
                maxEnergyFrames: maxEnergyFrames,
                energies: &energies,
                pendingSumSquares: &pendingSumSquares,
                pendingSampleCount: &pendingSampleCount,
                pendingFrameSamples: &pendingFrameSamples
            )
        }

        if reader.status == .failed {
            throw reader.error ?? AudioHapticsAnalysisError.readerFailed
        }

        if pendingFrameSamples > 0 &&
            (maxEnergyFrames == nil || energies.count < maxEnergyFrames!) {
            let rms = pendingSampleCount > 0
                ? sqrt(pendingSumSquares / Double(pendingSampleCount))
                : 0
            energies.append(min(1.0, rms * 2.8))
        }

        return [
            "frameMs": resolvedFrameMs,
            "startFrame": resolvedStartFrame,
            "durationMs": durationMs,
            "energies": energies,
        ]
    }

    private func appendEnergies(
        from sampleBuffer: CMSampleBuffer,
        fallbackChannels: Int,
        frameLength: Int,
        maxEnergyFrames: Int?,
        energies: inout [Double],
        pendingSumSquares: inout Double,
        pendingSampleCount: inout Int,
        pendingFrameSamples: inout Int
    ) throws {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }

        let dataLength = CMBlockBufferGetDataLength(blockBuffer)
        if dataLength <= 0 { return }

        var data = Data(count: dataLength)
        let copyStatus = data.withUnsafeMutableBytes { rawBuffer -> OSStatus in
            guard let baseAddress = rawBuffer.baseAddress else { return noErr }
            return CMBlockBufferCopyDataBytes(
                blockBuffer,
                atOffset: 0,
                dataLength: dataLength,
                destination: baseAddress
            )
        }
        if copyStatus != noErr {
            throw AudioHapticsAnalysisError.blockBufferCopyFailed(copyStatus)
        }

        let frames = CMSampleBufferGetNumSamples(sampleBuffer)
        if frames <= 0 { return }

        let channels = max(1, channelCount(from: sampleBuffer) ?? fallbackChannels)
        let maxFloatSamples = min(dataLength / MemoryLayout<Float>.size, frames * channels)
        if maxFloatSamples <= 0 { return }

        data.withUnsafeBytes { rawBuffer in
            let samples = rawBuffer.bindMemory(to: Float.self)
            let totalFrames = min(frames, maxFloatSamples / channels)
            for frameIndex in 0..<totalFrames {
                if let maxEnergyFrames, energies.count >= maxEnergyFrames {
                    break
                }

                let sampleOffset = frameIndex * channels
                for channel in 0..<channels {
                    let sample = Double(samples[sampleOffset + channel])
                    pendingSumSquares += sample * sample
                }
                pendingSampleCount += channels
                pendingFrameSamples += 1

                if pendingFrameSamples >= frameLength {
                    let rms = pendingSampleCount > 0
                        ? sqrt(pendingSumSquares / Double(pendingSampleCount))
                        : 0
                    energies.append(min(1.0, rms * 2.8))
                    pendingSumSquares = 0
                    pendingSampleCount = 0
                    pendingFrameSamples = 0
                }
            }
        }
    }

    private func audioTrackInfo(track: AVAssetTrack) -> (sampleRate: Double, channels: Int) {
        for formatDescription in track.formatDescriptions {
            let audioDescription = formatDescription as! CMAudioFormatDescription
            guard let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioDescription) else {
                continue
            }
            let sampleRate = streamDescription.pointee.mSampleRate
            let channels = Int(streamDescription.pointee.mChannelsPerFrame)
            if sampleRate > 0 {
                return (sampleRate, max(1, channels))
            }
        }
        return (44_100, 2)
    }

    private func channelCount(from sampleBuffer: CMSampleBuffer) -> Int? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return nil
        }
        let channels = Int(streamDescription.pointee.mChannelsPerFrame)
        return channels > 0 ? channels : nil
    }

    private func validSeconds(_ time: CMTime) -> Double? {
        let seconds = CMTimeGetSeconds(time)
        return seconds.isFinite && seconds > 0 ? seconds : nil
    }

    private func streamAnalyzeFile(
        path: String,
        finalPath: String?,
        frameMs: Int,
        maxDurationMs: Int,
        startPositionMs: Int,
        generation: Int,
        analysisToken: Int,
        growingFile: Bool
    ) {
        let resolvedFrameMs = max(20, min(frameMs, 200))
        let chunkFrames = growingFile ? 24 : 240
        var nextFrame = max(0, startPositionMs / resolvedFrameMs)
        var retryCount = 0

        while generation == streamAnalysisGeneration {
            do {
                let readablePath = readableAnalysisPath(path: path, finalPath: finalPath)
                let analysis = try analyzeAudio(
                    path: readablePath,
                    frameMs: resolvedFrameMs,
                    maxDurationMs: maxDurationMs,
                    startFrame: nextFrame,
                    maxEnergyFrames: chunkFrames
                )
                guard generation == streamAnalysisGeneration else { return }
                guard let energies = analysis["energies"] as? [Double] else { return }
                let chunkStartFrame = analysis["startFrame"] as? Int ?? nextFrame

                if !energies.isEmpty {
                    sendAnalysisChunk(
                        analysisToken: analysisToken,
                        frameMs: resolvedFrameMs,
                        startFrame: chunkStartFrame,
                        energies: energies
                    )
                    nextFrame = chunkStartFrame + energies.count
                    retryCount = 0
                }

                let finalReady = finalPath != nil &&
                    FileManager.default.fileExists(atPath: finalPath!)
                if energies.isEmpty && (!growingFile || finalReady) {
                    sendAnalysisFinished(analysisToken: analysisToken)
                    return
                }

                if Int64(nextFrame * resolvedFrameMs) >= Int64(maxDurationMs) {
                    sendAnalysisFinished(analysisToken: analysisToken)
                    return
                }
                let sleepInterval: TimeInterval
                if energies.isEmpty {
                    sleepInterval = growingFile ? 0.75 : 0.02
                } else {
                    sleepInterval = growingFile ? 0.12 : 0.02
                }
                Thread.sleep(forTimeInterval: sleepInterval)
            } catch {
                guard generation == streamAnalysisGeneration else { return }
                let finalReady = finalPath != nil &&
                    FileManager.default.fileExists(atPath: finalPath!)
                if !growingFile ||
                    (finalReady && retryCount >= 24) ||
                    retryCount >= 240 {
                    sendAnalysisFailed(
                        analysisToken: analysisToken,
                        message: error.localizedDescription
                    )
                    return
                }
                retryCount += 1
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    private func readableAnalysisPath(path: String, finalPath: String?) -> String {
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
        if let finalPath, FileManager.default.fileExists(atPath: finalPath) {
            return finalPath
        }
        return path
    }

    private func readableAudioURL(path: String) -> (url: URL, shouldRemove: Bool) {
        let url = URL(fileURLWithPath: path)
        if isKnownAudioExtension(url.pathExtension) {
            return (url, false)
        }

        guard let extensionHint = sniffAudioExtension(path: path) else {
            return (url, false)
        }

        let aliasName = "kikoflu_haptics_\(abs(path.hashValue)).\(extensionHint)"
        let aliasURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(aliasName)
        try? FileManager.default.removeItem(at: aliasURL)

        do {
            try FileManager.default.linkItem(at: url, to: aliasURL)
            return (aliasURL, true)
        } catch {
            do {
                try FileManager.default.copyItem(at: url, to: aliasURL)
                return (aliasURL, true)
            } catch {
                return (url, false)
            }
        }
    }

    private func isKnownAudioExtension(_ value: String) -> Bool {
        switch value.lowercased() {
        case "mp3", "m4a", "mp4", "aac", "wav", "aiff", "aif", "caf":
            return true
        default:
            return false
        }
    }

    private func sniffAudioExtension(path: String) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: 16)
        let bytes = [UInt8](data)
        if bytes.count >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33 {
            return "mp3"
        }
        if bytes.count >= 2 && bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0 {
            return "mp3"
        }
        if bytes.count >= 12 &&
            bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
            bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45 {
            return "wav"
        }
        if bytes.count >= 8 &&
            bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            return "m4a"
        }
        if bytes.count >= 2 && bytes[0] == 0xff && (bytes[1] == 0xf1 || bytes[1] == 0xf9) {
            return "aac"
        }
        return nil
    }

    private func sendAnalysisChunk(
        analysisToken: Int,
        frameMs: Int,
        startFrame: Int,
        energies: [Double]
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("analysisChunk", arguments: [
                "analysisToken": analysisToken,
                "frameMs": frameMs,
                "startFrame": startFrame,
                "energies": energies,
            ])
        }
    }

    private func sendAnalysisFinished(analysisToken: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod(
                "analysisFinished",
                arguments: ["analysisToken": analysisToken]
            )
        }
    }

    private func sendAnalysisFailed(analysisToken: Int, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod(
                "analysisFailed",
                arguments: [
                    "analysisToken": analysisToken,
                    "message": message,
                ]
            )
        }
    }

    private func sendDiagnostic(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("diagnostic", arguments: ["message": message])
        }
    }

    private func pulse(intensity: Double, durationMs: Int) {
        let clampedIntensity = max(0.1, min(1.0, intensity))
        let clampedDuration = max(0.01, min(0.12, Double(durationMs) / 1000.0))
        if !loggedHapticsCapability {
            if #available(iOS 13.0, *) {
                sendDiagnostic(
                    "iOS 触感能力: supportsHaptics=\(CHHapticEngine.capabilitiesForHardware().supportsHaptics), supportsAudio=\(CHHapticEngine.capabilitiesForHardware().supportsAudio)"
                )
            } else {
                sendDiagnostic("iOS 触感能力: CoreHaptics unavailable below iOS 13")
            }
            loggedHapticsCapability = true
        }

        if #available(iOS 13.0, *), CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            do {
                if engine == nil {
                    engine = try CHHapticEngine()
                    engine?.stoppedHandler = { [weak self] _ in self?.engine = nil }
                    engine?.resetHandler = { [weak self] in
                        try? self?.engine?.start()
                    }
                }
                try engine?.start()
                let parameters = [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(clampedIntensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(max(0.25, min(1.0, clampedIntensity + 0.15)))),
                ]
                let event: CHHapticEvent
                if clampedDuration > 0.045 {
                    event = CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: parameters,
                        relativeTime: 0,
                        duration: clampedDuration
                    )
                } else {
                    event = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: parameters,
                        relativeTime: 0
                    )
                }
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
                return
            } catch {
                if !loggedCoreHapticsFailure {
                    sendDiagnostic("CoreHaptics 播放失败，降级到 UIImpactFeedbackGenerator: \(error.localizedDescription)")
                    loggedCoreHapticsFailure = true
                }
                // Fall back below.
            }
        }

        if !loggedFallbackPulse {
            sendDiagnostic("使用 UIImpactFeedbackGenerator 触感降级路径")
            loggedFallbackPulse = true
        }
        let style: UIImpactFeedbackGenerator.FeedbackStyle =
            clampedIntensity > 0.72 ? .heavy : (clampedIntensity > 0.42 ? .medium : .light)
        impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator?.prepare()
        if #available(iOS 13.0, *) {
            impactGenerator?.impactOccurred(intensity: CGFloat(clampedIntensity))
        } else {
            impactGenerator?.impactOccurred()
        }
        if clampedIntensity > 0.85 {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
}

private enum AudioHapticsAnalysisError: LocalizedError {
    case noAudioTrack
    case invalidSampleRate
    case readerOutputUnavailable
    case readerStartFailed
    case readerFailed
    case blockBufferCopyFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "No readable audio track was found"
        case .invalidSampleRate:
            return "Invalid audio sample rate"
        case .readerOutputUnavailable:
            return "Audio reader output is unavailable"
        case .readerStartFailed:
            return "Audio reader failed to start"
        case .readerFailed:
            return "Audio reader failed"
        case .blockBufferCopyFailed(let status):
            return "Audio sample buffer copy failed: \(status)"
        }
    }
}

// MARK: - Network Speed Monitor
class NetworkSpeedMonitor {
    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var timer: Timer?
    var onSpeedUpdate: ((String) -> Void)?
    
    func start() {
        // Initialize with current values
        let (bytesIn, bytesOut) = getNetworkBytes()
        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func update() {
        let (bytesIn, bytesOut) = getNetworkBytes()
        let downloadSpeed = bytesIn >= previousBytesIn ? bytesIn - previousBytesIn : 0
        let uploadSpeed = bytesOut >= previousBytesOut ? bytesOut - previousBytesOut : 0
        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
        
        let downStr = formatSpeed(downloadSpeed)
        let upStr = formatSpeed(uploadSpeed)
        onSpeedUpdate?("↓\(downStr) ↑\(upStr)")
    }
    
    private func getNetworkBytes() -> (UInt64, UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }
        
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        
        var ptr = firstAddr
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            // Include Wi-Fi (en0) and cellular (pdp_ip0) interfaces
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                if let data = ptr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    bytesIn += UInt64(networkData.pointee.ifi_ibytes)
                    bytesOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            if let next = ptr.pointee.ifa_next {
                ptr = next
            } else {
                break
            }
        }
        
        return (bytesIn, bytesOut)
    }
    
    private func formatSpeed(_ bytesPerSecond: UInt64) -> String {
        let kb = Double(bytesPerSecond) / 1024.0
        if kb < 1024 {
            return String(format: "%.0f KB/s", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.1f MB/s", mb)
    }
}

// MARK: - FPS Monitor
// Uses Apple's recommended approach: read the display's current frame interval
// via (targetTimestamp - timestamp) each CADisplayLink callback.
// This reports the refresh rate the system is actually driving — correctly
// shows 120Hz on ProMotion when the display is running fast (e.g. during
// scrolling/animations) and 60Hz when idle.
// Note: CADisplayLink's presence on the RunLoop keeps ProMotion at ≥60Hz;
// this is an inherent iOS limitation shared by all CADisplayLink-based monitors.
class FPSMonitor {
    private var displayLink: CADisplayLink?
    private var lastReportTime: CFTimeInterval = 0
    private var fpsReadings: [Double] = []

    var onFPSUpdate: ((Int) -> Void)?

    func start() {
        stop()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        // Request the full range so we receive callbacks at whatever rate the
        // system is currently driving (up to 120Hz on ProMotion devices).
        if #available(iOS 15.0, *) {
            let maxFPS = Float(UIScreen.main.maximumFramesPerSecond)
            displayLink?.preferredFrameRateRange = CAFrameRateRange(
                minimum: 1, maximum: maxFPS, preferred: 0)
        }
        displayLink?.add(to: .main, forMode: .common)
        lastReportTime = 0
        fpsReadings.removeAll()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        fpsReadings.removeAll()
        lastReportTime = 0
    }

    @objc private func tick(link: CADisplayLink) {
        // Apple-recommended way to read the current display refresh rate.
        let frameDuration = link.targetTimestamp - link.timestamp
        if frameDuration > 0 {
            fpsReadings.append(1.0 / frameDuration)
        }

        let now = CACurrentMediaTime()
        if lastReportTime == 0 {
            lastReportTime = now
            return
        }

        // Report averaged FPS every ~1 second
        if now - lastReportTime >= 1.0 {
            if !fpsReadings.isEmpty {
                let avg = fpsReadings.reduce(0, +) / Double(fpsReadings.count)
                onFPSUpdate?(Int(round(avg)))
                fpsReadings.removeAll()
            }
            lastReportTime = now
        }
    }
}

@available(iOS 15.0, *)
private final class FloatingLyricSampleBufferPlaybackDelegate: NSObject,
    AVPictureInPictureSampleBufferPlaybackDelegate {
    weak var manager: FloatingLyricManager?

    init(manager: FloatingLyricManager) {
        self.manager = manager
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        if playing {
            manager?.refreshSampleBufferFrame()
        }
    }

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        false
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        manager?.refreshSampleBufferFrame()
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion: @escaping () -> Void
    ) {
        completion()
    }
}

class FloatingLyricManager: NSObject, AVPictureInPictureControllerDelegate {
    private var pipController: AVPictureInPictureController?
    private var pipPossibleObservation: NSKeyValueObservation?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var playerLayerReadyObservation: NSKeyValueObservation?
    private var sampleBufferStatusObservation: NSKeyValueObservation?
    private var sampleBufferReadyObservation: NSKeyValueObservation?
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var videoComposition: AVMutableVideoComposition?
    private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private var sampleBufferPlaybackDelegate: AnyObject?
    private weak var hostView: UIView?
    private var channel: FlutterMethodChannel

    private var fpsMonitor = FPSMonitor()
    private var networkSpeedMonitor = NetworkSpeedMonitor()
    private var showFPS: Bool = false
    private var showNetworkSpeed: Bool = false
    private var currentFPS: Int?
    private var currentNetworkSpeed: String?

    private var currentText = "♪ - ♪"
    private var lyricFontSize: CGFloat = 14
    private var lyricTextColor: UIColor = .white
    private var lyricBackgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 0.88)
    private var lyricCornerRadius: CGFloat = 16
    private var lyricPaddingHorizontal: CGFloat = 20
    private var lyricPaddingVertical: CGFloat = 10
    private var infoTextColor: UIColor = .white
    private let logicalFrameSize = CGSize(width: 414, height: 104)
    private let outputFrameRate: Int32 = 30
    private var renderSize = CGSize(width: 828, height: 208)
    private var renderScale: CGFloat = 2
    private var renderInputLogicalWidth: CGFloat = 414
    private var renderInputNativeScale: CGFloat = 2
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private let renderedFrameLock = NSLock()
    private var renderedFrame: CGImage?
    private var renderedCIImage: CIImage?
    private var renderedFrameGeneration = 0
    private var compositionFrameCount = 0
    private var didLogFirstCompositionFrame = false
    private var sampleBufferEnqueueCount = 0
    private let sampleBufferHeartbeatInterval: TimeInterval = 0.25
    private var sampleBufferHeartbeatTimer: Timer?
    private var sampleBufferHeartbeatEnqueueCount = 0
    private var sampleBufferLastEnqueueUptime: TimeInterval?
    private var sampleBufferMaximumEnqueueGapMilliseconds = 0
    private var sampleBufferPixelBuffer: CVPixelBuffer?
    private var sampleBufferFormatDescription: CMVideoFormatDescription?
    private var sampleBufferFrameGeneration = -1
    private var sampleBufferCreationFailureCount = 0
    private var didLogSampleBufferCreationFailure = false
    private var sampleBufferLastCreationFailureStage: String?
    private var sampleBufferLastCreationFailureStatus: Int32?
    private var didLogSampleBufferFlushAfterFailure = false
    private var didAttemptSampleBufferFailureReset = false
    private var didLogSampleBufferResetFailure = false
    private var sampleBufferResetInProgress = false
    private var didLogSampleBufferFrameContent = false
    private var sampleBufferLastPresentationTime: CMTime?
    private var sampleBufferNonMonotonicTimestampCount = 0
    private var sampleBufferFrameContentDetails: [String: Any]?
    private var pictureInPictureStartUptime: TimeInterval?
    private var stopRequestedByApp = false
    private var setupFailure: String?
    private var pendingShowResult: FlutterResult?
    private var startGeneration = 0
    private var startRequestedGeneration: Int?
    
    // Base64 of a 1-second black MP4 video
    private let dummyVideoBase64 = "AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAAAIZnJlZQAAAzxtZGF0AAACnwYF//+b3EXpvebZSLeWLNgg2SPu73gyNjQgLSBjb3JlIDE2NSAtIEguMjY0L01QRUctNCBBVkMgY29kZWMgLSBDb3B5bGVmdCAyMDAzLTIwMjUgLSBodHRwOi8vd3d3LnZpZGVvbGFuLm9yZy94MjY0Lmh0bWwgLSBvcHRpb25zOiBjYWJhYz0xIHJlZj0zIGRlYmxvY2s9MTowOjAgYW5hbHlzZT0weDM6MHgxMTMgbWU9aGV4IHN1Ym1lPTcgcHN5PTEgcHN5X3JkPTEuMDA6MC4wMCBtaXhlZF9yZWY9MSBtZV9yYW5nZT0xNiBjaHJvbWFfbWU9MSB0cmVsbGlzPTEgOHg4ZGN0PTEgY3FtPTAgZGVhZHpvbmU9MjEsMTEgZmFzdF9wc2tpcD0xIGNocm9tYV9xcF9vZmZzZXQ9LTIgdGhyZWFkcz0zIGxvb2thaGVhZF90aHJlYWRzPTEgc2xpY2VkX3RocmVhZHM9MCBucj0wIGRlY2ltYXRlPTEgaW50ZXJsYWNlZD0wIGJsdXJheV9jb21wYXQ9MCBjb25zdHJhaW5lZF9pbnRyYT0wIGJmcmFtZXM9MyBiX3B5cmFtaWQ9MiBiX2FkYXB0PTEgYl9iaWFzPTAgZGlyZWN0PTEgd2VpZ2h0Yj0xIG9wZW5fZ29wPTAgd2VpZ2h0cD0yIGtleWludD0yNTAga2V5aW50X21pbj0xIHNjZW5lY3V0PTQwIGludHJhX3JlZnJlc2g9MCByY19sb29rYWhlYWQ9NDAgcmM9Y3JmIG1idHJlZT0xIGNyZj0yMy4wIHFjb21wPTAuNjAgcXBtaW49MCBxcG1heD02OSBxcHN0ZXA9NCBpcF9yYXRpbz0xLjQwIGFxPTE6MS4wMACAAAAAbmWIhAAX//731LfMsu4HIrYLqPeiniZfQ3UlAZuWxO06gAAAAwH59sMvUJl+D/6JZYfSbX+N2G0zTmpT8MS5Z28oYXk80p7dd2r0R/+AAe9UAACvQpMjU6B8PVjHQ4Eclp5iBuAWr7bKk+fDOdstAAAADUGaImxBX/7WpVAAJmAAAAAKAZ5BeQV/AAAZ8QAAA1Ntb292AAAAbG12aGQAAAAAAAAAAAAAAAAAAAPoAAAPoAABAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAACfnRyYWsAAABcdGtoZAAAAAMAAAAAAAAAAAAAAAEAAAAAAAAPoAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAABngAAAGgAAAAAACRlZHRzAAAAHGVsc3QAAAAAAAAAAQAAD6AAAIAAAAEAAAAAAfZtZGlhAAAAIG1kaGQAAAAAAAAAAAAAAAAAAEAAAAFAAFXEAAAAAAAxaGRscgAAAAAAAAAAdmlkZQAAAAAAAAAAAAAAAENvcmUgTWVkaWEgVmlkZW8AAAABnW1pbmYAAAAUdm1oZAAAAAEAAAAAAAAAAAAAACRkaW5mAAAAHGRyZWYAAAAAAAAAAQAAAAx1cmwgAAAAAQAAAV1zdGJsAAAAsXN0c2QAAAAAAAAAAQAAAKFhdmMxAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAZ4AaABIAAAASAAAAAAAAAABFUxhdmM2Mi4xNi4xMDAgbGlieDI2NAAAAAAAAAAAAAAAGP//AAAAN2F2Y0MBZAAL/+EAGmdkAAus2UGj+pYpQAAAAwBAAAADAIPFCmWAAQAGaOvjyyLA/fj4AAAAABRidHJ0AAAAAAAACIoAAAAAAAAAGHN0dHMAAAAAAAAAAQAAAAMAAEAAAAAAFHN0c3MAAAAAAAAAAQAAAAEAAAAoY3R0cwAAAAAAAAADAAAAAQAAgAAAAAABAADAAAAAAAEAAEAAAAAAHHN0c2MAAAAAAAAAAQAAAAEAAAADAAAAAQAAACBzdHN6AAAAAAAAAAAAAAADAAADFQAAABEAAAAOAAAAFHN0Y28AAAAAAAAAAQAAADAAAABhdWR0YQAAAFltZXRhAAAAAAAAACFoZGxyAAAAAAAAAABtZGlyYXBwbAAAAAAAAAAAAAAAACxpbHN0AAAAJKl0b28AAAAcZGF0YQAAAAEAAAAATGF2ZjYyLjYuMTAx"

    init(controller: FlutterViewController) {
        channel = FlutterMethodChannel(
            name: "com.kikoeru.flutter/floating_lyric",
            binaryMessenger: controller.binaryMessenger
        )
        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        hostView = controller.view
        updateRenderMetrics(for: controller.view)
        rebuildRenderedFrame()
        setupPictureInPicture(in: controller.view)
    }

    deinit {
        sampleBufferHeartbeatTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func updateRenderMetrics(for view: UIView?) {
        guard let view else { return }
        let screen = view.window?.screen ?? UIScreen.main
        let logicalWidth = view.bounds.width > 0
            ? view.bounds.width
            : screen.bounds.width
        let nativeScale = screen.nativeScale > 0 ? screen.nativeScale : screen.scale
        let physicalWidth = logicalWidth * nativeScale
        let minimumWidth = logicalFrameSize.width * 2
        let maximumWidth = logicalFrameSize.width * 4
        let preferredWidth = physicalWidth * 0.5
        let outputWidth = evenPixelValue(
            min(max(preferredWidth, minimumWidth), maximumWidth)
        )
        let scale = outputWidth / logicalFrameSize.width
        let outputHeight = evenPixelValue(logicalFrameSize.height * scale)

        renderInputLogicalWidth = logicalWidth
        renderInputNativeScale = nativeScale
        renderScale = scale
        renderSize = CGSize(width: outputWidth, height: outputHeight)

        updateSampleBufferDisplayLayerGeometry()

        if let videoComposition {
            videoComposition.renderSize = renderSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: outputFrameRate)
            player?.currentItem?.videoComposition = videoComposition
        }
    }

    private func evenPixelValue(_ value: CGFloat) -> CGFloat {
        CGFloat(max(2, Int(value.rounded()) / 2 * 2))
    }

    private func setupPictureInPicture(in view: UIView) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            setupFailure = "picture_in_picture_unsupported"
            return
        }

        if #available(iOS 15.0, *) {
            setupSampleBufferPictureInPicture(in: view)
        } else {
            setupLegacyPictureInPicture(in: view)
        }
    }

    @available(iOS 15.0, *)
    private func setupSampleBufferPictureInPicture(in view: UIView) {
        let displayLayer = AVSampleBufferDisplayLayer()
        displayLayer.opacity = 1
        displayLayer.backgroundColor = UIColor.black.cgColor
        displayLayer.videoGravity = .resizeAspect
        sampleBufferDisplayLayer = displayLayer
        updateSampleBufferDisplayLayerGeometry()
        attachSampleBufferDisplayLayer(below: view)

        let playbackDelegate = FloatingLyricSampleBufferPlaybackDelegate(manager: self)
        sampleBufferPlaybackDelegate = playbackDelegate
        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: playbackDelegate
        )
        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.delegate = self
        pipController?.requiresLinearPlayback = true
        pipController?.setValue(1, forKey: "controlsStyle")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sampleBufferDisplayLayerFailedToDecode(notification:)),
            name: .AVSampleBufferDisplayLayerFailedToDecode,
            object: displayLayer
        )
        observeSampleBufferState(displayLayer)
        observePictureInPicturePossibility()
        enqueueCurrentSampleBuffer(reason: "setup")
        if pipController == nil {
            setupFailure = "sample_buffer_pip_controller_creation_failed"
        }
    }

    private func updateSampleBufferDisplayLayerGeometry() {
        guard let displayLayer = sampleBufferDisplayLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.bounds = CGRect(origin: .zero, size: logicalFrameSize)
        displayLayer.position = CGPoint(
            x: logicalFrameSize.width / 2,
            y: logicalFrameSize.height / 2
        )
        displayLayer.contentsScale = renderScale
        CATransaction.commit()
    }

    private func attachSampleBufferDisplayLayer(below view: UIView) {
        guard let displayLayer = sampleBufferDisplayLayer,
              let parentLayer = view.layer.superlayer else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.removeFromSuperlayer()
        parentLayer.insertSublayer(displayLayer, below: view.layer)
        CATransaction.commit()
    }

    private func setupLegacyPictureInPicture(in view: UIView) {
        guard let data = Data(base64Encoded: dummyVideoBase64) else {
            setupFailure = "dummy_video_decode_failed"
            return
        }
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pip_video.mp4")
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            setupFailure = "dummy_video_write_failed: \(error.localizedDescription)"
            return
        }

        let asset = AVURLAsset(url: fileURL)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 0
        let composition = AVMutableVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler: { [weak self] request in
                guard let self, let overlay = self.currentRenderedCIImage() else {
                    request.finish(with: request.sourceImage, context: nil)
                    return
                }
                let sourceExtent = request.sourceImage.extent
                let outputExtent = CGRect(origin: .zero, size: request.renderSize)
                let scaledOverlay = overlay.transformed(by: CGAffineTransform(
                    scaleX: outputExtent.width / overlay.extent.width,
                    y: outputExtent.height / overlay.extent.height
                ))
                let output = scaledOverlay.transformed(by: CGAffineTransform(
                    translationX: outputExtent.minX - scaledOverlay.extent.minX,
                    y: outputExtent.minY - scaledOverlay.extent.minY
                )).cropped(to: outputExtent)
                request.finish(with: output, context: nil)
                self.recordCompositionFrame(
                    sourceSize: sourceExtent.size,
                    outputSize: output.extent.size
                )
            }
        )
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: outputFrameRate)
        videoComposition = composition
        item.videoComposition = composition
        player = AVPlayer(playerItem: item)
        player?.isMuted = true
        player?.allowsExternalPlayback = true
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlayToEnd(notification:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemNewErrorLogEntry(notification:)),
            name: .AVPlayerItemNewErrorLogEntry,
            object: item
        )

        let layer = AVPlayerLayer(player: player)
        layer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        layer.opacity = 0.01
        view.layer.addSublayer(layer)
        playerLayer = layer
        pipController = AVPictureInPictureController(playerLayer: layer)
        pipController?.delegate = self
        pipController?.setValue(1, forKey: "controlsStyle")
        observePlayerState(item: item, layer: layer)
        observePictureInPicturePossibility()
        if pipController == nil {
            setupFailure = "picture_in_picture_controller_creation_failed"
        }
    }

    @available(iOS 15.0, *)
    private func observeSampleBufferState(_ displayLayer: AVSampleBufferDisplayLayer) {
        if #available(iOS 17.0, *) {
            let renderer = displayLayer.sampleBufferRenderer
            sampleBufferStatusObservation = renderer.observe(\.status, options: [.new]) {
                [weak self, weak displayLayer] renderer, _ in
                DispatchQueue.main.async {
                    guard let self, let displayLayer else { return }
                    self.emitDiagnostic(
                        "sample_buffer_status_changed",
                        level: renderer.status == .failed ? "error" : "info",
                        details: self.sampleBufferDetails(displayLayer)
                    )
                }
            }
        } else {
            sampleBufferStatusObservation = displayLayer.observe(\.status, options: [.new]) {
                [weak self, weak displayLayer] layer, _ in
                DispatchQueue.main.async {
                    guard let self, let displayLayer else { return }
                    self.emitDiagnostic(
                        "sample_buffer_status_changed",
                        level: layer.status == .failed ? "error" : "info",
                        details: self.sampleBufferDetails(displayLayer)
                    )
                }
            }
        }
        if #available(iOS 17.4, *) {
            sampleBufferReadyObservation = displayLayer.observe(
                \.isReadyForDisplay,
                options: [.new]
            ) { [weak self] layer, _ in
                DispatchQueue.main.async {
                    self?.emitDiagnostic(
                        "sample_buffer_ready_changed",
                        details: ["readyForDisplay": layer.isReadyForDisplay]
                    )
                }
            }
        }
    }

    @objc private func sampleBufferDisplayLayerFailedToDecode(notification: Notification) {
        let error = notification.userInfo?[
            AVSampleBufferDisplayLayerFailedToDecodeNotificationErrorKey
        ] as? Error
        var details = errorDetails(error)
        if let displayLayer = notification.object as? AVSampleBufferDisplayLayer {
            sampleBufferDetails(displayLayer).forEach { details[$0.key] = $0.value }
        }
        emitDiagnostic(
            "sample_buffer_failed_to_decode",
            level: "error",
            details: details
        )
    }

    private func observePictureInPicturePossibility() {
        pipPossibleObservation = pipController?.observe(
            \.isPictureInPicturePossible,
            options: [.new]
        ) { [weak self] _, change in
            DispatchQueue.main.async {
                guard let self else { return }
                self.emitDiagnostic(
                    "pip_possibility_changed",
                    details: ["possible": change.newValue == true]
                )
                if change.newValue == true {
                    self.startPendingPictureInPictureIfPossible()
                }
            }
        }
    }

    private func observePlayerState(item: AVPlayerItem, layer: AVPlayerLayer) {
        playerItemStatusObservation = item.observe(\.status, options: [.new]) {
            [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let level = item.status == .failed ? "error" : "info"
                self.emitDiagnostic(
                    "player_item_status_changed",
                    level: level,
                    details: self.diagnosticSnapshot()
                )
            }
        }
        playerLayerReadyObservation = layer.observe(\.isReadyForDisplay, options: [.new]) {
            [weak self] layer, _ in
            DispatchQueue.main.async {
                self?.emitDiagnostic(
                    "player_layer_ready_changed",
                    details: ["readyForDisplay": layer.isReadyForDisplay]
                )
            }
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero) { [weak self] completed in
            guard let self else { return }
            if completed,
               self.pendingShowResult != nil ||
               self.pipController?.isPictureInPictureActive == true {
                self.player?.play()
            } else if !completed {
                self.emitDiagnostic(
                    "dummy_video_loop_seek_incomplete",
                    level: "warning"
                )
            }
        }
    }

    @objc private func playerItemFailedToPlayToEnd(notification: Notification) {
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
        emitDiagnostic(
            "player_item_failed_to_end",
            level: "error",
            details: errorDetails(error)
        )
    }

    @objc private func playerItemNewErrorLogEntry(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              let event = item.errorLog()?.events.last else { return }
        emitDiagnostic(
            "player_item_error_log",
            level: "warning",
            details: [
                "statusCode": event.errorStatusCode,
                "domain": event.errorDomain,
                "comment": event.errorComment ?? "",
            ]
        )
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "show":
            let args = call.arguments as? [String: Any]
            updateRenderMetrics(for: hostView)
            currentText = args?["text"] as? String ?? "Lyrics"
            applyStyleArguments(args)
            rebuildRenderedFrame()
            show(result: result)
        case "hide":
            hide()
            result(true)
        case "updateText":
            let args = call.arguments as? [String: Any]
            updateText(args?["text"] as? String ?? "")
            result(true)
        case "updateStyle":
            updateStyle(args: call.arguments as? [String: Any])
            result(true)
        case "setFPSEnabled":
            let args = call.arguments as? [String: Any]
            setFPSEnabled(args?["enabled"] as? Bool ?? false)
            result(true)
        case "setNetworkSpeedEnabled":
            let args = call.arguments as? [String: Any]
            setNetworkSpeedEnabled(args?["enabled"] as? Bool ?? false)
            result(true)
        case "hasPermission", "requestPermission":
            result(pipController != nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func show(result: @escaping FlutterResult) {
        guard let pipController else {
            emitDiagnostic(
                "show_rejected",
                level: "error",
                details: ["reason": setupFailure ?? "pip_controller_unavailable"]
            )
            result(false)
            return
        }
        if !pipController.isPictureInPictureActive {
            stopRequestedByApp = false
            pictureInPictureStartUptime = nil
        }
        emitDiagnostic("render_metrics_selected", details: renderMetricsDetails())
        emitDiagnostic("show_requested", details: diagnosticSnapshot())
        if pipController.isPictureInPictureActive {
            emitDiagnostic("show_reused_active_pip", details: diagnosticSnapshot())
            result(true)
            return
        }

        stopSampleBufferHeartbeat()
        completePendingShow(false)
        pendingShowResult = result
        startGeneration += 1
        let generation = startGeneration
        resetCompositionDiagnostics()
        if sampleBufferDisplayLayer != nil {
            if let hostView {
                attachSampleBufferDisplayLayer(below: hostView)
            }
            enqueueCurrentSampleBuffer(reason: "show")
            emitDiagnostic("sample_buffer_show_requested", details: diagnosticSnapshot())
        } else {
            player?.play()
            emitDiagnostic("dummy_video_play_requested", details: diagnosticSnapshot())
        }
        startPendingPictureInPictureIfPossible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, generation == self.startGeneration,
                  self.pendingShowResult != nil else { return }
            self.emitDiagnostic(
                "pip_start_timeout",
                level: "error",
                details: self.diagnosticSnapshot()
            )
            self.stopSampleBufferHeartbeat()
            self.player?.pause()
            self.completePendingShow(false)
        }
    }

    private func startPendingPictureInPictureIfPossible() {
        guard pendingShowResult != nil, let pipController else { return }
        guard pipController.isPictureInPicturePossible else {
            emitDiagnostic("pip_start_waiting", details: diagnosticSnapshot())
            return
        }
        guard startRequestedGeneration != startGeneration else { return }
        startRequestedGeneration = startGeneration
        emitDiagnostic("pip_start_requested", details: diagnosticSnapshot())
        pipController.startPictureInPicture()
    }

    private func completePendingShow(_ success: Bool) {
        guard let result = pendingShowResult else { return }
        pendingShowResult = nil
        startRequestedGeneration = nil
        result(success)
    }

    private func hide() {
        stopRequestedByApp = true
        stopSampleBufferHeartbeat()
        emitDiagnostic("hide_requested", details: diagnosticSnapshot())
        startGeneration += 1
        completePendingShow(false)
        pipController?.stopPictureInPicture()
        player?.pause()
        stopMonitors()
    }

    private func setFPSEnabled(_ enabled: Bool) {
        showFPS = enabled
        currentFPS = nil
        if enabled, pipController?.isPictureInPictureActive == true {
            fpsMonitor.onFPSUpdate = { [weak self] fps in
                self?.updateFPS(fps)
            }
            fpsMonitor.start()
        } else if !enabled {
            fpsMonitor.stop()
        }
        rebuildRenderedFrame()
    }

    private func setNetworkSpeedEnabled(_ enabled: Bool) {
        showNetworkSpeed = enabled
        currentNetworkSpeed = nil
        if enabled, pipController?.isPictureInPictureActive == true {
            networkSpeedMonitor.onSpeedUpdate = { [weak self] speed in
                self?.updateNetworkSpeed(speed)
            }
            networkSpeedMonitor.start()
        } else if !enabled {
            networkSpeedMonitor.stop()
        }
        rebuildRenderedFrame()
    }

    private func startMonitorsIfNeeded() {
        if showFPS {
            fpsMonitor.onFPSUpdate = { [weak self] fps in
                self?.updateFPS(fps)
            }
            fpsMonitor.start()
        }
        if showNetworkSpeed {
            networkSpeedMonitor.onSpeedUpdate = { [weak self] speed in
                self?.updateNetworkSpeed(speed)
            }
            networkSpeedMonitor.start()
        }
    }

    private func stopMonitors() {
        fpsMonitor.stop()
        networkSpeedMonitor.stop()
    }

    private func updateFPS(_ fps: Int) {
        DispatchQueue.main.async {
            self.currentFPS = fps
            self.rebuildRenderedFrame()
        }
    }

    private func updateNetworkSpeed(_ speed: String) {
        DispatchQueue.main.async {
            self.currentNetworkSpeed = speed
            self.rebuildRenderedFrame()
        }
    }

    private func updateText(_ text: String) {
        DispatchQueue.main.async {
            self.currentText = text
            self.rebuildRenderedFrame()
        }
    }

    private func updateStyle(args: [String: Any]?) {
        guard let args else { return }
        DispatchQueue.main.async {
            self.applyStyleArguments(args)
            self.rebuildRenderedFrame()
        }
    }

    private func applyStyleArguments(_ args: [String: Any]?) {
        guard let args else { return }
        if let value = args["fontSize"] as? Double {
            lyricFontSize = CGFloat(value)
        }
        if let value = args["textColor"] as? Int {
            lyricTextColor = colorFromInt(value)
            infoTextColor = lyricTextColor
        }
        if let value = args["backgroundColor"] as? Int {
            lyricBackgroundColor = colorFromInt(value)
        }
        if let value = args["cornerRadius"] as? Double {
            lyricCornerRadius = CGFloat(value)
        }
        if let value = args["paddingHorizontal"] as? Double {
            lyricPaddingHorizontal = CGFloat(value)
        }
        if let value = args["paddingVertical"] as? Double {
            lyricPaddingVertical = CGFloat(value)
        }
    }

    private func colorFromInt(_ argb: Int) -> UIColor {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255
        let red = CGFloat((argb >> 16) & 0xFF) / 255
        let green = CGFloat((argb >> 8) & 0xFF) / 255
        let blue = CGFloat(argb & 0xFF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func emitDiagnostic(
        _ event: String,
        level: String = "info",
        details: [String: Any] = [:]
    ) {
        let arguments: [String: Any] = [
            "event": event,
            "level": level,
            "details": details,
        ]
        let send = { [weak self] in
            self?.channel.invokeMethod("onDiagnostic", arguments: arguments)
        }
        if Thread.isMainThread {
            send()
        } else {
            DispatchQueue.main.async {
                send()
            }
        }
    }

    private func diagnosticSnapshot() -> [String: Any] {
        renderedFrameLock.lock()
        let frameCount = compositionFrameCount
        let renderGeneration = renderedFrameGeneration
        renderedFrameLock.unlock()

        let usesSampleBuffer = sampleBufferDisplayLayer != nil
        var details: [String: Any] = [
            "pipeline": usesSampleBuffer
                ? "sample_buffer_display_layer"
                : "legacy_av_player_layer_video_composition",
            "systemVersion": UIDevice.current.systemVersion,
            "pipSupported": AVPictureInPictureController.isPictureInPictureSupported(),
            "pipPossible": pipController?.isPictureInPicturePossible ?? false,
            "pipActive": pipController?.isPictureInPictureActive ?? false,
            "pipSuspended": pipController?.isPictureInPictureSuspended ?? false,
            "playerItemStatus": playerItemStatusDescription(player?.currentItem?.status),
            "playerTimeControlStatus": playerTimeControlStatusDescription(),
            "playerLayerReady": playerLayer?.isReadyForDisplay ?? false,
            "compositionFrameCount": frameCount,
            "sampleBufferEnqueueCount": sampleBufferEnqueueCount,
            "sampleBufferHeartbeatIntervalMilliseconds": Int(
                sampleBufferHeartbeatInterval * 1000
            ),
            "sampleBufferHeartbeatRunning": sampleBufferHeartbeatTimer != nil,
            "sampleBufferHeartbeatEnqueueCount": sampleBufferHeartbeatEnqueueCount,
            "sampleBufferMaximumEnqueueGapMilliseconds":
                sampleBufferMaximumEnqueueGapMilliseconds,
            "sampleBufferCreationFailureCount": sampleBufferCreationFailureCount,
            "sampleBufferNonMonotonicTimestampCount":
                sampleBufferNonMonotonicTimestampCount,
            "stopRequestedByApp": stopRequestedByApp,
            "renderGeneration": renderGeneration,
            "renderWidth": Int(renderSize.width),
            "renderHeight": Int(renderSize.height),
            "renderScale": Double(renderScale),
            "outputFrameRate": outputFrameRate,
            "windowLogicalWidth": Double(renderInputLogicalWidth),
            "screenNativeScale": Double(renderInputNativeScale),
            "textLength": currentText.count,
            "applicationState": applicationStateDescription(
                UIApplication.shared.applicationState
            ),
            "lowPowerModeEnabled": ProcessInfo.processInfo.isLowPowerModeEnabled,
        ]
        if let sampleBufferLastCreationFailureStage {
            details["sampleBufferLastCreationFailureStage"] =
                sampleBufferLastCreationFailureStage
        }
        if let sampleBufferLastCreationFailureStatus {
            details["sampleBufferLastCreationFailureStatus"] =
                Int(sampleBufferLastCreationFailureStatus)
        }
        if let lastEnqueueUptime = sampleBufferLastEnqueueUptime {
            details["sampleBufferMillisecondsSinceLastEnqueue"] = Int(
                max(0, ProcessInfo.processInfo.systemUptime - lastEnqueueUptime) * 1000
            )
        }
        if let pictureInPictureStartUptime {
            details["pipActiveDurationMilliseconds"] = Int(
                max(0, ProcessInfo.processInfo.systemUptime - pictureInPictureStartUptime)
                    * 1000
            )
        }
        let audioSession = AVAudioSession.sharedInstance()
        details["audioSessionCategory"] = audioSession.category.rawValue
        details["audioSessionMode"] = audioSession.mode.rawValue
        details["audioSessionOtherAudioPlaying"] = audioSession.isOtherAudioPlaying
        if let sampleBufferDisplayLayer {
            if #available(iOS 17.0, *) {
                details["sampleBufferQueueApi"] = "AVSampleBufferVideoRenderer"
            } else {
                details["sampleBufferQueueApi"] = "AVSampleBufferDisplayLayer"
            }
            sampleBufferDetails(sampleBufferDisplayLayer).forEach {
                details[$0.key] = $0.value
            }
        }
        if let error = player?.currentItem?.error as NSError? {
            details["playerItemErrorDomain"] = error.domain
            details["playerItemErrorCode"] = error.code
            details["playerItemError"] = error.localizedDescription
        }
        if let error = player?.error as NSError? {
            details["playerErrorDomain"] = error.domain
            details["playerErrorCode"] = error.code
            details["playerError"] = error.localizedDescription
        }
        return details
    }

    private func applicationStateDescription(_ state: UIApplication.State) -> String {
        switch state {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unrecognized"
        }
    }

    private func sampleBufferDetails(
        _ displayLayer: AVSampleBufferDisplayLayer
    ) -> [String: Any] {
        var details: [String: Any] = [
            "sampleBufferStatus": sampleBufferStatusDescription(
                sampleBufferStatus(for: displayLayer)
            ),
            "sampleBufferLayerWidth": Double(displayLayer.bounds.width),
            "sampleBufferLayerHeight": Double(displayLayer.bounds.height),
            "sampleBufferLayerAttached": displayLayer.superlayer != nil,
            "sampleBufferLayerMatchesLogicalFrameSize":
                displayLayer.bounds.size == logicalFrameSize,
        ]
        if #available(iOS 17.4, *) {
            details["sampleBufferReadyForDisplay"] = displayLayer.isReadyForDisplay
        } else {
            details["sampleBufferReadyForDisplay"] = "unavailable_before_iOS_17_4"
        }
        if let error = sampleBufferError(for: displayLayer) {
            details["sampleBufferErrorDomain"] = error.domain
            details["sampleBufferErrorCode"] = error.code
            details["sampleBufferError"] = error.localizedDescription
        }
        details["sampleBufferRequiresFlushToResumeDecoding"] =
            sampleBufferRequiresFlushToResumeDecoding(for: displayLayer)
        return details
    }

    private func sampleBufferStatus(
        for displayLayer: AVSampleBufferDisplayLayer
    ) -> AVQueuedSampleBufferRenderingStatus {
        if #available(iOS 17.0, *) {
            return displayLayer.sampleBufferRenderer.status
        }
        return displayLayer.status
    }

    private func sampleBufferError(
        for displayLayer: AVSampleBufferDisplayLayer
    ) -> NSError? {
        if #available(iOS 17.0, *) {
            if let error = displayLayer.sampleBufferRenderer.error {
                return error as NSError
            }
            return nil
        }
        if let error = displayLayer.error {
            return error as NSError
        }
        return nil
    }

    private func sampleBufferRequiresFlushToResumeDecoding(
        for displayLayer: AVSampleBufferDisplayLayer
    ) -> Bool {
        if #available(iOS 17.0, *) {
            return displayLayer.sampleBufferRenderer.requiresFlushToResumeDecoding
        }
        if #available(iOS 14.0, *) {
            return displayLayer.requiresFlushToResumeDecoding
        }
        return false
    }

    private func sampleBufferStatusDescription(
        _ status: AVQueuedSampleBufferRenderingStatus
    ) -> String {
        switch status {
        case .unknown:
            return "unknown"
        case .rendering:
            return "rendering"
        case .failed:
            return "failed"
        @unknown default:
            return "unrecognized"
        }
    }

    private func renderMetricsDetails() -> [String: Any] {
        [
            "logicalFrameWidth": Int(logicalFrameSize.width),
            "logicalFrameHeight": Int(logicalFrameSize.height),
            "windowLogicalWidth": Double(renderInputLogicalWidth),
            "screenNativeScale": Double(renderInputNativeScale),
            "renderScale": Double(renderScale),
            "renderWidth": Int(renderSize.width),
            "renderHeight": Int(renderSize.height),
            "outputFrameRate": outputFrameRate,
        ]
    }

    private func playerItemStatusDescription(_ status: AVPlayerItem.Status?) -> String {
        switch status {
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        case .unknown:
            return "unknown"
        case nil:
            return "missing"
        @unknown default:
            return "unrecognized"
        }
    }

    private func playerTimeControlStatusDescription() -> String {
        guard let player else { return "missing" }
        switch player.timeControlStatus {
        case .paused:
            return "paused"
        case .waitingToPlayAtSpecifiedRate:
            return "waiting"
        case .playing:
            return "playing"
        @unknown default:
            return "unrecognized"
        }
    }

    private func errorDetails(_ error: Error?) -> [String: Any] {
        guard let error = error as NSError? else {
            return ["error": "missing_error_details"]
        }
        return [
            "error": error.localizedDescription,
            "domain": error.domain,
            "code": error.code,
        ]
    }

    private func recordCompositionFrame(sourceSize: CGSize, outputSize: CGSize) {
        renderedFrameLock.lock()
        compositionFrameCount += 1
        let frameCount = compositionFrameCount
        let shouldLog = !didLogFirstCompositionFrame
        didLogFirstCompositionFrame = true
        renderedFrameLock.unlock()

        guard shouldLog else { return }
        emitDiagnostic(
            "video_compositor_first_frame",
            details: [
                "compositionFrameCount": frameCount,
                "sourceWidth": Int(sourceSize.width),
                "sourceHeight": Int(sourceSize.height),
                "outputWidth": Int(outputSize.width),
                "outputHeight": Int(outputSize.height),
            ]
        )
    }

    private func resetCompositionDiagnostics() {
        renderedFrameLock.lock()
        compositionFrameCount = 0
        didLogFirstCompositionFrame = false
        renderedFrameLock.unlock()
        sampleBufferEnqueueCount = 0
        sampleBufferHeartbeatEnqueueCount = 0
        sampleBufferLastEnqueueUptime = nil
        sampleBufferMaximumEnqueueGapMilliseconds = 0
        sampleBufferCreationFailureCount = 0
        didLogSampleBufferCreationFailure = false
        sampleBufferLastCreationFailureStage = nil
        sampleBufferLastCreationFailureStatus = nil
        didLogSampleBufferFlushAfterFailure = false
        didAttemptSampleBufferFailureReset = false
        didLogSampleBufferResetFailure = false
        sampleBufferResetInProgress = false
        didLogSampleBufferFrameContent = false
        sampleBufferFrameContentDetails = nil
        sampleBufferLastPresentationTime = nil
        sampleBufferNonMonotonicTimestampCount = 0
    }

    private func schedulePictureInPictureHealthCheck(after delay: TimeInterval) {
        let generation = startGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, generation == self.startGeneration,
                  self.pipController?.isPictureInPictureActive == true else { return }
            let snapshot = self.diagnosticSnapshot()
            let issue: String
            if let displayLayer = self.sampleBufferDisplayLayer {
                if self.sampleBufferStatus(for: displayLayer) == .failed {
                    issue = "sample_buffer_failed"
                } else if self.sampleBufferEnqueueCount == 0 {
                    issue = "sample_buffer_no_enqueued_frame"
                } else if self.sampleBufferCreationFailureCount > 0 {
                    issue = "sample_buffer_creation_failed"
                } else if let lastEnqueueUptime = self.sampleBufferLastEnqueueUptime,
                          ProcessInfo.processInfo.systemUptime - lastEnqueueUptime
                              > self.sampleBufferHeartbeatInterval * 3 {
                    issue = "sample_buffer_cadence_stalled"
                } else if #available(iOS 17.4, *),
                          !displayLayer.isReadyForDisplay {
                    issue = "sample_buffer_no_display_frame"
                } else {
                    issue = "pipeline_reports_ready"
                }
            } else {
                let status = self.player?.currentItem?.status
                let frameCount = snapshot["compositionFrameCount"] as? Int ?? 0
                let layerReady = self.playerLayer?.isReadyForDisplay == true
                if status == .failed {
                    issue = "player_item_failed"
                } else if status != .readyToPlay {
                    issue = "player_item_not_ready"
                } else if frameCount == 0 {
                    issue = "video_compositor_no_output"
                } else if !layerReady {
                    issue = "player_layer_no_display_frame"
                } else {
                    issue = "pipeline_reports_ready"
                }
            }
            var details = snapshot
            details["health"] = issue
            details["delayMilliseconds"] = Int(delay * 1000)
            self.emitDiagnostic(
                "pip_health_check",
                level: issue == "pipeline_reports_ready" ? "info" : "warning",
                details: details
            )
        }
    }

    private func rebuildRenderedFrame() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        let image = renderer.image { context in
            let bounds = CGRect(origin: .zero, size: renderSize)
            UIColor.black.setFill()
            context.fill(bounds)

            lyricBackgroundColor.setFill()
            let backgroundPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: lyricCornerRadius * renderScale
            )
            backgroundPath.fill()

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(
                    ofSize: lyricFontSize * renderScale,
                    weight: .medium
                ),
                .foregroundColor: lyricTextColor,
                .paragraphStyle: paragraphStyle,
            ]
            let horizontalInset = lyricPaddingHorizontal * renderScale
            let verticalInset = lyricPaddingVertical * renderScale
            var textBounds = bounds.insetBy(
                dx: horizontalInset,
                dy: verticalInset
            )
            if showFPS || showNetworkSpeed {
                textBounds.size.height = max(0, textBounds.height - 24)
            }
            let attributedText = NSAttributedString(
                string: currentText,
                attributes: attributes
            )
            let measured = attributedText.boundingRect(
                with: textBounds.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            let drawHeight = min(textBounds.height, ceil(measured.height))
            let drawRect = CGRect(
                x: textBounds.minX,
                y: textBounds.midY - drawHeight / 2,
                width: textBounds.width,
                height: drawHeight
            )
            attributedText.draw(
                with: drawRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )

            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(
                    ofSize: 10 * renderScale,
                    weight: .medium
                ),
                .foregroundColor: infoTextColor.withAlphaComponent(0.8),
            ]
            let infoY = renderSize.height - (18 * renderScale)
            if showFPS, let currentFPS {
                NSString(string: "\(currentFPS) FPS").draw(
                    in: CGRect(
                        x: 4 * renderScale,
                        y: infoY,
                        width: 60 * renderScale,
                        height: 14 * renderScale
                    ),
                    withAttributes: infoAttributes
                )
            }
            if showNetworkSpeed, let currentNetworkSpeed {
                let width = 150 * renderScale
                let speedParagraphStyle = NSMutableParagraphStyle()
                speedParagraphStyle.alignment = .right
                var speedAttributes = infoAttributes
                speedAttributes[.paragraphStyle] = speedParagraphStyle
                NSString(string: currentNetworkSpeed).draw(
                    in: CGRect(
                        x: renderSize.width - width - (4 * renderScale),
                        y: infoY,
                        width: width,
                        height: 14 * renderScale
                    ),
                    withAttributes: speedAttributes
                )
            }
        }
        guard let cgImage = image.cgImage else { return }
        renderedFrameLock.lock()
        renderedFrame = cgImage
        renderedCIImage = CIImage(cgImage: cgImage)
        renderedFrameGeneration += 1
        let generation = renderedFrameGeneration
        renderedFrameLock.unlock()
        enqueueCurrentSampleBuffer(reason: "render_\(generation)")
    }

    private func currentRenderedCIImage() -> CIImage? {
        renderedFrameLock.lock()
        defer { renderedFrameLock.unlock() }
        return renderedCIImage
    }

    private func currentRenderedFrame() -> (image: CGImage, generation: Int)? {
        renderedFrameLock.lock()
        defer { renderedFrameLock.unlock() }
        guard let renderedFrame else { return nil }
        return (renderedFrame, renderedFrameGeneration)
    }

    fileprivate func refreshSampleBufferFrame() {
        DispatchQueue.main.async {
            self.enqueueCurrentSampleBuffer(reason: "pip_refresh")
        }
    }

    private func startSampleBufferHeartbeat() {
        guard sampleBufferDisplayLayer != nil,
              sampleBufferHeartbeatTimer == nil else { return }
        enqueueCurrentSampleBuffer(reason: "heartbeat_start")
        let timer = Timer(
            timeInterval: sampleBufferHeartbeatInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self,
                  self.pipController?.isPictureInPictureActive == true
                    || self.pendingShowResult != nil else { return }
            self.enqueueCurrentSampleBuffer(reason: "heartbeat")
        }
        timer.tolerance = sampleBufferHeartbeatInterval * 0.2
        RunLoop.main.add(timer, forMode: .common)
        sampleBufferHeartbeatTimer = timer
    }

    private func stopSampleBufferHeartbeat() {
        sampleBufferHeartbeatTimer?.invalidate()
        sampleBufferHeartbeatTimer = nil
    }

    private func enqueueCurrentSampleBuffer(
        reason: String,
        afterFailureReset: Bool = false
    ) {
        guard #available(iOS 15.0, *),
              let displayLayer = sampleBufferDisplayLayer,
              let frame = currentRenderedFrame() else { return }
        guard !sampleBufferResetInProgress || afterFailureReset else { return }

        if sampleBufferStatus(for: displayLayer) != .failed {
            didAttemptSampleBufferFailureReset = false
        }
        if sampleBufferStatus(for: displayLayer) == .failed, !afterFailureReset {
            guard !didAttemptSampleBufferFailureReset else { return }
            didAttemptSampleBufferFailureReset = true
            if !didLogSampleBufferFlushAfterFailure {
                didLogSampleBufferFlushAfterFailure = true
                emitDiagnostic(
                    "sample_buffer_flush_after_failure",
                    level: "warning",
                    details: sampleBufferDetails(displayLayer)
                )
            }
            resetSampleBufferRendererAfterFailure(displayLayer) { [weak self] in
                self?.enqueueCurrentSampleBuffer(
                    reason: reason,
                    afterFailureReset: true
                )
            }
            return
        }
        if sampleBufferStatus(for: displayLayer) == .failed {
            if !didLogSampleBufferResetFailure {
                didLogSampleBufferResetFailure = true
                emitDiagnostic(
                    "sample_buffer_reset_failed",
                    level: "error",
                    details: sampleBufferDetails(displayLayer)
                )
            }
            return
        }

        guard let sampleBuffer = makeImmediateSampleBuffer(
            from: frame.image,
            generation: frame.generation
        ) else {
            sampleBufferCreationFailureCount += 1
            if !didLogSampleBufferCreationFailure {
                didLogSampleBufferCreationFailure = true
                var details: [String: Any] = [
                    "reason": reason,
                    "imageWidth": frame.image.width,
                    "imageHeight": frame.image.height,
                    "failureStage": sampleBufferLastCreationFailureStage ?? "unknown",
                ]
                if let sampleBufferLastCreationFailureStatus {
                    details["failureStatus"] = Int(sampleBufferLastCreationFailureStatus)
                }
                emitDiagnostic(
                    "sample_buffer_creation_failed",
                    level: "error",
                    details: details
                )
            }
            return
        }

        if #available(iOS 17.0, *) {
            displayLayer.sampleBufferRenderer.enqueue(sampleBuffer)
        } else {
            displayLayer.enqueue(sampleBuffer)
        }
        let now = ProcessInfo.processInfo.systemUptime
        if let lastEnqueueUptime = sampleBufferLastEnqueueUptime {
            sampleBufferMaximumEnqueueGapMilliseconds = max(
                sampleBufferMaximumEnqueueGapMilliseconds,
                Int(max(0, now - lastEnqueueUptime) * 1000)
            )
        }
        sampleBufferLastEnqueueUptime = now
        sampleBufferEnqueueCount += 1
        if reason == "heartbeat" {
            sampleBufferHeartbeatEnqueueCount += 1
        }
        if sampleBufferEnqueueCount == 1 {
            var details = sampleBufferDetails(displayLayer)
            details["reason"] = reason
            details["imageWidth"] = frame.image.width
            details["imageHeight"] = frame.image.height
            if let sampleBufferFrameContentDetails {
                details["frameContent"] = sampleBufferFrameContentDetails
            }
            emitDiagnostic("sample_buffer_frame_enqueued", details: details)
        }
    }

    @available(iOS 15.0, *)
    private func resetSampleBufferRendererAfterFailure(
        _ displayLayer: AVSampleBufferDisplayLayer,
        completion: @escaping () -> Void
    ) {
        sampleBufferLastPresentationTime = nil
        sampleBufferResetInProgress = true
        if #available(iOS 17.0, *) {
            displayLayer.sampleBufferRenderer.flush(
                removingDisplayedImage: true,
                completionHandler: {
                    DispatchQueue.main.async {
                        self.sampleBufferResetInProgress = false
                        completion()
                    }
                }
            )
        } else {
            displayLayer.flushAndRemoveImage()
            if displayLayer.status == .failed {
                displayLayer.flush()
            }
            sampleBufferResetInProgress = false
            completion()
        }
    }

    @available(iOS 15.0, *)
    private func makeImmediateSampleBuffer(
        from image: CGImage,
        generation: Int
    ) -> CMSampleBuffer? {
        let pixelBuffer: CVPixelBuffer
        let formatDescription: CMVideoFormatDescription
        if sampleBufferFrameGeneration == generation,
           let cachedPixelBuffer = sampleBufferPixelBuffer,
           let cachedFormatDescription = sampleBufferFormatDescription {
            pixelBuffer = cachedPixelBuffer
            formatDescription = cachedFormatDescription
        } else {
            var newPixelBuffer: CVPixelBuffer?
            let attributes: [CFString: Any] = [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true,
                kCVPixelBufferIOSurfacePropertiesKey: [:],
            ]
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                image.width,
                image.height,
                kCVPixelFormatType_32BGRA,
                attributes as CFDictionary,
                &newPixelBuffer
            )
            guard status == kCVReturnSuccess else {
                recordSampleBufferCreationFailure(
                    stage: "CVPixelBufferCreate",
                    status: status
                )
                return nil
            }
            guard let newPixelBuffer else {
                recordSampleBufferCreationFailure(stage: "pixel_buffer_missing")
                return nil
            }

            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
                ?? CGColorSpaceCreateDeviceRGB()
            CVBufferSetAttachment(
                newPixelBuffer,
                kCVImageBufferCGColorSpaceKey,
                colorSpace,
                .shouldPropagate
            )
            CVBufferSetAttachment(
                newPixelBuffer,
                kCVImageBufferAlphaChannelIsOpaque,
                kCFBooleanTrue,
                .shouldPropagate
            )
            ciContext.render(
                CIImage(cgImage: image),
                to: newPixelBuffer,
                bounds: CGRect(x: 0, y: 0, width: image.width, height: image.height),
                colorSpace: colorSpace
            )

            var newFormatDescription: CMVideoFormatDescription?
            let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: newPixelBuffer,
                formatDescriptionOut: &newFormatDescription
            )
            guard formatStatus == noErr else {
                recordSampleBufferCreationFailure(
                    stage: "CMVideoFormatDescriptionCreateForImageBuffer",
                    status: formatStatus
                )
                return nil
            }
            guard let newFormatDescription else {
                recordSampleBufferCreationFailure(
                    stage: "format_description_missing"
                )
                return nil
            }
            sampleBufferPixelBuffer = newPixelBuffer
            sampleBufferFormatDescription = newFormatDescription
            sampleBufferFrameGeneration = generation
            pixelBuffer = newPixelBuffer
            formatDescription = newFormatDescription
        }

        emitSampleBufferFrameContentDiagnosticIfNeeded(pixelBuffer)

        let hostTime = CMClockGetTime(CMClockGetHostTimeClock())
        let presentationTime: CMTime
        if let lastPresentationTime = sampleBufferLastPresentationTime,
           CMTimeCompare(hostTime, lastPresentationTime) <= 0 {
            presentationTime = CMTimeAdd(
                lastPresentationTime,
                CMTime(value: 1, timescale: 600)
            )
            sampleBufferNonMonotonicTimestampCount += 1
        } else {
            presentationTime = hostTime
        }
        sampleBufferLastPresentationTime = presentationTime
        var timing = CMSampleTimingInfo(
            duration: CMTime(
                seconds: sampleBufferHeartbeatInterval,
                preferredTimescale: 600
            ),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        let sampleBufferStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard sampleBufferStatus == noErr else {
            recordSampleBufferCreationFailure(
                stage: "CMSampleBufferCreateForImageBuffer",
                status: sampleBufferStatus
            )
            return nil
        }
        guard let sampleBuffer else {
            recordSampleBufferCreationFailure(stage: "sample_buffer_missing")
            return nil
        }

        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: true
        ), CFArrayGetCount(attachments) > 0 else {
            recordSampleBufferCreationFailure(stage: "sample_attachments_missing")
            return nil
        }
        let attachment = unsafeBitCast(
            CFArrayGetValueAtIndex(attachments, 0),
            to: CFMutableDictionary.self
        )
        CFDictionarySetValue(
            attachment,
            Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
            Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
        )
        return sampleBuffer
    }

    private func recordSampleBufferCreationFailure(
        stage: String,
        status: OSStatus? = nil
    ) {
        sampleBufferLastCreationFailureStage = stage
        sampleBufferLastCreationFailureStatus = status
    }

    private func emitSampleBufferFrameContentDiagnosticIfNeeded(
        _ pixelBuffer: CVPixelBuffer
    ) {
        guard !didLogSampleBufferFrameContent else { return }
        didLogSampleBufferFrameContent = true

        let lockStatus = CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        guard lockStatus == kCVReturnSuccess else {
            emitDiagnostic(
                "sample_buffer_frame_content_unavailable",
                level: "warning",
                details: ["pixelBufferLockStatus": lockStatus]
            )
            return
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            emitDiagnostic(
                "sample_buffer_frame_content_unavailable",
                level: "warning",
                details: ["reason": "missing_base_address"]
            )
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        var sampledPixelCount = 0
        var nonBlackPixelCount = 0
        var maximumRGB = 0
        var minimumAlpha = 255

        for yStep in 1...4 {
            let y = min(height - 1, height * yStep / 5)
            for xStep in 1...8 {
                let x = min(width - 1, width * xStep / 9)
                let offset = y * bytesPerRow + x * 4
                let blue = Int(bytes[offset])
                let green = Int(bytes[offset + 1])
                let red = Int(bytes[offset + 2])
                let alpha = Int(bytes[offset + 3])
                let brightestComponent = max(red, green, blue)
                sampledPixelCount += 1
                maximumRGB = max(maximumRGB, brightestComponent)
                minimumAlpha = min(minimumAlpha, alpha)
                if brightestComponent > 8 {
                    nonBlackPixelCount += 1
                }
            }
        }

        let details: [String: Any] = [
            "pixelFormat": CVPixelBufferGetPixelFormatType(pixelBuffer),
            "pixelWidth": width,
            "pixelHeight": height,
            "sampledPixelCount": sampledPixelCount,
            "nonBlackPixelCount": nonBlackPixelCount,
            "maximumRGB": maximumRGB,
            "minimumAlpha": minimumAlpha,
            "hasColorSpace": CVBufferGetAttachment(
                pixelBuffer,
                kCVImageBufferCGColorSpaceKey,
                nil
            ) != nil,
            "alphaMarkedOpaque": CVBufferGetAttachment(
                pixelBuffer,
                kCVImageBufferAlphaChannelIsOpaque,
                nil
            ) != nil,
        ]
        sampleBufferFrameContentDetails = details
        emitDiagnostic("sample_buffer_frame_content", details: details)
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        startSampleBufferHeartbeat()
        emitDiagnostic("pip_will_start", details: diagnosticSnapshot())
        refreshSampleBufferFrame()
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        pictureInPictureStartUptime = ProcessInfo.processInfo.systemUptime
        startSampleBufferHeartbeat()
        emitDiagnostic("pip_did_start", details: diagnosticSnapshot())
        refreshSampleBufferFrame()
        completePendingShow(true)
        startMonitorsIfNeeded()
        schedulePictureInPictureHealthCheck(after: 0.5)
        schedulePictureInPictureHealthCheck(after: 2)
        schedulePictureInPictureHealthCheck(after: 10)
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        emitDiagnostic("pip_did_stop", details: diagnosticSnapshot())
        stopSampleBufferHeartbeat()
        pictureInPictureStartUptime = nil
        startGeneration += 1
        completePendingShow(false)
        stopMonitors()
        player?.pause()
        channel.invokeMethod("onClose", arguments: nil)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        var details = diagnosticSnapshot()
        errorDetails(error).forEach { details[$0.key] = $0.value }
        emitDiagnostic("pip_failed_to_start", level: "error", details: details)
        stopSampleBufferHeartbeat()
        pictureInPictureStartUptime = nil
        startGeneration += 1
        completePendingShow(false)
        stopMonitors()
        player?.pause()
    }
}
