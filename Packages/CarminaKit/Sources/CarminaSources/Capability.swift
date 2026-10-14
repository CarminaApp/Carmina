// SPDX-License-Identifier: GPL-3.0-or-later

/// An optional part of the Service port that a service may support.
///
/// Decided when the source connects, from the service, its server version and the OS. A capability that
/// isn't declared can never work; one that is declared can still fail while the source is unavailable.
public enum Capability: Hashable, Sendable {
	/// Saving a source track on the device for offline play.
	case download
}
