// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// One specific connection the listener can search and browse, such as one Plex server.
public struct SourceID: Hashable, Sendable, Codable {
	public let rawValue: UUID

	public init(rawValue: UUID = UUID()) {
		self.rawValue = rawValue
	}
}

/// Identifies a source track: the source it lives on, plus a key only that source's adapter understands.
///
/// The key is stable for as long as the source track exists, across refreshes.
public struct SourceTrackID: Hashable, Sendable, Codable {
	public let source: SourceID
	public let key: String

	public init(source: SourceID, key: String) {
		self.source = source
		self.key = key
	}
}

/// A song as it exists on one source, with that source's own details.
public struct SourceTrack: Hashable, Sendable, Codable {
	public let id: SourceTrackID
	public var details: TrackDetails

	public init(id: SourceTrackID, details: TrackDetails) {
		self.id = id
		self.details = details
	}
}
