// SPDX-License-Identifier: GPL-3.0-or-later

public import CarminaDomain

/// One page of a source's song listing.
///
/// Every page of one listing has the same coverage. Only the last page has a `mark`.
public struct SongPage: Sendable {
	/// No adapter returns more source tracks than this in one page, so a listing's memory stays bounded.
	public static let maximumSize = 500

	public enum Coverage: Sendable, Equatable {
		/// Every source track on the source appears somewhere in this listing, so anything not listed is gone.
		case complete
		/// Only source tracks added or changed since the mark. Unlisted source tracks may still exist, and
		/// deletions are reported only if the service can report them.
		case changesOnly
	}

	/// Source tracks that are new or whose details changed. In a complete listing, every source track.
	public var tracks: [SourceTrack]
	/// Source tracks deleted since the mark, when the service can report them. Always empty in a complete listing.
	public var deleted: [SourceTrackID]
	public var coverage: Coverage
	/// Where the next page starts, or `nil` if this is the last page.
	public var next: PageCursor?
	/// On the last page: where a later listing can continue from to get only what changed.
	public var mark: RefreshMark?

	public init(
		tracks: [SourceTrack],
		deleted: [SourceTrackID] = [],
		coverage: Coverage,
		next: PageCursor?,
		mark: RefreshMark? = nil
	) {
		self.tracks = tracks
		self.deleted = deleted
		self.coverage = coverage
		self.next = next
		self.mark = mark
	}
}

/// Where a listing continues. Only valid within the listing that produced it.
public struct PageCursor: Hashable, Sendable {
	public let rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}
}

/// Marks how far a source's listing got, so a later listing can ask only for what changed since.
///
/// Opaque to callers. An adapter that can't list changes ignores it and returns a complete listing.
public struct RefreshMark: Hashable, Sendable, Codable {
	public let rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}
}
