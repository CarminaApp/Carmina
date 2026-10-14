// SPDX-License-Identifier: GPL-3.0-or-later

import CarminaDomain
import CarminaSources
import CarminaSourcesTesting
import Foundation
import Testing

/// The rules every adapter at the Service port must follow.
///
/// Each subject is an adapter set up with a known catalog of source tracks. The same suite runs against
/// every adapter, so a new service is checked against exactly the same contract as the existing ones.
@Suite("Service contract")
struct ServiceContractTests {
	@Test("Search returns at most the limit, all from the searched source", arguments: ContractSubject.all)
	func searchRespectsLimitAndSource(_ subject: ContractSubject) async throws {
		let (service, _) = try await subject.make()

		let results = try await service.search(subject.broadSearchTerm, limit: 1)

		#expect(results.count == 1)
		#expect(results.allSatisfy { $0.id.source == service.source })
	}

	@Test("A full listing delivers every source track exactly once, in bounded pages", arguments: ContractSubject.all)
	func fullListingIsCompleteAndBounded(_ subject: ContractSubject) async throws {
		let (service, catalog) = try await subject.make()

		let listing = try await Listing.collect(from: service, since: nil)

		#expect(listing.pages.allSatisfy { $0.tracks.count <= SongPage.maximumSize })
		#expect(listing.listed.count == catalog.count)
		#expect(Set(listing.listed) == Set(catalog.map(\.id)))
		#expect(listing.coverage == .complete)
	}

	@Test("A listing since a mark never shows a deleted source track as still there", arguments: ContractSubject.all)
	func listingSinceMarkAccountsForDeletion(_ subject: ContractSubject) async throws {
		let (service, catalog) = try await subject.make()
		let mark = try #require(try await Listing.collect(from: service, since: nil).mark)
		let deleted = try #require(catalog.first?.id)

		try await subject.deleteFromSource(service, deleted)
		let listing = try await Listing.collect(from: service, since: mark)

		#expect(!listing.listed.contains(deleted))
		switch try #require(listing.coverage) {
		case .complete:
			#expect(Set(listing.listed) == Set(catalog.dropFirst().map(\.id)))
		case .changesOnly:
			// Change feeds may not report deletions; Refresh then relies on a scheduled complete listing.
			#expect(listing.deleted.allSatisfy { $0 == deleted })
		}
	}

	@Test("Every source track is playable until it is deleted from the source", arguments: ContractSubject.all)
	func playableUntilDeleted(_ subject: ContractSubject) async throws {
		let (service, catalog) = try await subject.make()
		for track in catalog {
			_ = try await service.playable(for: track)
		}
		let deleted = try #require(catalog.first)

		try await subject.deleteFromSource(service, deleted.id)

		await #expect(throws: ServiceError.trackNotFound) {
			try await service.playable(for: deleted)
		}
	}

	@Test("Download works exactly when the service declares it can download", arguments: ContractSubject.all)
	func downloadMatchesCapabilities(_ subject: ContractSubject) async throws {
		let (service, catalog) = try await subject.make()
		let track = try #require(catalog.first)
		let destination = URL.temporaryDirectory.appending(path: UUID().uuidString)
		defer { try? FileManager.default.removeItem(at: destination) }

		if service.capabilities.contains(.download) {
			try await service.download(track, to: destination)
			#expect(FileManager.default.fileExists(atPath: destination.path()))
		} else {
			await #expect(throws: ServiceError.unsupported) {
				try await service.download(track, to: destination)
			}
		}
	}

	@Test(
		"A source that becomes unavailable fails every call with the reason, even partway through a listing",
		arguments: ContractSubject.all, [ServiceError.Reason.offline, .signInExpired]
	)
	func unavailableFailsWithReason(_ subject: ContractSubject, reason: ServiceError.Reason) async throws {
		let (service, catalog) = try await subject.make()
		let track = try #require(catalog.first)
		let firstPage = try await service.songs(since: nil, after: nil)
		let next = try #require(firstPage.next, "The catalog must span more than one page")

		try await subject.makeUnavailable(service, reason)

		await #expect(throws: ServiceError.unavailable(reason)) {
			try await service.songs(since: nil, after: next)
		}
		await #expect(throws: ServiceError.unavailable(reason)) {
			try await service.search(subject.broadSearchTerm, limit: 1)
		}
		await #expect(throws: ServiceError.unavailable(reason)) {
			try await service.playable(for: track)
		}
	}

	@Test("A cancelled listing stops instead of returning another page", arguments: ContractSubject.all)
	func cancelledListingStops(_ subject: ContractSubject) async throws {
		let (service, _) = try await subject.make()
		let next = try #require(try await service.songs(since: nil, after: nil).next)

		let listing = Task {
			withUnsafeCurrentTask { $0?.cancel() }
			return try await service.songs(since: nil, after: next)
		}

		await #expect(throws: CancellationError.self) {
			try await listing.value
		}
	}
}

/// Every page of one listing, pulled until the last.
private struct Listing {
	var pages: [SongPage] = []

	var listed: [SourceTrackID] { pages.flatMap { $0.tracks.map(\.id) } }
	var deleted: [SourceTrackID] { pages.flatMap(\.deleted) }
	var coverage: SongPage.Coverage? { pages.last?.coverage }
	var mark: RefreshMark? { pages.last?.mark }

	static func collect(from service: any Service, since mark: RefreshMark?) async throws -> Listing {
		var listing = Listing()
		var cursor: PageCursor?
		repeat {
			let page = try await service.songs(since: mark, after: cursor)
			listing.pages.append(page)
			cursor = page.next
		} while cursor != nil
		return listing
	}
}
