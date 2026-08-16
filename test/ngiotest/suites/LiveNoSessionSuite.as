/**
 * LiveNoSessionSuite
 *
 * Everything the gateway will do for a client that has NO session at all.
 *
 * Runs immediately after LiveGatewaySuite and before LiveSessionSuite, in the
 * window between NGIO.init() and the first checkSession(). That window is real
 * and stable: init() only fires App.logView, which needs no session, and the
 * keepAlive interval started alongside it returns early unless hasUser(), so
 * nothing can quietly open a session behind these tests.
 *
 * WHY IT IS WORTH HAVING. Sixteen of the twenty-five components never touch a
 * session, and games use them that way - a medal list or a high score table
 * shown on a title screen, before anyone has signed in. Nothing else in the
 * suite proves those calls work with no session_id in the envelope, because
 * every other live suite runs after the session exists.
 *
 * It also loads the medal and scoreboard lists early, which the guest suite
 * later reuses.
 */
import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveNoSessionSuite extends ngiotest.LiveSuite {

	/**
	 * False once anything has opened a session, which makes the whole suite
	 * meaningless. Static for the same reason LiveSuite.didInit is - and read
	 * through the full path, because AS2 does not inherit statics.
	 */
	private static var sessionFree:Boolean = true;

	public function LiveNoSessionSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / No session";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveNoSessionSuite = this;

		add("starts with no session at all", function(t:ngiotest.TestContext):Void {
			// The precondition for everything below.
			//
			// A SESSION ALREADY EXISTING IS NOT A FAILURE. AppState picks one up
			// during construction from either of TWO pre-authorised sources, and
			// both are normal:
			//
			//   1. A "remember me" session saved in the SharedObject, checked
			//      FIRST. This is the usual one when testing locally, and it does
			//      NOT set preauthenticatedId.
			//   2. ngio_session_id on the page URL, checked only if there was no
			//      saved one. This is how Newgrounds hands a logged-in session to
			//      an embedded game, and it DOES set preauthenticatedId.
			//
			// Either way there is no session-free window to test in, and the
			// honest answer is "not applicable here", not "broken". Everything
			// below skips on the same condition, so such a run reports clean
			// skips rather than a cascade of failures.
			var hasSession:Boolean = NGIO.hasSession();
			ngiotest.suites.LiveNoSessionSuite.sessionFree = !hasSession;

			if (hasSession) {
				var appState:io.newgrounds.AppState = self.getCore().appState;
				var session = appState.session;

				// preauthenticatedId is set only by the URL path, which is what
				// separates source 2 from source 1.
				var fromUrl:Boolean = (session != null &&
				                       session.preauthenticatedId != null &&
				                       session.preauthenticatedId.length > 0);

				var savedId:String = io.newgrounds.helpers.AppStateBootstrapHelper.getSavedSessionId(
					appState.sessionStorageKey);
				var remembered:Boolean = (savedId != null && savedId.length > 0);

				if (fromUrl) {
					t.skip("the page URL supplied a session id (ngio_session_id), which is normal - " +
					       "no session-free window exists in this environment");
				} else if (remembered) {
					t.skip("a remembered session was restored from the SharedObject, which is normal - " +
					       "no session-free window exists in this environment. Clear the 'ngio' " +
					       "SharedObject to run this suite");
				} else {
					// Neither source explains it, which WOULD mean the init path
					// changed. Still a skip rather than a failure - the suite
					// cannot run either way - but said plainly.
					t.skip("a session exists from neither the URL nor the SharedObject - " +
					       "worth checking whether something in the init path now opens one");
				}

				t.note("session id present before checkSession() was ever called: " +
				       self.getCore().sessionId);
				return;
			}

			t.assertFalse(NGIO.hasUser(), "and no user");
			t.assertNull(self.getCore().sessionId, "no session id on Core");
			t.note("init() fires only App.logView, so this window is genuinely session-free");
			t.done();
		});

		add("loads medals and scoreboards without a session", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSessionFree(t)) {
				return;
			}

			// One batched request for both, to keep the cost of this suite down.
			//
			// "scoreBoards", capital B - AppState.dataProperties spells it that
			// way, matching NGIO.getScoreBoards(). loadData throws on an unknown
			// name rather than ignoring it, which is how a lowercase 'b' here
			// showed up as a thrown Error rather than a silently empty result.
			NGIO.loadAppData(["medals", "scoreBoards"], function(error):Void {
				if (!self.assertNoError(t, error, "loadAppData succeeded with no session")) {
					t.done();
					return;
				}

				var medals:Array = NGIO.getMedals();
				var boards:Array = NGIO.getScoreBoards();

				if (t.assertNotNull(medals, "medals came back")) {
					t.assertEquals(ngiotest.TestConfig.EXPECTED_MEDAL_COUNT, medals.length,
						"all medals are visible to a client with no session");
				}
				if (t.assertNotNull(boards, "scoreboards came back")) {
					t.assertEquals(ngiotest.TestConfig.EXPECTED_SCOREBOARD_COUNT, boards.length,
						"all scoreboards are visible too");
				}

				t.assertFalse(NGIO.hasSession(), "and reading them did not open a session");
				t.done();
			}, null);
		});

		add("reads scores without a session", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSessionFree(t)) {
				return;
			}

			var boards:Array = NGIO.getScoreBoards();
			if (boards == null || boards.length == 0) {
				t.skip("no scoreboards loaded");
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = boards[0];
			board.getScores({ period: "A", limit: 3 }, function(scores:Array, error):Void {
				if (!self.assertNoError(t, error, "getScores succeeded with no session")) {
					t.done();
					return;
				}

				// An empty board is a valid answer - this is about whether the
				// call is permitted, not about what is on the board.
				t.assertNotNull(scores, "a score list came back");
				t.note("board '" + board.name + "' returned " + scores.length + " score(s) to a sessionless client");
				t.assertFalse(NGIO.hasSession(), "still no session");
				t.done();
			}, null);
		});

		add("resolves a loader url without a session", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSessionFree(t)) {
				return;
			}

			NGIO.loadOfficialUrl(false, function(url:String, error):Void {
				if (self.assertNoError(t, error, "loadOfficialUrl succeeded with no session")) {
					if (t.assertNotNull(url, "a url came back")) {
						t.assertTrue(url.indexOf("http") == 0, "and it is absolute");
						t.note("official url with no session: " + url);
					}
				}
				t.done();
			}, null);
		});

		//==================== THE SESSION-GATED HALF ====================

		add("an unlock with no session is refused, and by the SERVER", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSessionFree(t)) {
				return;
			}

			var medals:Array = NGIO.getMedals();
			if (medals == null || medals.length == 0) {
				t.skip("no medals loaded");
				return;
			}

			// WORTH KNOWING, and the reason this test says "by the SERVER":
			// BaseComponent.hasValidProperties() checks requiresSession and would
			// reject this before it left the machine - but NOTHING IN build/ EVER
			// CALLS IT. Confirmed by grep: the only callers are in the offline
			// tests. Every session guard in this library is server-side at
			// runtime, so the request goes out and comes back refused.
			//
			// That also means the offline test "a session-gated component is
			// invalid without a session" pins a method the library never
			// consults. Both are worth having; neither should be mistaken for the
			// other.
			var medal:io.newgrounds.models.objects.Medal = medals[0];
			medal.unlock(function(unlockedMedal:io.newgrounds.models.objects.Medal, error):Void {
				if (t.assertNotNull(error, "the unlock was refused")) {
					t.note("server said: " + self.describeError(error));
				}
				t.assertFalse(unlockedMedal.unlocked, "and the medal is not flagged unlocked");
				t.assertFalse(NGIO.hasSession(), "a refused call did not open a session either");
				t.done();
			}, null);
		});

		add("cloud saves are refused with no session", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSessionFree(t)) {
				return;
			}

			// Same shape as the unlock above: sent, then refused server-side.
			//
			// THE CODE IS THE POINT. With no session the gateway answers 102,
			// "Missing required parameter" - there is no session_id in the
			// envelope to check. With a guest session it answers 110, "User is
			// not logged in" - the id is there and belongs to nobody. Same call,
			// same component, two genuinely different refusals.
			//
			// That is the empirical case for LiveNoSessionSuite and LiveGuestSuite
			// being separate suites rather than one: they are not the same test
			// run twice. LiveGuestSuite asserts the matching 110.
			//
			// Both are documented Errors constants rather than transient server
			// conditions, so they are safe to assert - if either changes, that is
			// worth being told about.
			NGIO.loadSaveSlots(function(slots:Array, error):Void {
				if (t.assertNotNull(error, "loading save slots was refused")) {
					t.assertEquals(102, error.code,
						"refused for a MISSING session, not for being logged out");
					t.assertNotEquals(110, error.code,
						"and specifically not the guest-session code");
					t.note("server said: " + self.describeError(error));
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================

	/**
	 * Skip when a session exists, so this suite never reports a pass for a
	 * condition it did not actually meet.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function skipUnlessSessionFree(t:ngiotest.TestContext):Boolean {
		if (!ngiotest.suites.LiveNoSessionSuite.sessionFree || NGIO.hasSession()) {
			t.skip("a session exists, so this is no longer a no-session test");
			return true;
		}
		return false;
	}
}
