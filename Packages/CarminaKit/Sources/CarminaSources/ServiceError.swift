// SPDX-License-Identifier: GPL-3.0-or-later

/// The only errors an adapter throws, apart from `CancellationError`.
public enum ServiceError: Error, Hashable, Sendable {
	/// The source track is no longer on its source.
	case trackNotFound
	/// The service can never do this: it isn't among the service's capabilities.
	case unsupported
	/// The source can't answer right now. Retrying can work once the reason is resolved.
	case unavailable(Reason)

	public enum Reason: Hashable, Sendable {
		case offline
		/// The listener has to sign in to the server again.
		case signInExpired
	}
}
