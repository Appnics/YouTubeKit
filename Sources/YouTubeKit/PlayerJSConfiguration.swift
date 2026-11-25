//
//  PlayerJSConfiguration.swift
//  YouTubeKit (Appnics fork)
//
//  Which of a player's JavaScript files the signatures are solved from, settable by the app at run
//  time, so a variant YouTube breaks can be swapped for one that works without a new build.
//  The values follow the apps' `/config` `youtube_player` contract (Singday youtube-guard FR-8).
//

import Foundation

/// The player's JavaScript file the challenges are solved from: `https://youtube.com/s/player/{ID}/{variantPath}`,
/// or the page's own file when `variantPath` is nil (`page`), with the page's player ID unless `playerIDOverride`
/// is set. Set `current` before extracting; a value of the wrong form is ignored, so the file stays on youtube.com
/// under `/s/player/`.
public struct PlayerJSConfiguration: Sendable, Equatable {
    /// yt-dlp's default since 2026.11.23: the web variants of player b485e332 and later throw in the solver.
    public static let defaultVariantPath = "tv-player-ias.vflset/tv-player-ias.js"

    /// Nil: the page's own variant, as before the tv variant (`page`).
    public var variantPath: String?
    public var playerIDOverride: String?

    public init(variantPath: String? = defaultVariantPath, playerIDOverride: String? = nil) {
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

    /// The default path for an invalid `variantPath` (nil stays nil), and no override for an invalid ID.
    public var validated: PlayerJSConfiguration {
        PlayerJSConfiguration(
            variantPath: variantPath.map { Self.isValidVariantPath($0) ? $0 : Self.defaultVariantPath },
            playerIDOverride: playerIDOverride.flatMap { Self.isValidPlayerID($0) ? $0 : nil })
    }

    /// 1 to 4 segments separated by `/`, each `^(?!\.{1,2}$)[A-Za-z0-9_.-]+$` (no `.` or `..` segment), the last
    /// ending in `.js`: no leading `/`, no scheme or host, no query.
    public static func isValidVariantPath(_ path: String) -> Bool {
        let segments = path.split(separator: "/", omittingEmptySubsequences: false)
        guard (1...4).contains(segments.count), path.hasSuffix(".js"), path.count <= 200 else { return false }
        return segments.allSatisfy { segment in
            segment != "." && segment != ".."
                && segment.range(of: #"^[A-Za-z0-9_.-]+\z"#, options: .regularExpression) != nil
        }
    }

    /// `^[A-Za-z0-9_-]{6,16}$`, with no trailing newline (`\z`, not ICU's `$`).
    public static func isValidPlayerID(_ id: String) -> Bool {
        id.range(of: #"^[A-Za-z0-9_-]{6,16}\z"#, options: .regularExpression) != nil
    }

    private static let lock = NSLock()
#if swift(>=5.10)
    nonisolated(unsafe) private static var stored = PlayerJSConfiguration()
#else
    private static var stored = PlayerJSConfiguration()
#endif
}
