// SPDX-License-Identifier: GPL-3.0-or-later

import CarminaDomain
import CarminaLibrary
import Testing

@Suite("Duplicate rule")
struct DuplicateRuleTests {
	private let inLibrary = TrackDetails(
		title: "Blue Monday",
		trackArtist: "New Order",
		album: "Power, Corruption & Lies",
		duration: .seconds(448)
	)

	@Test("Identical details are a duplicate")
	func identicalDetails() {
		#expect(DuplicateRule.isDuplicate(inLibrary, of: inLibrary))
	}

	@Test("Differences only in case and spacing are still a duplicate")
	func caseAndSpacing() {
		let candidate = TrackDetails(
			title: "  blue   MONDAY",
			trackArtist: "new order ",
			album: "Power,  Corruption & lies",
			duration: .seconds(448)
		)

		#expect(DuplicateRule.isDuplicate(candidate, of: inLibrary))
	}

	@Test("Durations within two seconds of each other are nearly the same", arguments: [446.0, 447.5, 449.9, 450])
	func nearlySameDuration(seconds: Double) {
		var candidate = inLibrary
		candidate.duration = .seconds(seconds)

		#expect(DuplicateRule.isDuplicate(candidate, of: inLibrary))
	}

	@Test("Durations further apart are a different song", arguments: [445.9, 450.1, 200])
	func differentDuration(seconds: Double) {
		var candidate = inLibrary
		candidate.duration = .seconds(seconds)

		#expect(!DuplicateRule.isDuplicate(candidate, of: inLibrary))
	}

	@Test("An unknown duration on either side leaves the decision to title, track artist and album")
	func unknownDuration() {
		var candidate = inLibrary
		candidate.duration = nil

		#expect(DuplicateRule.isDuplicate(candidate, of: inLibrary))
		#expect(DuplicateRule.isDuplicate(inLibrary, of: candidate))
	}

	@Test(
		"A different title, track artist or album is a different song",
		arguments: [
			TrackDetails(title: "Blue Monday '88", trackArtist: "New Order", album: "Power, Corruption & Lies"),
			TrackDetails(title: "Blue Monday", trackArtist: "Orkestra Obsolete", album: "Power, Corruption & Lies"),
			TrackDetails(title: "Blue Monday", trackArtist: "New Order", album: "Substance"),
			TrackDetails(title: "Blue Monday", trackArtist: "New Order"),
		]
	)
	func differentText(candidate: TrackDetails) {
		var candidate = candidate
		candidate.duration = inLibrary.duration

		#expect(!DuplicateRule.isDuplicate(candidate, of: inLibrary))
	}
}
