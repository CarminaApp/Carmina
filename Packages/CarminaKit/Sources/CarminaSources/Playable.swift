// SPDX-License-Identifier: GPL-3.0-or-later

public import Foundation

/// What a renderer needs to start playing a source track.
public enum Playable: Hashable, Sendable {
	/// A local file or a stream the Carmina renderer can open.
	case url(URL)
}
