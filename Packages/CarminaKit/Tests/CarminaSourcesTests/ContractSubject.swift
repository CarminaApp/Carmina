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

	var testDescription: String { name }

	static let all: [ContractSubject] = [.fake]

	static let fake = ContractSubject(
		name: "FakeService",
		broadSearchTerm: "Blue",
		make: {
			let source = SourceID()
			let catalog = ["Blue Monday", "Blue Line", "Red Light"].enumerated().map { index, title in
				SourceTrack(id: SourceTrackID(source: source, key: "track-\(index)"), title: title)
			}
			// A page size smaller than the catalog, so listing has to follow cursors across pages.
			return (FakeService(source: source, tracks: catalog, pageSize: 2), catalog)
		},
		deleteFromSource: { service, id in
			try await #require(service as? FakeService).delete(id)
		}
	)
}
