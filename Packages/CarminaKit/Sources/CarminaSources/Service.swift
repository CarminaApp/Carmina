// SPDX-License-Identifier: GPL-3.0-or-later

public import CarminaDomain

/// The port every service's adapter fills. One instance serves one source.
///
/// Callers don't use this directly; they go through `Sources`, which owns the rules shared by every
/// service. Adapters only answer for their own source.
public protocol Service: Sendable {
	/// The source this instance serves. Every source track it returns belongs to it.
	var source: SourceID { get }

	/// Searches the source for songs, returning at most `limit` source tracks in the service's own order.
	func search(_ text: String, limit: Int) async throws -> [SourceTrack]

	/// Lists the source's songs one page at a time.
	///
	/// Pass `nil` for `cursor` to start, then each page's `next` until it is `nil`. A listing with
	/// `mark: nil` covers every source track.
	func songs(since mark: RefreshMark?, after cursor: PageCursor?) async throws -> SongPage
}
