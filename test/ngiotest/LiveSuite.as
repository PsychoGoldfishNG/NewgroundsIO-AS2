/**
 * LiveSuite
 *
 * Base class for suites that talk to the real gateway.
 *
 * All live suites share one NGIO instance, because NGIO is a static facade and
 * calling init() twice logs a warning and keeps the first Core. Sharing is also
 * what the tests want: the session established by the session suite has to be
 * visible to the medal, scoreboard and cloud save suites that follow.
 *
 * Members here are public rather than protected because AS2 has no protected,
 * and its `private` is not reachable from a subclass at all.
 */
import io.newgrounds.Core;
import io.newgrounds.models.objects.User;

class ngiotest.LiveSuite extends ngiotest.TestSuite {

	/**
	 * Guards the one-time NGIO.init() across every live suite.
	 *
	 * Always referenced as ngiotest.LiveSuite.didInit, never bare and never
	 * through a subclass: AS2 does not inherit statics, so a subclass reading
	 * `didInit` would silently get undefined and re-initialise.
	 */
	private static var didInit:Boolean = false;

	/**
	 * Set once the gateway has stopped answering.
	 *
	 * Like didInit, always referenced as ngiotest.LiveSuite.gatewayStopped -
	 * AS2 does not inherit statics, so a subclass reading it bare would get
	 * undefined and carry on hammering a gateway that has already cut us off.
	 */
	private static var gatewayStopped:Boolean = false;

	public function LiveSuite() {
		super();
		isLive = true;
	}

	public function setUp(done:Function):Void {
		if (!ngiotest.LiveSuite.didInit) {
			// Applied before init(), because Core reads GATEWAY_URL when it
			// loads the policy file and every request afterwards. Does nothing
			// unless someone has uncommented the override.
			ngiotest.TestConfig.applyGatewayOverride();

			NGIO.init(
				ngiotest.TestConfig.APP_ID,
				ngiotest.TestConfig.ENCRYPTION_KEY,
				ngiotest.TestConfig.BUILD_VERSION,
				ngiotest.TestConfig.USE_DEBUG_MODE
			);

			// Record gateway traffic so a failing test can show it. Attach
			// immediately after init, because init() itself fires App.logView
			// and that exchange is worth having if it goes wrong.
			if (ngiotest.TestConfig.CAPTURE_PACKETS_ON_FAILURE) {
				ngiotest.NetworkLog.attach(NGIO.core);
			}
			if (ngiotest.TestConfig.TRACE_ALL_PACKETS) {
				NGIO.core.debugNetworkCalls = true;
			}

			ngiotest.LiveSuite.didInit = true;
		}
		done.call(null);
	}

	//==================== SHARED HELPERS ====================

	/** The Core the live suites share */
	public function getCore():io.newgrounds.Core {
		return NGIO.core;
	}

	/** True when a Newgrounds user is signed in */
	public function isSignedIn():Boolean {
		return (NGIO.core != null) && NGIO.hasUser();
	}

	/** The signed-in user, or null */
	public function getUser():io.newgrounds.models.objects.User {
		return isSignedIn() ? io.newgrounds.models.objects.User(NGIO.getUser()) : null;
	}

	/**
	 * Skip the current test when no user is signed in.
	 *
	 * Session-gated components (medal unlocks, score posts, cloud saves) cannot
	 * be exercised as a guest, and reporting them as failures would drown out
	 * real regressions on a guest-only run.
	 *
	 * @return true if the test was skipped and should return immediately
	 */
	public function skipUnlessSignedIn(t:ngiotest.TestContext):Boolean {
		if (!isSignedIn()) {
			t.skip("needs a signed-in user");
			return true;
		}
		return false;
	}

	/**
	 * Turn whatever the library handed back as an "error" into something
	 * readable. Errors arrive as NgioError models, but a transport failure can
	 * produce a plain Error or a String.
	 */
	public function describeError(error):String {
		if (error == null || error == undefined) {
			return "null";
		}
		if (typeof(error) == "string") {
			return String(error);
		}
		if (error.code != undefined || error.message != undefined) {
			return "[" + error.code + "] " + error.message;
		}
		return String(error);
	}

	/**
	 * Standard "the call came back clean" assertion.
	 *
	 * @return true when there was no error, so callers can guard the rest of
	 *         their assertions on it
	 */
	public function assertNoError(t:ngiotest.TestContext, error, label:String):Boolean {
		if (error == null || error == undefined) {
			return t.assert(true, label);
		}

		// A request that never got an answer is not a result about the library.
		// Reporting it as a failure buries the real regressions - and worse, the
		// tests around it that assert an ABSENCE go green, because an empty cache
		// looks the same whether the guard worked or the load never happened.
		if (isTransportFailure(error)) {
			stopLiveTesting(t, label);
			return false;
		}

		t.fail(label + " -- gateway returned " + describeError(error));
		return false;
	}

	/**
	 * True when this error means "no answer came back", rather than "the gateway
	 * answered and said no".
	 */
	public function isTransportFailure(error):Boolean {
		if (error == null || error == undefined) {
			return false;
		}

		// The unambiguous case: the gateway told us in so many words. Only
		// reachable when the player reported a real HTTP status, which in AS2 is
		// the exception rather than the rule - hence the observer check below.
		if (error.code == io.newgrounds.Errors.TOO_MANY_REQUESTS) {
			return true;
		}

		// Otherwise ask what the transport actually saw. Structural rather than
		// matching on the message text, and it does not confuse "nothing came
		// back" with "a 2xx whose body would not parse" - those share an error
		// code but not an observer event. See NetworkLog.transportFailures().
		return (ngiotest.NetworkLog.transportFailures() > 0);
	}

	/**
	 * Skip this test and abandon the rest of the live run.
	 *
	 * Stopping early is the point rather than a side effect: the gateway limits a
	 * COUNT of requests per window, so continuing to fire tests at a gateway that
	 * has already refused us spends the next window's budget too, and turns a
	 * short cool-off into a long one.
	 */
	public function stopLiveTesting(t:ngiotest.TestContext, label:String):Void {
		var reason:String = "the gateway stopped answering (" +
			ngiotest.NetworkLog.transportFailures() + " request(s) got no response after " +
			ngiotest.NetworkLog.totalRequests() + " sent)";

		if (!ngiotest.LiveSuite.gatewayStopped) {
			ngiotest.LiveSuite.gatewayStopped = true;
			t.note("STOPPING LIVE TESTS: " + reason +
				". Most likely the request-count rate limit - wait a few minutes " +
				"before re-running, and do not re-run immediately, which spends " +
				"the next window as well.");

			if (runner != null) {
				runner.abortLiveSuites(reason);
			}
		}

		// Reported as the reason alone. The assertion label is phrased as a
		// positive claim ("newgrounds url resolved without error"), so gluing it
		// to a skip reason reads as a contradiction - and the Reporter already
		// prints the test name, which identifies the test just as well.
		t.skip(reason);
	}

	/**
	 * Skip immediately when the gateway has already given up on us.
	 *
	 * The runner skips whole live SUITES once aborted; this is for the remaining
	 * cases inside the suite that was running when it happened.
	 *
	 * @return true if the test was skipped and should return immediately
	 */
	public function skipIfGatewayStopped(t:ngiotest.TestContext):Boolean {
		if (ngiotest.LiveSuite.gatewayStopped) {
			t.skip("the gateway stopped answering earlier in this run");
			return true;
		}
		return false;
	}
}
