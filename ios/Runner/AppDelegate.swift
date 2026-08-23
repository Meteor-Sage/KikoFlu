import Flutter
import UIKit
import AVKit
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

class FloatingLyricManager: NSObject, AVPictureInPictureControllerDelegate {
    private var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var lyricView: UILabel?
    private var fpsLabel: UILabel?
    private var networkSpeedLabel: UILabel?
    private var channel: FlutterMethodChannel
    
    private var fpsMonitor = FPSMonitor()
    private var networkSpeedMonitor = NetworkSpeedMonitor()
    private var showFPS: Bool = false
    private var showNetworkSpeed: Bool = false
    private weak var hostView: UIView?

    // iOS 15+ provides a supported PiP content view for custom UIKit content.
    // Older iOS versions keep the legacy AVPlayerLayer fallback below.
    private var pipVideoCallController: AnyObject?
    
    // Cached subtitle style for info labels (follows lyric style except font size)
    private var infoTextColor: UIColor = .white
    private var infoCornerRadius: CGFloat = 4
    
    // Base64 of a 1-second black MP4 video
    private let dummyVideoBase64 = "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"

    init(controller: FlutterViewController) {
        channel = FlutterMethodChannel(name: "com.kikoeru.flutter/floating_lyric", binaryMessenger: controller.binaryMessenger)
        super.init()
        hostView = controller.view
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
        
        setupPlayer(in: controller.view)
    }
    
    private func setupPlayer(in view: UIView) {
        prepareLyricView(text: "♪ - ♪")

        if #available(iOS 15.0, *) {
            setupModernPictureInPicture(in: view)
            return
        }

