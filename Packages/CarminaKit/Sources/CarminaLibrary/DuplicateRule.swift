// SPDX-License-Identifier: GPL-3.0-or-later

public import CarminaDomain
import Foundation

/// Decides whether a source track is a duplicate of a track already in the library.
///
/// It only ever triggers a prompt before adding, or reconnects a missing track within the same source.
/// Carmina never combines tracks because of it.
public enum DuplicateRule {
	/// Whether a source track with `candidate` details duplicates a library track showing `existing`.
	public static func isDuplicate(_ candidate: TrackDetails, of existing: TrackDetails) -> Bool {
		comparable(candidate.title) == comparable(existing.title)
			&& comparable(candidate.trackArtist) == comparable(existing.trackArtist)
			&& comparable(candidate.album ?? "") == comparable(existing.album ?? "")
			&& nearlySame(candidate.duration, existing.duration)
	}

	/// How far apart two durations can be and still be nearly the same, to allow for different encodings.
	static let durationTolerance = Duration.seconds(2)

	/// An unknown duration rules nothing out, so the text decides.
	private static func nearlySame(_ first: Duration?, _ second: Duration?) -> Bool {
		guard let first, let second else {
			return true
		}
		let gap = first > second ? first - second : second - first
		return gap <= durationTolerance
	}

	/// The text with case and spacing differences removed.
	private static func comparable(_ text: String) -> String {
		text.split(whereSeparator: \.isWhitespace).joined(separator: " ").folding(
			options: .caseInsensitive, locale: nil)
	}
}
