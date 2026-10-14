// SPDX-License-Identifier: GPL-3.0-or-later

import CarminaDomain
import CarminaSources
import CarminaSourcesTesting
import Foundation
import Testing

/// An adapter under test, with the source tracks it is known to contain.
struct ContractSubject: Sendable, CustomTestStringConvertible {
	let name: String
	/// A search term known to match more than one source track in the catalog.
	let broadSearchTerm: String
	let make: @Sendable () async throws -> (service: any Service, catalog: [SourceTrack])
	/// Deletes a source track on the source itself, the way it would disappear outside Carmina.
	let deleteFromSource: @Sendable (any Service, SourceTrackID) async throws -> Void
	/// Puts the source in the given unavailable state, such as cutting the network or expiring the sign-in.
	let makeUnavailable: @Sendable (any Service, ServiceError.Reason) async throws -> Void

	var testDescription: String { name }

	static let all: [ContractSubject] = [
		.fake(named: "FakeService", capabilities: [.download]),
		.fake(named: "FakeService without capabilities", capabilities: []),
	]

	static func fake(named name: String, capabilities: Set<Capability>) -> ContractSubject {
		ContractSubject(
			name: name,
			broadSearchTerm: "Blue",
			make: {
				let source = SourceID()
				let catalog = ["Blue Monday", "Blue Line", "Red Light"].enumerated().map { index, title in
					SourceTrack(
						id: SourceTrackID(source: source, key: "track-\(index)"), details: TrackDetails(title: title))
				}
				// A page size smaller than the catalog, so listing has to follow cursors across pages.
				let service = FakeService(source: source, tracks: catalog, capabilities: capabilities, pageSize: 2)
				return (service, catalog)
			},
			deleteFromSource: { service, id in
				try await #require(service as? FakeService).delete(id)
			},
			makeUnavailable: { service, reason in
				try await #require(service as? FakeService).makeUnavailable(reason)
			}
		)
	}
}
