import XCTest

final class SmokeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        addUIInterruptionMonitor(withDescription: "System permission") { alert in
            for label in ["Allow", "Don’t Allow", "Don't Allow", "OK"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            if alert.buttons.count > 0 {
                alert.buttons.element(boundBy: 0).tap()
                return true
            }
            return false
        }
    }

    private func launchApp(seed: Bool = true, premium: Bool = false, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        var args = [
            "-resetData", "YES",
            "-onboardingCompleted", "YES",
            "-postOnboardingCompleted", "YES",
            "-skipSplash", "YES",
            "-appearanceMode", "light"
        ]
        if seed { args += ["-seedDemo", "YES"] }
        if premium { args += ["-seedPremium", "YES"] }
        app.launchArguments = args + extra
        app.launch()
        return app
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) {
        var attempts = 0
        while attempts < maxSwipes {
            let frame = element.frame
            let safeBottom = app.frame.maxY - 110
            if element.isHittable && frame.maxY < safeBottom && frame.minY > 80 {
                return
            }
            if frame.minY > 0 && frame.minY < 90 {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
            attempts += 1
        }
    }

    private func tapTab(_ tab: String, in app: XCUIApplication) {
        let button = app.buttons["tab.\(tab)"]
        XCTAssertTrue(button.waitForExistence(timeout: 8), "Missing tab \(tab)")
        button.tap()
    }

    // MARK: - Seeded navigation

    func testSeededNavigationAndDetailSheets() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Heart Rate"].exists)

        tapTab("dashboard", in: app)
        XCTAssertTrue(app.staticTexts["Dashboard"].waitForExistence(timeout: 6))
        let metric = app.buttons["dashboard.metric.healthIndex"]
        XCTAssertTrue(metric.waitForExistence(timeout: 4))
        metric.tap()
        XCTAssertTrue(app.staticTexts["Compare your latest result with your average values"].waitForExistence(timeout: 6))
        app.buttons["metric.close"].tap()

        app.buttons["dashboard.chartSettings"].tap()
        XCTAssertTrue(app.navigationBars["Chart Settings"].waitForExistence(timeout: 6))
        app.buttons["Save"].tap()

        tapTab("insights", in: app)
        XCTAssertTrue(app.staticTexts["Insights"].waitForExistence(timeout: 6))
        let article = app.buttons["popular.hrv-basics.how_hrv_works"]
        XCTAssertTrue(article.waitForExistence(timeout: 4))
        article.tap()
        XCTAssertTrue(app.staticTexts["PAGE 1"].waitForExistence(timeout: 6))
        app.buttons["article.close"].tap()
        XCTAssertTrue(app.staticTexts["Insights"].waitForExistence(timeout: 6))

        tapTab("me", in: app)
        XCTAssertTrue(app.staticTexts["My Statistics"].waitForExistence(timeout: 6))
        let pulseRow = app.staticTexts["Pulse"]
        XCTAssertTrue(pulseRow.waitForExistence(timeout: 6))
        pulseRow.tap()
        XCTAssertTrue(app.staticTexts["Compare your latest result with your average values"].waitForExistence(timeout: 6))
        app.buttons["metric.close"].tap()
        let achievements = app.buttons["me.achievements"]
        scrollTo(achievements, in: app)
        achievements.tap()
        XCTAssertTrue(app.staticTexts["Achievements"].waitForExistence(timeout: 6))
        app.buttons["achievements.close"].tap()

        app.buttons["me.profile"].tap()
        XCTAssertTrue(app.staticTexts["My Profile"].waitForExistence(timeout: 6))
        app.buttons["profile.close"].tap()

        app.buttons["me.settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 6))
        app.buttons["settings.close"].tap()

        tapTab("home", in: app)
        let history = app.buttons["home.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 6))
        history.tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 6))
        app.buttons["history.close"].tap()

        let journey = app.buttons["home.journey"]
        scrollTo(journey, in: app)
        journey.tap()
        XCTAssertTrue(app.staticTexts["Chapters"].waitForExistence(timeout: 6))
        app.buttons["journey.chapter.CH01"].tap()
        let level = app.staticTexts["Easy Start"]
        XCTAssertTrue(level.waitForExistence(timeout: 6))
        level.tap()
        XCTAssertTrue(app.staticTexts["Main"].waitForExistence(timeout: 6))
        app.buttons["journey.back"].tap()
        app.buttons["journey.back"].tap()
        app.buttons["journey.close"].tap()
    }

    // MARK: - Empty state

    func testEmptyStateScreensDoNotCrash() {
        let app = launchApp(seed: false)
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 12))

        app.buttons["home.history"].tap()
        XCTAssertTrue(app.staticTexts["No Records Yet"].waitForExistence(timeout: 6))
        app.buttons["history.close"].tap()

        tapTab("dashboard", in: app)
        XCTAssertTrue(app.staticTexts["Dashboard"].waitForExistence(timeout: 6))
        app.buttons["dashboard.metric.healthIndex"].tap()
        XCTAssertTrue(app.staticTexts["No Data"].waitForExistence(timeout: 6))
        app.buttons["metric.close"].tap()

        tapTab("me", in: app)
        XCTAssertTrue(app.staticTexts["My Statistics"].waitForExistence(timeout: 6))
        app.buttons["me.monthly"].tap()
        XCTAssertTrue(app.staticTexts["Monthly Insights"].waitForExistence(timeout: 6))
        app.buttons["Not now"].tap()

        let appleHealth = app.buttons["me.appleHealth"]
        scrollTo(appleHealth, in: app)
        appleHealth.tap()
        XCTAssertTrue(app.staticTexts["Apple Health"].waitForExistence(timeout: 6))
        app.buttons["applehealth.close"].tap()

        let achievements = app.buttons["me.achievements"]
        scrollTo(achievements, in: app)
        achievements.tap()
        XCTAssertTrue(app.staticTexts["Achievements"].waitForExistence(timeout: 6))
        app.buttons["achievements.close"].tap()
    }

    // MARK: - Measurement

    func testMeasurementFlowCompletes() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 12))
        app.buttons["tab.measure"].tap()
        XCTAssertTrue(app.staticTexts["Step 1 · Calibrating"].waitForExistence(timeout: 8))
        app.buttons["measure.mode.fast"].tap()
        XCTAssertTrue(app.staticTexts["Measurement Complete"].waitForExistence(timeout: 35))
        app.buttons["result.continue"].tap()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 8))
    }

    // MARK: - Metric detail regression

    func testMetricDetailPathsDoNotCrash() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 12))
        tapTab("dashboard", in: app)
        XCTAssertTrue(app.staticTexts["Dashboard"].waitForExistence(timeout: 6))

        for identifier in ["dashboard.metric.hrv", "dashboard.metric.rmssd"] {
            let card = app.buttons[identifier]
            XCTAssertTrue(card.waitForExistence(timeout: 6))
            card.tap()
            XCTAssertTrue(app.staticTexts["Compare your latest result with your average values"].waitForExistence(timeout: 6))
            app.buttons["metric.close"].tap()
        }

        let csi = app.buttons["dashboard.csi"]
        scrollTo(csi, in: app)
        csi.tap()
        XCTAssertTrue(app.staticTexts["Stress Index"].waitForExistence(timeout: 6))
        app.buttons["metric.close"].tap()

        tapTab("me", in: app)
        XCTAssertTrue(app.staticTexts["Pulse"].waitForExistence(timeout: 6))
        app.staticTexts["Pulse"].tap()
        XCTAssertTrue(app.staticTexts["Compare your latest result with your average values"].waitForExistence(timeout: 6))
        app.buttons["metric.close"].tap()
    }

    // MARK: - Logs / settings / paywall

    func testManualLogSettingsAndPaywall() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 12))
        app.buttons["home.history"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 6))
        app.buttons["history.add"].tap()
        app.buttons["Log Pressure"].tap()
        XCTAssertTrue(app.staticTexts["Blood Pressure"].waitForExistence(timeout: 6))
        app.buttons["Log Blood Pressure"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 6))
        app.buttons["history.close"].tap()

        tapTab("me", in: app)
        XCTAssertTrue(app.staticTexts["My Statistics"].waitForExistence(timeout: 6))
        app.buttons["me.settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 6))
        app.buttons["settings.reminders"].tap()
        XCTAssertTrue(app.staticTexts["Daily Reminders"].waitForExistence(timeout: 6))
        app.buttons["reminders.close"].tap()
        app.buttons["settings.appleHealth"].tap()
        XCTAssertTrue(app.staticTexts["Apple Health"].waitForExistence(timeout: 6))
        app.buttons["applehealth.close"].tap()
        app.buttons["settings.close"].tap()

        tapTab("home", in: app)
        let premium = app.buttons["home.premium"]
        scrollTo(premium, in: app)
        premium.tap()
        XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 8))
        app.buttons["paywall.purchase"].tap()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 8))
    }

    func testPremiumMonthlyOpensWithoutPromo() {
        let app = launchApp(premium: true, extra: ["-showMonthly", "YES"])
        XCTAssertTrue(app.staticTexts["Day Average"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Monthly Insights"].exists)
        app.buttons["monthly.close"].tap()
    }

    // MARK: - Onboarding

    func testOnboardingAndAssessmentFlow() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-resetData", "YES",
            "-resetOnboarding", "YES",
            "-skipSplash", "YES"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 12))
        for _ in 0..<4 {
            app.buttons["Continue"].tap()
        }
        app.buttons["Personalize My Journey"].tap()

        XCTAssertTrue(app.buttons["Continue with Free Plan"].waitForExistence(timeout: 6))
        app.buttons["Continue with Free Plan"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 6))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 6))
        let notificationToggle = app.switches["onboarding.notificationToggle"]
        if notificationToggle.exists, (notificationToggle.value as? String) == "1" {
            notificationToggle.tap()
        }
        app.buttons["Get Started"].tap()

        XCTAssertTrue(app.buttons["Proceed Without Apple Health"].waitForExistence(timeout: 10))
        app.buttons["Proceed Without Apple Health"].tap()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 6))
        app.buttons["Continue"].tap()

        for index in 0..<3 {
            let answer = index == 1 ? app.buttons["Rarely"] : app.buttons["Yes"]
            XCTAssertTrue(answer.waitForExistence(timeout: 6))
            answer.tap()
            let next = app.buttons["Next"]
            if next.exists {
                next.tap()
            } else {
                app.buttons["See My Analysis"].tap()
            }
        }

        XCTAssertTrue(app.buttons["See Results"].waitForExistence(timeout: 12))
        app.buttons["See Results"].tap()
        XCTAssertTrue(app.buttons["Start Your Journey"].waitForExistence(timeout: 6))
        app.buttons["Start Your Journey"].tap()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 10))
    }
}