        setupLegacyPictureInPicture(in: view)
    }

    @available(iOS 15.0, *)
    private func setupModernPictureInPicture(in view: UIView) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("Floating lyric PiP is not supported on this device")
            return
        }

        let contentController = AVPictureInPictureVideoCallViewController()
        contentController.preferredContentSize = CGSize(width: 414, height: 104)
        contentController.view.backgroundColor = .black

        if let lyricView = lyricView {
            lyricView.translatesAutoresizingMaskIntoConstraints = false
            contentController.view.addSubview(lyricView)
            NSLayoutConstraint.activate([
                lyricView.leadingAnchor.constraint(equalTo: contentController.view.leadingAnchor),
                lyricView.trailingAnchor.constraint(equalTo: contentController.view.trailingAnchor),
                lyricView.topAnchor.constraint(equalTo: contentController.view.topAnchor),
                lyricView.bottomAnchor.constraint(equalTo: contentController.view.bottomAnchor),
            ])
        }

        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: view,
            contentViewController: contentController
        )
        pipVideoCallController = contentController
        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.delegate = self
    }

    private func setupLegacyPictureInPicture(in view: UIView) {
        guard let data = Data(base64Encoded: dummyVideoBase64) else { return }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("pip_video.mp4")
        try? data.write(to: fileURL)
        
        let playerItem = AVPlayerItem(url: fileURL)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true
        player?.allowsExternalPlayback = true
        // Important: prevent this player from pausing other audio
        if #available(iOS 10.0, *) {
            player?.automaticallyWaitsToMinimizeStalling = false
        }
        // Loop the video
        player?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(playerItemDidReachEnd(notification:)),
                                             name: .AVPlayerItemDidPlayToEndTime,
                                             object: player?.currentItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        playerLayer?.opacity = 0.01
        view.layer.addSublayer(playerLayer!)
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
            pipController?.delegate = self
            // Hide controls
            pipController?.setValue(1, forKey: "controlsStyle")
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "show":
            let args = call.arguments as? [String: Any]
            let text = args?["text"] as? String ?? "Lyrics"
            result(show(text: text, args: args))
        case "hide":
            hide()
            result(true)
        case "updateText":
            let args = call.arguments as? [String: Any]
            let text = args?["text"] as? String ?? ""
            updateText(text)
            result(true)
        case "updateStyle":
            let args = call.arguments as? [String: Any]
            updateStyle(args: args)
            result(true)
        case "setFPSEnabled":
            let args = call.arguments as? [String: Any]
            let enabled = args?["enabled"] as? Bool ?? false
            setFPSEnabled(enabled)
            result(true)
        case "setNetworkSpeedEnabled":
            let args = call.arguments as? [String: Any]
            let enabled = args?["enabled"] as? Bool ?? false
            setNetworkSpeedEnabled(enabled)
            result(true)
        case "hasPermission":
            result(true)
        case "requestPermission":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @discardableResult
    private func show(text: String, args: [String: Any]?) -> Bool {
        if pipController?.isPictureInPictureActive == true {
            updateText(text)
            updateStyle(args: args)
            return true
        }

        prepareLyricView(text: text)
        updateStyle(args: args)

        guard let pipController = pipController else {
            print("Floating lyric PiP is unavailable")
            return false
        }

        if #available(iOS 15.0, *), pipVideoCallController != nil {
            pipController.startPictureInPicture()
        } else {
            player?.play()
            pipController.startPictureInPicture()
        }
        return true
    }
    
    private func hide() {
        pipController?.stopPictureInPicture()
        player?.pause()
        stopMonitors()
    }
    
    private func setFPSEnabled(_ enabled: Bool) {
        showFPS = enabled
        if enabled {
            fpsMonitor.onFPSUpdate = { [weak self] fps in
                self?.updateFPSLabel(fps)
            }
            if pipController?.isPictureInPictureActive == true {
                fpsMonitor.start()
                ensureFPSLabel()
            }
        } else {
            fpsMonitor.stop()
            DispatchQueue.main.async {
                self.fpsLabel?.removeFromSuperview()
                self.fpsLabel = nil
            }
        }
    }
    
    private func setNetworkSpeedEnabled(_ enabled: Bool) {
        showNetworkSpeed = enabled
        if enabled {
            networkSpeedMonitor.onSpeedUpdate = { [weak self] speed in
                self?.updateNetworkSpeedLabel(speed)
            }
            if pipController?.isPictureInPictureActive == true {
                networkSpeedMonitor.start()
                ensureNetworkSpeedLabel()
            }
        } else {
            networkSpeedMonitor.stop()
            DispatchQueue.main.async {
                self.networkSpeedLabel?.removeFromSuperview()
                self.networkSpeedLabel = nil
            }
        }
    }
    
    private func stopMonitors() {
        fpsMonitor.stop()
        networkSpeedMonitor.stop()
    }
    
    private func startMonitorsIfNeeded() {
        if showFPS {
            fpsMonitor.onFPSUpdate = { [weak self] fps in
                self?.updateFPSLabel(fps)
            }
            fpsMonitor.start()
        }
        if showNetworkSpeed {
            networkSpeedMonitor.onSpeedUpdate = { [weak self] speed in
                self?.updateNetworkSpeedLabel(speed)
            }
            networkSpeedMonitor.start()
        }
    }
    
    private func ensureFPSLabel() {
        DispatchQueue.main.async {
            guard self.showFPS else { return }
            if self.fpsLabel == nil {
                let label = UILabel()
                label.textColor = self.infoTextColor.withAlphaComponent(0.8)
                label.backgroundColor = .clear
                label.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
                label.textAlignment = .center
                label.layer.cornerRadius = self.infoCornerRadius
                label.clipsToBounds = true
                self.fpsLabel = label
            }
            if #available(iOS 15.0, *), let contentView = self.modernPictureInPictureView(), self.fpsLabel?.superview == nil {
                if let label = self.fpsLabel {
                    label.translatesAutoresizingMaskIntoConstraints = true
                    contentView.addSubview(label)
                    contentView.bringSubviewToFront(label)
                    self.layoutInfoLabels(in: contentView)
                }
            } else if let window = self.legacyPictureInPictureWindow(), self.fpsLabel?.superview == nil {
                if let label = self.fpsLabel {
                    label.translatesAutoresizingMaskIntoConstraints = true
                    window.addSubview(label)
                    window.bringSubviewToFront(label)
                    self.layoutInfoLabels(in: window)
                }
            }
        }
    }
    
    private func ensureNetworkSpeedLabel() {
        DispatchQueue.main.async {
            guard self.showNetworkSpeed else { return }
            if self.networkSpeedLabel == nil {
                let label = UILabel()
                label.textColor = self.infoTextColor.withAlphaComponent(0.8)
                label.backgroundColor = .clear
                label.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
                label.textAlignment = .center
                label.layer.cornerRadius = self.infoCornerRadius
                label.clipsToBounds = true
                self.networkSpeedLabel = label
            }
            if #available(iOS 15.0, *), let contentView = self.modernPictureInPictureView(), self.networkSpeedLabel?.superview == nil {
                if let label = self.networkSpeedLabel {
                    label.translatesAutoresizingMaskIntoConstraints = true
                    contentView.addSubview(label)
                    contentView.bringSubviewToFront(label)
                    self.layoutInfoLabels(in: contentView)
                }
            } else if let window = self.legacyPictureInPictureWindow(), self.networkSpeedLabel?.superview == nil {
                if let label = self.networkSpeedLabel {
                    label.translatesAutoresizingMaskIntoConstraints = true
                    window.addSubview(label)
                    window.bringSubviewToFront(label)
                    self.layoutInfoLabels(in: window)
                }
            }
        }
    }
    
    private func layoutInfoLabels(in window: UIView) {
        let margin: CGFloat = 4
        let height: CGFloat = 16
        if let label = fpsLabel {
            let width: CGFloat = 50
            label.frame = CGRect(
                x: margin,
                y: window.bounds.height - height - margin,
                width: width,
                height: height
            )
        }
        if let label = networkSpeedLabel {
            let width: CGFloat = 140
            label.frame = CGRect(
                x: window.bounds.width - width - margin,
                y: window.bounds.height - height - margin,
                width: width,
                height: height
            )
        }
    }
    
    private func updateFPSLabel(_ fps: Int) {
        DispatchQueue.main.async {
            self.fpsLabel?.text = "\(fps) FPS"
        }
    }
    
    private func updateNetworkSpeedLabel(_ speed: String) {
        DispatchQueue.main.async {
            self.networkSpeedLabel?.text = speed
        }
    }
    
    private func updateText(_ text: String) {
        DispatchQueue.main.async {
            self.lyricView?.text = text
            self.lyricView?.setNeedsLayout()
        }
    }
    
    private func updateStyle(args: [String: Any]?) {
        guard let args = args else { return }
        
        DispatchQueue.main.async {
            guard let view = self.lyricView else { return }
            
            if let fontSize = args["fontSize"] as? Double {
                view.font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: .medium)
            }
            
            if let textColorInt = args["textColor"] as? Int {
                let color = self.colorFromInt(textColorInt)
                view.textColor = color
                self.infoTextColor = color
            }
            
            if let backgroundColorInt = args["backgroundColor"] as? Int {
                view.backgroundColor = self.colorFromInt(backgroundColorInt)
            }
            
            if let cornerRadius = args["cornerRadius"] as? Double {
                view.layer.cornerRadius = CGFloat(cornerRadius)
                self.infoCornerRadius = CGFloat(cornerRadius)
            }
            
            // Sync style to info labels (text color + corner radius, no background)
            self.applyStyleToInfoLabels()
        }
    }
    
    private func colorFromInt(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    private func applyStyleToInfoLabels() {
        for label in [fpsLabel, networkSpeedLabel] {
            guard let label = label else { continue }
            label.textColor = infoTextColor.withAlphaComponent(0.8)
            label.layer.cornerRadius = infoCornerRadius
        }
    }

    @available(iOS 15.0, *)
    private func modernPictureInPictureView() -> UIView? {
        return (pipVideoCallController as? AVPictureInPictureVideoCallViewController)?.view
    }

    private func legacyPictureInPictureWindow() -> UIWindow? {
        var windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for window in UIApplication.shared.windows where !windows.contains(where: { $0 === window }) {
            windows.append(window)
        }
        let mainWindow = hostView?.window
        let candidates = windows.filter { window in
            window !== mainWindow && !window.isHidden && window.alpha > 0 && !window.bounds.isEmpty
        }

        // PiP is system-managed and is not guaranteed to be in the app scene.
        // Prefer the identifiable system window, then a non-app elevated window.
        if let pipWindow = candidates.first(where: {
            String(describing: type(of: $0)).localizedCaseInsensitiveContains("pip")
        }) {
            return pipWindow
        }
        return candidates.first(where: { $0.windowLevel > .normal })
    }

    private func attachLegacyOverlay(attempt: Int = 0) {
        if #available(iOS 15.0, *), pipVideoCallController != nil {
            return
        }
        guard let window = legacyPictureInPictureWindow() else {
            if attempt < 12 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.attachLegacyOverlay(attempt: attempt + 1)
                }
            } else {
                print("Floating lyric PiP window was not found")
            }
            return
        }

        if let view = lyricView, view.superview !== window {
            view.translatesAutoresizingMaskIntoConstraints = true
            view.frame = window.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(view)
            window.bringSubviewToFront(view)
        }
        startMonitorsIfNeeded()
        if showFPS { ensureFPSLabel() }
        if showNetworkSpeed { ensureNetworkSpeedLabel() }
    }
    
    private func prepareLyricView(text: String) {
        if lyricView == nil {
            lyricView = UILabel()
            lyricView?.textColor = .white
            lyricView?.backgroundColor = UIColor(white: 0.0, alpha: 0.3) // Default style
            lyricView?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            lyricView?.textAlignment = .center
            lyricView?.numberOfLines = 0
            lyricView?.layer.cornerRadius = 8
            lyricView?.clipsToBounds = true
            // Remove shadow
            lyricView?.shadowColor = .clear
            lyricView?.shadowOffset = .zero
        }
        lyricView?.text = text
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if #available(iOS 15.0, *), pipVideoCallController != nil {
            return
        }
        attachLegacyOverlay()
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        startMonitorsIfNeeded()
        if showFPS { ensureFPSLabel() }
        if showNetworkSpeed { ensureNetworkSpeedLabel() }
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if #available(iOS 15.0, *), pipVideoCallController != nil {
            // Keep the lyric view attached to the system-managed content view
            // so the next PiP session can reuse it without a timing race.
        } else {
            lyricView?.removeFromSuperview()
        }
        fpsLabel?.removeFromSuperview()
        networkSpeedLabel?.removeFromSuperview()
        stopMonitors()
        player?.pause()
        channel.invokeMethod("onClose", arguments: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("PiP failed: \(error)")
    }
}
