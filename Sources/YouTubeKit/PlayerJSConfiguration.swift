//
//  PlayerJSConfiguration.swift
//  YouTubeKit (Appnics fork)
//
//  Which of a player's JavaScript files the signatures are solved from, settable by the app at run
//  time, so a variant YouTube breaks can be swapped for one that works without a new build.
//

import Foundation

/// The player's JavaScript file the challenges are solved from: `https://youtube.com/s/player/{ID}/{variantPath}`,
/// with the page's player ID unless `playerIDOverride` is set. Set `current` before extracting; a value
/// that is not a plain relative `.js` path or a plain ID is ignored, so the file stays on youtube.com.
public struct PlayerJSConfiguration: Sendable, Equatable {
    /// yt-dlp's default since 2026.11.23: the web variants of player b485e332 and later throw in the solver.
    public static let defaultVariantPath = "tv-player-ias.vflset/tv-player-ias.js"

    public var variantPath: String
    public var playerIDOverride: String?

    public init(variantPath: String = defaultVariantPath, playerIDOverride: String? = nil) {
        self.variantPath = variantPath
        self.playerIDOverride = playerIDOverride
    }

    /// What `Extraction.jsURL` uses. Setting it keeps only the valid parts of the new value.
    public static var current: PlayerJSConfiguration {
        get {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
        set {
            let valid = newValue.validated
            lock.lock()
            defer { lock.unlock() }
            stored = valid
        }
    }

    /// The default path for an invalid `variantPath`, and no override for an invalid `playerIDOverride`.
    public var validated: PlayerJSConfiguration {
        PlayerJSConfiguration(
            variantPath: Self.isValidVariantPath(variantPath) ? variantPath : Self.defaultVariantPath,
            playerIDOverride: playerIDOverride.flatMap { Self.isValidPlayerID($0) ? $0 : nil })
    }

    /// Path segments of letters, digits, `_` and `-` joined by single dots, separated by `/`, ending in `.js`,
    /// 100 characters at most: no `..`, no leading `/`, no scheme or host, no query.
    public static func isValidVariantPath(_ path: String) -> Bool {
        path.count <= 100 && path.range(
            of: #"^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*(/[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*)*\.js$"#,
            options: .regularExpression) != nil
    }

    public static func isValidPlayerID(_ id: String) -> Bool {
        id.range(of: #"^[A-Za-z0-9_]{1,32}$"#, options: .regularExpression) != nil
    }

    private static let lock = NSLock()
#if swift(>=5.10)
    nonisolated(unsafe) private static var stored = PlayerJSConfiguration()
#else
    private static var stored = PlayerJSConfiguration()
#endif
}
