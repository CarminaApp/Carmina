// SPDX-License-Identifier: GPL-3.0-or-later

public import CarminaDomain
public import CarminaSources
import Foundation

/// An in-memory service seeded with source tracks, for tests of anything that talks to the Service port.
///
/// It behaves like a service with a full change feed: a listing since a mark returns only what changed,
/// including deletions.
public actor FakeService: Service {
	public nonisolated let source: SourceID
	public nonisolated let capabilities: Set<Capability>
	private let pageSize: Int
	private var tracks: [SourceTrack]
	/// Bumped on every change, and handed out as the refresh mark.
	private var version = 0
	private var changedAt: [SourceTrackID: Int] = [:]
	private var deletedAt: [SourceTrackID: Int] = [:]
	private var unavailable: ServiceError.Reason?

	public init(
		source: SourceID,
		tracks: [SourceTrack],
		capabilities: Set<Capability> = [],
		pageSize: Int = SongPage.maximumSize
	) {
		self.source = source
		self.tracks = tracks
		self.capabilities = capabilities
		self.pageSize = pageSize
	}

	/// Deletes a source track on the source, as if it had been removed outside Carmina.
	public func delete(_ id: SourceTrackID) {
		version += 1
		tracks.removeAll { $0.id == id }
		changedAt[id] = nil
		deletedAt[id] = version
	}

	/// Fails every later call with the reason, as if the source had gone offline or the sign-in had expired.
	public func makeUnavailable(_ reason: ServiceError.Reason) {
		unavailable = reason
	}

	private func checkAvailable() throws {
		if let unavailable {
			throw ServiceError.unavailable(unavailable)
		}
	}

	public func search(_ text: String, limit: Int) async throws -> [SourceTrack] {
		try checkAvailable()
		let matches = tracks.filter { $0.title.localizedStandardContains(text) }
		return Array(matches.prefix(limit))
	}

	public func playable(for track: SourceTrack) async throws -> Playable {
		try checkAvailable()
		guard tracks.contains(where: { $0.id == track.id }) else {
			throw ServiceError.trackNotFound
		}
		return .url(URL(string: "fake://\(track.id.key)")!)
	}

	/// Writes the source track's title as the file's contents.
	public func download(_ track: SourceTrack, to destination: URL) async throws {
		guard capabilities.contains(.download) else {
			throw ServiceError.unsupported
		}
		_ = try await playable(for: track)
		try Data(track.title.utf8).write(to: destination)
	}

	public func songs(since mark: RefreshMark?, after cursor: PageCursor?) async throws -> SongPage {
		try Task.checkCancellation()
		try checkAvailable()
		let since = mark.flatMap { Int($0.rawValue) }
		let listed = since.map { since in tracks.filter { changedAt[$0.id, default: 0] > since } } ?? tracks
		let deleted = since.map { since in deletedAt.filter { $0.value > since }.map(\.key) } ?? []

		let start = cursor.flatMap { Int($0.rawValue) } ?? 0
		let end = min(start + pageSize, listed.count)
		let isLast = end == listed.count
		return SongPage(
			tracks: Array(listed[start..<end]),
			deleted: start == 0 ? deleted : [],
			coverage: since == nil ? .complete : .changesOnly,
			next: isLast ? nil : PageCursor(rawValue: String(end)),
			mark: isLast ? RefreshMark(rawValue: String(version)) : nil
		)
	}
}
