import GlinskiEngine
import Testing
@testable import GlinskiFeature

@MainActor
struct GameStoreTests {
    @Test func startsWithAFreshGameByDefault() {
        #expect(GameStore().state == GameFeature.State())
    }

    @Test func restoresAGivenState() {
        let saved = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")))
        #expect(GameStore(state: saved).state == saved)
    }

    @Test func sendRunsTheReducer() {
        let store = GameStore()
        store.send(.cellTapped(c("e4")))
        store.send(.cellTapped(c("e6")))
        #expect(store.state == GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6"))))
    }
}
