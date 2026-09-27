import Observation

/// The single source of truth a view observes. All logic lives in `GameFeature.reduce`.
@Observable @MainActor
public final class GameStore {
    public private(set) var state: GameFeature.State

    public init(state: GameFeature.State = .init()) {
        self.state = state
    }

    public func send(_ intent: GameFeature.Intent) {
        GameFeature.reduce(&state, intent)
    }
}
