/**
 * NgioUnitTest
 *
 * Entry point for NgioUnitTest.fla. The .fla's first frame does:
 *
 *     import initiator.NgioUnitTest;
 *     initiator.NgioUnitTest.startTests(this);
 *
 * with its AS2 class paths set to "." and "..\build" - so this file lives under
 * test/ and the library under build/.
 *
 * Everything this class does is wiring: find the three stage objects, hand them
 * to the harness, register the suites, and start the run. Results go to trace(),
 * which lands in the Flash IDE Output panel.
 */
import ngiotest.Reporter;
import ngiotest.TestRunner;
import ngiotest.TestUI;

import ngiotest.suites.LiveAppDataSuite;
import ngiotest.suites.LiveCloudSaveSuite;
import ngiotest.suites.LiveCrossAppSuite;
import ngiotest.suites.LiveGateSuite;
import ngiotest.suites.LiveGatewaySuite;
import ngiotest.suites.LiveGuestSuite;
import ngiotest.suites.LiveLoaderSuite;
import ngiotest.suites.LiveMedalSuite;
import ngiotest.suites.LiveNoSessionSuite;
import ngiotest.suites.LiveScoreBoardSuite;
import ngiotest.suites.LiveSessionSuite;
import ngiotest.suites.LiveSignInSuite;
import ngiotest.suites.OfflineBaseObjectSuite;
import ngiotest.suites.OfflineCryptoSuite;
import ngiotest.suites.OfflineForeignGuardSuite;
import ngiotest.suites.OfflineJsonSuite;
import ngiotest.suites.OfflineModelSuite;
import ngiotest.suites.OfflineObjectFactorySuite;
import ngiotest.suites.OfflineWireFormatSuite;

class initiator.NgioUnitTest {

	/** The run in progress, kept alive for the length of the session */
	public static var instance:initiator.NgioUnitTest;

	//==================== ENTRY POINT ====================

	/**
	 * Called from the .fla's first frame.
	 *
	 * @param caller The timeline holding infoText, inputButton and
	 *               inputButtonLabel - normally `this`
	 */
	public static function startTests(caller:MovieClip):Void {
		if (instance != null) {
			trace("NgioUnitTest: already running, ignoring a second startTests() call");
			return;
		}

		// A symbol placed on the stage with "Button" behaviour is a Button, not
		// a MovieClip. The lookup below deliberately does no casting at all -
		// TestUI holds the control untyped, so a Button, a MovieClip or a Sprite
		// all work, and none of them can be silently turned into null by a bad
		// cast. The AS3 side had exactly that bug, which disabled every
		// interactive test without an error.
		//
		// inputButton2 / inputButtonLabel2 are OPTIONAL. A stage without them
		// yields undefined here, TestUI.hasButton2() reports false, and the one
		// test that needs a two-way choice skips with a reason instead of
		// hanging.
		instance = new initiator.NgioUnitTest(
			TextField(caller["infoText"]),
			caller["inputButton"],
			TextField(caller["inputButtonLabel"]),
			caller["inputButton2"],
			TextField(caller["inputButtonLabel2"])
		);
	}

	//==================== PROPERTIES ====================

	private var ui:ngiotest.TestUI;
	private var runner:ngiotest.TestRunner;

	//==================== CONSTRUCTOR ====================

	public function NgioUnitTest(infoText:TextField, inputButton, inputButtonLabel:TextField,
	                             inputButton2, inputButtonLabel2:TextField) {
		ui = new ngiotest.TestUI(infoText, inputButton, inputButtonLabel, inputButton2, inputButtonLabel2);
		ui.setInfo("Running tests...\n\nResults appear in the Output panel.");

		if (infoText == null || infoText == undefined) {
			trace("NgioUnitTest: WARNING - no 'infoText' field found on the stage. " +
			      "Progress messages will only appear in the Output panel.");
		}
		if (inputButton == null || inputButton == undefined) {
			trace("NgioUnitTest: WARNING - no 'inputButton' found on the stage. " +
			      "Tests that need a click (Passport sign-in) will be skipped.");
		}
		if (inputButton2 == null || inputButton2 == undefined) {
			trace("NgioUnitTest: NOTE - no 'inputButton2' found on the stage. " +
			      "The session hand-off choice will be skipped; everything else runs.");
		}

		runner = new ngiotest.TestRunner(ui);
		registerSuites();

		var self:initiator.NgioUnitTest = this;
		runner.run(function(finishedRunner:ngiotest.TestRunner):Void {
			self.onRunComplete(finishedRunner);
		});
	}

	//==================== SUITE REGISTRATION ====================

	/**
	 * Order matters. Offline suites run first because they need nothing and
	 * localise failures best. Among the live suites, Gateway proves basic
	 * connectivity, Session establishes the login the rest depend on, and App
	 * data fills the caches the medal/scoreboard/save suites read.
	 */
	private function registerSuites():Void {
		// --- offline: no network, no login ---
		runner.addSuite(new ngiotest.suites.OfflineBaseObjectSuite());
		runner.addSuite(new ngiotest.suites.OfflineObjectFactorySuite());
		runner.addSuite(new ngiotest.suites.OfflineJsonSuite());
		runner.addSuite(new ngiotest.suites.OfflineCryptoSuite());
		runner.addSuite(new ngiotest.suites.OfflineWireFormatSuite());
		runner.addSuite(new ngiotest.suites.OfflineModelSuite());
		runner.addSuite(new ngiotest.suites.OfflineForeignGuardSuite());

		// --- live: real gateway ---
		//
		// The first four walk the session states in order, and the order is the
		// whole point - each one tests something only reachable before the next
		// has run:
		//
		//   No session   nothing has opened one yet (init only fires App.logView)
		//   Session      a session appears, and an existing one may be ended
		//   Guest        session id, no user - only if one was just ended
		//   Sign-in      Passport attaches a user
		//
		// Inserting anything that touches checkSession before LiveNoSessionSuite
		// closes that window permanently.
		runner.addSuite(new ngiotest.suites.LiveGateSuite());
		runner.addSuite(new ngiotest.suites.LiveGatewaySuite());
		runner.addSuite(new ngiotest.suites.LiveNoSessionSuite());
		runner.addSuite(new ngiotest.suites.LiveSessionSuite());
		runner.addSuite(new ngiotest.suites.LiveGuestSuite());
		runner.addSuite(new ngiotest.suites.LiveSignInSuite());
		runner.addSuite(new ngiotest.suites.LiveAppDataSuite());
		runner.addSuite(new ngiotest.suites.LiveMedalSuite());
		runner.addSuite(new ngiotest.suites.LiveScoreBoardSuite());
		runner.addSuite(new ngiotest.suites.LiveCloudSaveSuite());
		// After the suites that populate the local caches, so it has something
		// real to prove a foreign read cannot disturb
		runner.addSuite(new ngiotest.suites.LiveCrossAppSuite());
		runner.addSuite(new ngiotest.suites.LiveLoaderSuite());
	}

	//==================== COMPLETION ====================

	/** Public because the run callback reaches it through `self`. */
	public function onRunComplete(finishedRunner:ngiotest.TestRunner):Void {
		if (finishedRunner.failedCount > 0) {
			ngiotest.Reporter.line("Scroll up for the [FAIL] lines - each one names the assertion that broke.");
		}
	}
}
