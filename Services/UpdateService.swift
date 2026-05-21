//
//  UpdateService.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/21.
//

import CryptoKit
import Foundation

enum UpdateState: Equatable, Sendable {
    case idle
    case checking
    case upToDate(currentVersion: String)
    case available(version: String)
    case downloading(version: String)
    case readyToInstall(version: String)
    case failed(message: String)

    var isBusy: Bool {
        switch self {
        case .checking, .downloading:
            return true
        default:
            return false
        }
    }

    var buttonTitle: String {
        switch self {
        case .available:
            return "下载更新"
        case .readyToInstall:
            return "打开安装包"
        case .checking:
            return "正在检查"
        case .downloading:
            return "正在下载"
        default:
            return "检查更新"
        }
    }

    var buttonSystemImage: String {
        switch self {
        case .available:
            return "square.and.arrow.down"
        case .readyToInstall:
            return "shippingbox"
        case .failed:
            return "exclamationmark.triangle"
        default:
            return "arrow.triangle.2.circlepath"
        }
    }

    var message: String? {
        switch self {
        case .idle:
            return "检查是否有可安装的新版本。"
        case .checking:
            return "正在检查最新版本..."
        case .upToDate(let currentVersion):
            return "当前已是最新版本 \(currentVersion)。"
        case .available(let version):
            return "发现新版本 \(version)，可直接在应用内下载。"
        case .downloading(let version):
            return "正在下载 \(version) 安装包..."
        case .readyToInstall(let version):
            return "\(version) 安装包已打开，按窗口提示完成替换。"
        case .failed(let message):
            return message
        }
    }
}

struct UpdatePrompt: Equatable, Identifiable {
    let version: String

    var id: String {
        version
    }

    var title: String {
        "发现新版本"
    }

    var message: String {
        "今历 \(version) 已发布，是否现在更新？"
    }
}

struct UpdateInfo: Equatable, Sendable {
    let version: String
    let tagName: String
    let downloadURL: URL
    let expectedSHA256: String?
}

enum UpdateServiceError: LocalizedError, Sendable {
    case invalidReleaseResponse
    case requestFailed(statusCode: Int)
    case downloadFailed(statusCode: Int)
    case releaseVersionMissing
    case assetMissing(assetName: String)
    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .invalidReleaseResponse:
            return "无法读取更新信息，请稍后重试。"
        case .requestFailed(let statusCode):
            return "检查更新失败（HTTP \(statusCode)）。"
        case .downloadFailed(let statusCode):
            return "下载更新失败（HTTP \(statusCode)）。"
        case .releaseVersionMissing:
            return "最新版本号无法识别。"
        case .assetMissing(let assetName):
            return "发现新版本，但没有找到 \(assetName)。"
        case .checksumMismatch:
            return "安装包校验失败，请稍后重试。"
        }
    }
}

struct UpdateService: Sendable {
    private let owner: String
    private let repository: String
    private let assetName: String

    init(
        owner: String = "CoderQHao",
        repository: String = "menu-bar-calendar",
        assetName: String = "MenuBarCalendar.dmg"
    ) {
        self.owner = owner
        self.repository = repository
        self.assetName = assetName
    }

    func latestUpdate(currentVersion: String) async throws -> UpdateInfo? {
        let releaseURL = URL(
            string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest"
        )!
        let (data, response) = try await URLSession.shared.data(for: apiRequest(for: releaseURL))
        try validate(response: response, failure: UpdateServiceError.requestFailed(statusCode:))

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard let latestVersion = AppVersion(release.tagName),
              let installedVersion = AppVersion(currentVersion) else {
            throw UpdateServiceError.releaseVersionMissing
        }

        guard latestVersion > installedVersion else {
            return nil
        }

        guard let asset = release.assets.first(where: { $0.name == assetName }) else {
            throw UpdateServiceError.assetMissing(assetName: assetName)
        }

        return UpdateInfo(
            version: latestVersion.displayValue,
            tagName: release.tagName,
            downloadURL: asset.browserDownloadURL,
            expectedSHA256: asset.sha256Digest
        )
    }

    func download(_ update: UpdateInfo) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(
            for: downloadRequest(for: update.downloadURL)
        )
        try validate(response: response, failure: UpdateServiceError.downloadFailed(statusCode:))

        let fileManager = FileManager.default
        let destinationDirectory = try updateDirectory(fileManager: fileManager)
        let destinationURL = destinationDirectory.appendingPathComponent(
            "MenuBarCalendar-\(safeFileComponent(update.tagName)).dmg"
        )

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        try validateChecksum(for: destinationURL, expectedSHA256: update.expectedSHA256)
        return destinationURL
    }

    private func apiRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("MenuBarCalendar", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func downloadRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("MenuBarCalendar", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func validate(
        response: URLResponse,
        failure: (Int) -> UpdateServiceError
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateServiceError.invalidReleaseResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw failure(httpResponse.statusCode)
        }
    }

    private func updateDirectory(fileManager: FileManager) throws -> URL {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = applicationSupportURL.appendingPathComponent(
            "MenuBarCalendar/Updates",
            isDirectory: true
        )
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    private func safeFileComponent(_ value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        return value.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? String(scalar) : "-"
        }
        .joined()
    }

    private func validateChecksum(for fileURL: URL, expectedSHA256: String?) throws {
        guard let expectedSHA256 else {
            return
        }

        let fileData = try Data(contentsOf: fileURL)
        let downloadedSHA256 = SHA256.hash(data: fileData)
            .map { String(format: "%02x", $0) }
            .joined()

        guard downloadedSHA256.caseInsensitiveCompare(expectedSHA256) == .orderedSame else {
            try? FileManager.default.removeItem(at: fileURL)
            throw UpdateServiceError.checksumMismatch
        }
    }
}

private struct GitHubRelease: Decodable, Sendable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

private struct GitHubAsset: Decodable, Sendable {
    let name: String
    let browserDownloadURL: URL
    let digest: String?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case digest
    }

    var sha256Digest: String? {
        guard let digest,
              digest.hasPrefix("sha256:") else {
            return nil
        }

        return String(digest.dropFirst("sha256:".count))
    }
}

private struct AppVersion: Comparable, Sendable {
    let displayValue: String
    private let components: [Int]

    init?(_ rawValue: String) {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayValue = trimmedValue.removingLeadingVersionPrefix
        let rawComponents = displayValue.split(separator: ".")
        let components = rawComponents.compactMap { component -> Int? in
            let digits = component.prefix { $0.isNumber }
            return digits.isEmpty ? nil : Int(digits)
        }

        guard !displayValue.isEmpty,
              !components.isEmpty,
              components.count == rawComponents.count else {
            return nil
        }

        self.displayValue = displayValue
        self.components = components
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)

        for index in 0..<count {
            let lhsValue = index < lhs.components.count ? lhs.components[index] : 0
            let rhsValue = index < rhs.components.count ? rhs.components[index] : 0

            if lhsValue != rhsValue {
                return lhsValue < rhsValue
            }
        }

        return false
    }
}

private extension String {
    var removingLeadingVersionPrefix: String {
        guard let firstCharacter = first,
              firstCharacter == "v" || firstCharacter == "V" else {
            return self
        }

        return String(dropFirst())
    }
}
