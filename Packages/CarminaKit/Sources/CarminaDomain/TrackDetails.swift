// SPDX-License-Identifier: GPL-3.0-or-later

/// The details that describe a song, as a source reports them or as the listener edited them.
public struct TrackDetails: Hashable, Sendable, Codable {
	public var title: String
	/// The artist of this song, as opposed to the album artist.
	public var trackArtist: String
	public var album: String?
	/// `nil` when the source doesn't report it.
	public var duration: Duration?

	public init(title: String, trackArtist: String = "", album: String? = nil, duration: Duration? = nil) {
		self.title = title
		self.trackArtist = trackArtist
		self.album = album
		self.duration = duration
	}
}
