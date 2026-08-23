import Flutter
import UIKit
import AVKit
import CoreImage
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
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
        manager?.setPictureInPicturePlaybackActive(playing)
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
        manager?.refreshPictureInPictureFrame()
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
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private var sampleBufferPlaybackDelegate: AnyObject?
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
    private let renderSize = CGSize(width: 828, height: 208)
    private let renderScale: CGFloat = 2
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private let renderedFrameLock = NSLock()
    private var renderedFrame: CGImage?
    private var renderedCIImage: CIImage?
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

        rebuildRenderedFrame()
        setupPictureInPicture(in: controller.view)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupPictureInPicture(in view: UIView) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
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
        displayLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        displayLayer.opacity = 0.01
        displayLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(displayLayer)
        sampleBufferDisplayLayer = displayLayer

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
        observePictureInPicturePossibility()
        enqueueCurrentSampleBuffer()
    }

    private func setupLegacyPictureInPicture(in view: UIView) {
        guard let data = Data(base64Encoded: dummyVideoBase64) else { return }
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pip_video.mp4")
        try? data.write(to: fileURL)

        let asset = AVURLAsset(url: fileURL)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 0
        item.videoComposition = AVVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler: { [weak self] request in
                guard let self, let overlay = self.currentRenderedCIImage() else {
                    request.finish(with: request.sourceImage, context: nil)
                    return
                }
                let sourceExtent = request.sourceImage.extent
                let scale = CGAffineTransform(
                    scaleX: sourceExtent.width / overlay.extent.width,
                    y: sourceExtent.height / overlay.extent.height
                )
                let output = overlay.transformed(by: scale).cropped(to: sourceExtent)
                request.finish(with: output, context: nil)
            }
        )
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

        let layer = AVPlayerLayer(player: player)
        layer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        layer.opacity = 0.01
        view.layer.addSublayer(layer)
        playerLayer = layer
        pipController = AVPictureInPictureController(playerLayer: layer)
        pipController?.delegate = self
        pipController?.setValue(1, forKey: "controlsStyle")
        observePictureInPicturePossibility()
    }

    private func observePictureInPicturePossibility() {
        pipPossibleObservation = pipController?.observe(
            \.isPictureInPicturePossible,
            options: [.new]
        ) { [weak self] _, change in
            guard change.newValue == true else { return }
            DispatchQueue.main.async {
                self?.startPendingPictureInPictureIfPossible()
            }
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero, completionHandler: nil)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "show":
            let args = call.arguments as? [String: Any]
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
            result(false)
            return
        }
        if pipController.isPictureInPictureActive {
            result(true)
            return
        }

        completePendingShow(false)
        pendingShowResult = result
        startGeneration += 1
        let generation = startGeneration
        player?.play()
        enqueueCurrentSampleBufferIfAvailable()
        startPendingPictureInPictureIfPossible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, generation == self.startGeneration,
                  self.pendingShowResult != nil else { return }
            self.player?.pause()
            self.completePendingShow(false)
        }
    }

    private func startPendingPictureInPictureIfPossible() {
        guard pendingShowResult != nil, let pipController,
              pipController.isPictureInPicturePossible,
              startRequestedGeneration != startGeneration else { return }
        startRequestedGeneration = startGeneration
        pipController.startPictureInPicture()
    }

    private func completePendingShow(_ success: Bool) {
        guard let result = pendingShowResult else { return }
        pendingShowResult = nil
        startRequestedGeneration = nil
        result(success)
    }

    private func hide() {
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
        renderedFrameLock.unlock()
        enqueueCurrentSampleBufferIfAvailable()
    }

    private func currentRenderedCIImage() -> CIImage? {
        renderedFrameLock.lock()
        defer { renderedFrameLock.unlock() }
        return renderedCIImage
    }

    private func currentRenderedFrame() -> CGImage? {
        renderedFrameLock.lock()
        defer { renderedFrameLock.unlock() }
        return renderedFrame
    }

    private func enqueueCurrentSampleBufferIfAvailable() {
        guard #available(iOS 15.0, *), sampleBufferDisplayLayer != nil else {
            return
        }
        enqueueCurrentSampleBuffer()
    }

    @available(iOS 15.0, *)
    private func enqueueCurrentSampleBuffer() {
        guard let displayLayer = sampleBufferDisplayLayer,
              let image = currentRenderedFrame(),
              let sampleBuffer = makeSampleBuffer(from: image) else { return }
        if displayLayer.status == .failed {
            displayLayer.flush()
        }
        displayLayer.enqueue(sampleBuffer)
    }

    @available(iOS 15.0, *)
    private func makeSampleBuffer(from image: CGImage) -> CMSampleBuffer? {
        var pixelBuffer: CVPixelBuffer?
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
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        ciContext.render(
            CIImage(cgImage: image),
            to: pixelBuffer,
            bounds: CGRect(x: 0, y: 0, width: image.width, height: image.height),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        var formatDescription: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        ) == noErr, let formatDescription else { return nil }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        ) == noErr, let sampleBuffer else { return nil }
        CMSetAttachment(
            sampleBuffer,
            key: kCMSampleAttachmentKey_DisplayImmediately,
            value: kCFBooleanTrue,
            attachmentMode: kCMAttachmentMode_ShouldNotPropagate
        )
        return sampleBuffer
    }

    fileprivate func setPictureInPicturePlaybackActive(_ active: Bool) {
        if active {
            refreshPictureInPictureFrame()
        }
    }

    fileprivate func refreshPictureInPictureFrame() {
        DispatchQueue.main.async {
            self.rebuildRenderedFrame()
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        completePendingShow(true)
        startMonitorsIfNeeded()
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
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
        print("Floating lyric PiP failed: \(error)")
        startGeneration += 1
        completePendingShow(false)
        stopMonitors()
        player?.pause()
    }
}
