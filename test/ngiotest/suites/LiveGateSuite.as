/**
 * LiveGateSuite
 *
 * Sits between the offline and live suites and asks before going online.
 *
 * Live testing opens a browser window for Passport sign-in and writes to a real
 * Newgrounds account, so it should not start just because someone pressed
 * Ctrl+Enter. Clicking proceeds; ignoring the prompt abandons the live suites
 * and leaves the offline results readable.
 *
 * Set TestConfig.CONFIRM_BEFORE_LIVE = false to go straight through, or
 * TestConfig.RUN_LIVE_TESTS = false to drop the live suites entirely.
 *
 * Note this extends TestSuite rather than LiveSuite: it must not trigger
 * NGIO.init(), because the whole point is to ask BEFORE anything reaches the
 * network. It sets isLive itself so that switching live testing off removes the
 * prompt along with everything else.
 */
import ngiotest.TestConfig;
import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.LiveGateSuite extends ngiotest.TestSuite {

	/** How long to wait for a decision before assuming "no" */
	private static var DECISION_TIMEOUT_MS:Number = 90000;

	public function LiveGateSuite() {
		super();
		isLive = true;
	}

	public function getSuiteName():String {
		return "Live / Confirmation";
	}

	public function build():Void {

		// Captured because AS2 closures do not bind `this`, and the timeout
		// handler below needs the runner to call off the rest of the live run.
		var self:ngiotest.suites.LiveGateSuite = this;
		var decisionTimeout:Number = ngiotest.suites.LiveGateSuite.DECISION_TIMEOUT_MS;

		if (!ngiotest.TestConfig.CONFIRM_BEFORE_LIVE) {
			add("proceeding to live tests without confirmation", function(t:ngiotest.TestContext):Void {
				t.note("TestConfig.CONFIRM_BEFORE_LIVE is false");
				t.assert(true, "gate disabled");
				t.done();
			});
			return;
		}

		addSlow("waits for permission to go online", decisionTimeout, function(t:ngiotest.TestContext):Void {
			var decided:Boolean = false;

			t.prompt(
				"OFFLINE TESTS FINISHED\n\n" +
				"Scroll the Output panel to review them.\n\n" +
				"The live tests contact the Newgrounds gateway, may open a browser\n" +
				"window to sign in, and write to app '" + ngiotest.TestConfig.APP_ID + "'.\n\n" +
				"Click below to continue, or wait " + Math.round(decisionTimeout / 1000) +
				" seconds to stop here.",
				"Run live tests",
				function():Void {
					decided = true;
					t.note("live testing confirmed");
					t.assert(true, "user opted in");
					t.status("Starting live tests...");
					t.done();
				}
			);

			// The runner's watchdog fires if nobody clicks. Rather than let that
			// be recorded as a failure, convert it into a clean stop.
			t.onTimeout = function():Void {
				if (decided) {
					return;
				}
				if (self.runner != null) {
					self.runner.abortLiveSuites("live testing was declined");
				}
				t.skip("no response - live tests skipped");
			};
		});
	}
}
