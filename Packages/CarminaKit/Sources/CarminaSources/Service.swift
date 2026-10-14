// SPDX-License-Identifier: GPL-3.0-or-later

public import CarminaDomain
public import Foundation

/// The port every service's adapter fills. One instance serves one source.
///
/// Callers don't use this directly; they go through `Sources`, which owns the rules shared by every
/// service. Adapters only answer for their own source.
public protocol Service: Sendable {
	/// The source this instance serves. Every source track it returns belongs to it.
	var source: SourceID { get }

	/// The optional parts of the port this service supports. Doesn't change while the source is connected.
	var capabilities: Set<Capability> { get }

	/// Searches the source for songs, returning at most `limit` source tracks in the service's own order.
	func search(_ text: String, limit: Int) async throws -> [SourceTrack]

	/// Lists the source's songs one page at a time.
	///
	/// Pass `nil` for `cursor` to start, then each page's `next` until it is `nil`. A listing with
	/// `mark: nil` covers every source track. Throws `CancellationError` instead of returning a page once
	/// the calling task is cancelled.
	func songs(since mark: RefreshMark?, after cursor: PageCursor?) async throws -> SongPage

	/// Returns what a renderer needs to play the source track.
	///
	/// Throws `ServiceError.trackNotFound` if the source track has been deleted from the source.
	func playable(for track: SourceTrack) async throws -> Playable

	/// Saves the source track's audio file at `destination`. Requires `Capability.download`.
	func download(_ track: SourceTrack, to destination: URL) async throws
}

extension Service {
	public var capabilities: Set<Capability> { [] }

	public func download(_ track: SourceTrack, to destination: URL) async throws {
		throw ServiceError.unsupported
	}
}
