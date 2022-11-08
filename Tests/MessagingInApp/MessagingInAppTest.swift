@testable import CioMessagingInApp
@testable import CioTracking
@testable import Common
import Foundation
@testable import Gist
import SharedTests
import XCTest

class MessagingInAppTest: UnitTest {
    private var messagingInApp: MessagingInApp!

    private let inAppProviderMock = InAppProviderMock()
    private let eventListenerMock = InAppEventListenerMock()
    private let queueMock = QueueMock()

    override func setUp() {
        super.setUp()

        diGraph.override(value: inAppProviderMock, forType: InAppProvider.self)
        diGraph.override(value: queueMock, forType: Queue.self)

        messagingInApp = MessagingInApp(diGraph: diGraph, siteId: testSiteId, eventListener: eventListenerMock)
    }

    // MARK: initialize

    func test_initialize_givenOrganizationId_expectInitializeGistSDK() {
        let givenId = String.random

        messagingInApp.initialize(organizationId: givenId)

        XCTAssertTrue(inAppProviderMock.initializeCalled)
    }

    // MARK: profile hooks

    func test_givenProfileIdentified_expectSetupWithInApp() {
        let given = String.random

        messagingInApp.profileIdentified(identifier: given)

        XCTAssertEqual(inAppProviderMock.setProfileIdentifierCallsCount, 1)
        XCTAssertEqual(inAppProviderMock.setProfileIdentifierReceivedArguments, given)
    }

    func test_givenProfileNoLongerIdentified_expectRemoveFromInApp() {
        messagingInApp.beforeProfileStoppedBeingIdentified(oldIdentifier: String.random)

        XCTAssertEqual(inAppProviderMock.clearIdentifyCallsCount, 1)
    }

    // MARK: screen view hooks

    func test_givenScreenViewed_expectSetRouteOnInApp() {
        let given = String.random

        messagingInApp.screenViewed(name: given)

        XCTAssertEqual(inAppProviderMock.setRouteCallsCount, 1)
        XCTAssertEqual(inAppProviderMock.setRouteReceivedArguments, given)
    }

    // MARK: event listeners

    func test_eventListeners_expectCallListenerWithData() {
        let givenGistMessage = Message.random
        let expectedInAppMessage = InAppMessage(gistMessage: givenGistMessage)

        queueMock.addTrackInAppDeliveryTaskReturnValue = ModifyQueueResult(
            success: true,
            QueueStatus(queueId: .random, numTasksInQueue: 1)
        )

        // Message opened
        XCTAssertFalse(eventListenerMock.messageOpenedCalled)
        messagingInApp.messageShown(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.messageOpenedCallsCount, 1)
        XCTAssertEqual(eventListenerMock.messageOpenedReceivedArguments, expectedInAppMessage)

        // message dismissed
        XCTAssertFalse(eventListenerMock.messageDismissedCalled)
        messagingInApp.messageDismissed(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.messageDismissedCallsCount, 1)
        XCTAssertEqual(eventListenerMock.messageDismissedReceivedArguments, expectedInAppMessage)

        // error with message
        XCTAssertFalse(eventListenerMock.errorWithMessageCalled)
        messagingInApp.messageError(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.errorWithMessageCallsCount, 1)
        XCTAssertEqual(eventListenerMock.errorWithMessageReceivedArguments, expectedInAppMessage)

        // message action taken
        XCTAssertFalse(eventListenerMock.messageActionTakenCalled)
        let givenCurrentRoute = String.random
        let givenAction = String.random
        let givenName = String.random
        messagingInApp.action(
            message: givenGistMessage,
            currentRoute: givenCurrentRoute,
            action: givenAction,
            name: givenName
        )
        XCTAssertEqual(eventListenerMock.messageActionTakenCallsCount, 1)
        XCTAssertEqual(eventListenerMock.messageActionTakenReceivedArguments?.message, expectedInAppMessage)
        XCTAssertEqual(eventListenerMock.messageActionTakenReceivedArguments?.currentRoute, givenCurrentRoute)
        XCTAssertEqual(eventListenerMock.messageActionTakenReceivedArguments?.action, givenAction)
        XCTAssertEqual(eventListenerMock.messageActionTakenReceivedArguments?.name, givenName)
    }

    func test_eventListeners_expectCallListenerForEachEvent() {
        let givenGistMessage = Message.random

        queueMock.addTrackInAppDeliveryTaskReturnValue = ModifyQueueResult(
            success: true,
            QueueStatus(queueId: .random, numTasksInQueue: 1)
        )

        // Message opened
        XCTAssertEqual(eventListenerMock.messageOpenedCallsCount, 0)
        messagingInApp.messageShown(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.messageOpenedCallsCount, 1)
        messagingInApp.messageShown(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.messageOpenedCallsCount, 2)

        // message dismissed
        XCTAssertEqual(eventListenerMock.messageDismissedCallsCount, 0)
        messagingInApp.messageDismissed(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.messageDismissedCallsCount, 1)
        messagingInApp.messageDismissed(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.messageDismissedCallsCount, 2)

        // error with message
        XCTAssertEqual(eventListenerMock.errorWithMessageCallsCount, 0)
        messagingInApp.messageError(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.errorWithMessageCallsCount, 1)
        messagingInApp.messageError(message: givenGistMessage)
        XCTAssertEqual(eventListenerMock.errorWithMessageCallsCount, 2)

        // message action taken
        XCTAssertEqual(eventListenerMock.messageActionTakenCallsCount, 0)
        messagingInApp.action(message: givenGistMessage, currentRoute: .random, action: .random, name: .random)
        XCTAssertEqual(eventListenerMock.messageActionTakenCallsCount, 1)
        messagingInApp.action(message: givenGistMessage, currentRoute: .random, action: .random, name: .random)
        XCTAssertEqual(eventListenerMock.messageActionTakenCallsCount, 2)
    }
}
