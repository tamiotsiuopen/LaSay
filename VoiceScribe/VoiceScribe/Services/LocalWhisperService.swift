//
//  LocalWhisperService.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

final class LocalWhisperService {
    static let shared = LocalWhisperService()

    enum DownloadKind {
        case model
        case binary
    }

    struct DownloadProgress {
        let kind: DownloadKind
        let fraction: Double
        let bytesReceived: Int64
        let bytesExpected: Int64
        let isCompleted: Bool
    }

    typealias DownloadProgressHandler = (DownloadProgress) -> Void

    private let fileManager = FileManager.default
    private var progressObservations: [Int: NSKeyValueObservation] = [:]
    private let modelFileName = "ggml-base.bin"
    private let modelDownloadURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin")!
    private let binaryDownloadURLArm64 = URL(string: "https://github.com/bizenlabs/whisper-cpp-macos-bin/releases/download/v1.8.2-2/whisper-cpp-v1.8.2-macos-arm64-metal.zip")!
    private let binaryDownloadURLX86 = URL(string: "https://github.com/bizenlabs/whisper-cpp-macos-bin/releases/download/v1.8.2-2/whisper-cpp-v1.8.2-macos-x86_64-accelerate.zip")!

    private init() {}

    var isModelDownloaded: Bool {
        fileManager.fileExists(atPath: modelFileURL.path)
    }

    var isCLIDownloaded: Bool {
        findWhisperCLI() != nil
    }

    func predownload() {
        ensureWhisperCLI(progressHandler: nil) { _ in }
        ensureModel(progressHandler: nil) { _ in }
    }

    func transcribe(
        audioFileURL: URL,
        language: String? = nil,
        progressHandler: DownloadProgressHandler? = nil,
        completion: @escaping (Result<String, WhisperError>) -> Void
    ) {
        debugLog("[DEBUG] [LocalWhisper] transcribe called, audio: \(audioFileURL.path)")
        debugLog("[DEBUG] [LocalWhisper] CLI downloaded: \(isCLIDownloaded), Model downloaded: \(isModelDownloaded)")
        
        guard fileManager.fileExists(atPath: audioFileURL.path) else {
            debugLog("[ERROR] [LocalWhisper] Audio file not found: \(audioFileURL.path)")
            completion(.failure(.invalidAudioFile))
            return
        }

        ensureWhisperCLI(progressHandler: progressHandler) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let cliURL):
                self?.ensureModel(progressHandler: progressHandler) { modelResult in
                    switch modelResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let modelURL):
                        self?.runWhisperCLI(cliURL: cliURL, modelURL: modelURL, audioFileURL: audioFileURL, language: language, completion: completion)
                    }
                }
            }
        }
    }

    // MARK: - Paths

    private var baseDirectory: URL {
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return supportDir.appendingPathComponent("LaSay", isDirectory: true)
    }

    private var modelsDirectory: URL {
        baseDirectory.appendingPathComponent("models", isDirectory: true)
    }

    private var binariesDirectory: URL {
        baseDirectory.appendingPathComponent("whisper", isDirectory: true)
    }

    private var modelFileURL: URL {
        modelsDirectory.appendingPathComponent(modelFileName)
    }

    // MARK: - Model Download

    private func ensureModel(
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<URL, WhisperError>) -> Void
    ) {
        if fileManager.fileExists(atPath: modelFileURL.path) {
            completion(.success(modelFileURL))
            return
        }

        do {
            try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }

        debugLog("[DEBUG] [LocalWhisper] Downloading model to: \(modelFileURL.path)")

        downloadFile(
            from: modelDownloadURL,
            to: modelFileURL,
            label: "Model",
            kind: .model,
            progressHandler: progressHandler
        ) { result in
            switch result {
            case .success:
                debugLog("[OK] [LocalWhisper] Model downloaded")
                completion(.success(self.modelFileURL))
            case .failure:
                completion(.failure(.modelDownloadFailed))
            }
        }
    }

    // MARK: - Whisper CLI Download

    private func ensureWhisperCLI(
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<URL, WhisperError>) -> Void
    ) {
        if let existing = findWhisperCLI() {
            completion(.success(existing))
            return
        }

        do {
            try fileManager.createDirectory(at: binariesDirectory, withIntermediateDirectories: true)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }

        let arch = ProcessInfo.processInfo.machineArchitecture
        let downloadURL = arch == "arm64" ? binaryDownloadURLArm64 : binaryDownloadURLX86
        let zipURL = fileManager.temporaryDirectory.appendingPathComponent("whisper-cli-\(UUID().uuidString).zip")

        debugLog("[DEBUG] [LocalWhisper] Downloading whisper.cpp CLI (\(arch))")

        downloadFile(
            from: downloadURL,
            to: zipURL,
            label: "Binary",
            kind: .binary,
            progressHandler: progressHandler
        ) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(.networkError(error)))
            case .success:
                self?.unzipBinary(from: zipURL) { unzipResult in
                    switch unzipResult {
                    case .failure(let error):
                        completion(.failure(.networkError(error)))
                    case .success(let cliURL):
                        completion(.success(cliURL))
                    }
                }
            }
        }
    }

    private func unzipBinary(from zipURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipURL.path, "-d", binariesDirectory.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.terminationHandler = { [weak self] process in
            if process.terminationStatus != 0 {
                completion(.failure(NSError(domain: "LocalWhisper", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to unzip whisper.cpp"])) )
                return
            }

            if let cliURL = self?.findWhisperCLI() {
                do {
                    try self?.fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cliURL.path)
                } catch {
                    completion(.failure(error))
                    return
                }
                completion(.success(cliURL))
            } else {
                completion(.failure(NSError(domain: "LocalWhisper", code: -1, userInfo: [NSLocalizedDescriptionKey: "whisper-cli not found after unzip"])) )
            }
        }

        do {
            try process.run()
        } catch {
            completion(.failure(error))
        }
    }

    private func findWhisperCLI() -> URL? {
        guard fileManager.fileExists(atPath: binariesDirectory.path) else { return nil }

        let enumerator = fileManager.enumerator(at: binariesDirectory, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent == "whisper-cli" {
                return fileURL
            }
        }
        return nil
    }

    // MARK: - Run CLI

    private func runWhisperCLI(cliURL: URL, modelURL: URL, audioFileURL: URL, language: String?, completion: @escaping (Result<String, WhisperError>) -> Void) {
        debugLog("[DEBUG] [LocalWhisper] Running CLI: \(cliURL.path)")
        debugLog("[DEBUG] [LocalWhisper] Model: \(modelURL.path)")
        debugLog("[DEBUG] [LocalWhisper] Audio: \(audioFileURL.path)")
        DispatchQueue.global(qos: .userInitiated).async {
            let outputPrefix = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
            var arguments = [
                "-m", modelURL.path,
                "-f", audioFileURL.path,
                "-of", outputPrefix,
                "-otxt",
                "-nt"
            ]

            if let language = language {
                arguments.append(contentsOf: ["-l", language])
            }

            let process = Process()
            process.executableURL = cliURL
            process.arguments = arguments
            debugLog("[DEBUG] [LocalWhisper] CLI arguments: \(arguments)")

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                debugLog("[DEBUG] [LocalWhisper] CLI process started, pid: \(process.processIdentifier)")
                process.waitUntilExit()
                debugLog("[DEBUG] [LocalWhisper] CLI process exited with status: \(process.terminationStatus)")
            } catch {
                debugLog("[ERROR] [LocalWhisper] CLI process failed to start: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }

            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: data, encoding: .utf8) ?? "Unknown error"
                debugLog("[ERROR] [LocalWhisper] CLI error output: \(errorOutput)")
                DispatchQueue.main.async {
                    completion(.failure(.apiError(errorOutput)))
                }
                return
            }

            let outputURL = URL(fileURLWithPath: outputPrefix + ".txt")
            guard let rawText = try? String(contentsOf: outputURL, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                completion(.success(trimmed))
            }
        }
    }

    // MARK: - Download Helper

    private func downloadFile(
        from url: URL,
        to destination: URL,
        label: String,
        kind: DownloadKind,
        progressHandler: DownloadProgressHandler?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let request = URLRequest(url: url)
        var taskId: Int?
        let task = URLSession.shared.downloadTask(with: request) { [weak self] tempURL, response, error in
            defer {
                if let taskId = taskId {
                    self?.progressObservations.removeValue(forKey: taskId)
                }
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "LocalWhisper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed"])))
                return
            }

            // Get final byte count from response
            let bytesExpected = response?.expectedContentLength ?? -1

            do {
                if self?.fileManager.fileExists(atPath: destination.path) == true {
                    try self?.fileManager.removeItem(at: destination)
                }
                try self?.fileManager.moveItem(at: tempURL, to: destination)
                
                // Get actual file size
                let attrs = try? self?.fileManager.attributesOfItem(atPath: destination.path)
                let fileSize = (attrs?[.size] as? Int64) ?? bytesExpected
                
                DispatchQueue.main.async {
                    progressHandler?(DownloadProgress(
                        kind: kind,
                        fraction: 1.0,
                        bytesReceived: fileSize,
                        bytesExpected: fileSize,
                        isCompleted: true
                    ))
                }
                completion(.success(destination))
            } catch {
                completion(.failure(error))
            }
        }

        taskId = task.taskIdentifier

        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            let percent = Int(progress.fractionCompleted * 100)
            debugLog("[DEBUG] [LocalWhisper] \(label) download progress: \(percent)%")
            DispatchQueue.main.async {
                progressHandler?(DownloadProgress(
                    kind: kind,
                    fraction: progress.fractionCompleted,
                    bytesReceived: progress.completedUnitCount,
                    bytesExpected: progress.totalUnitCount,
                    isCompleted: false
                ))
            }
        }

        if let taskId = taskId {
            progressObservations[taskId] = observation
        }
        task.resume()
    }
}

private extension ProcessInfo {
    var machineArchitecture: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine
    }
}
