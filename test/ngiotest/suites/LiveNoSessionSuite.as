/**
 * LiveNoSessionSuite
 *
 * Everything the gateway will do for a client that has NO session at all.
 *
 * WHY IT IS WORTH HAVING. Sixteen of the twenty-five components never touch a
 * session, and games use them that way - a medal list or a high score table
 * shown on a title screen, before anyone has signed in. Nothing else in the
 * suite proves those calls work with no session_id in the envelope, because
 * every other live suite runs after the session exists.
 *
 * THIS SUITE MAKES ITS OWN WINDOW, so it runs on every machine in every login
 * state. setUp() parks whatever session AppState restored during construction
 * and tearDown() puts it back.
 *
 * That is honest rather than a shortcut: the request envelope is built from
 * appState.session.id (Core.sendRequest), so clearing it locally reproduces
 * exactly the wire condition being tested - a request with no session_id. No
 * session is ended, nothing is sent, and the tester's login is untouched.
 *
 * It used to rely on finding a naturally session-free window between init() and
 * the first checkSession(). That window does not exist for either common case -
 * a developer with a remembered login, or a game embedded on Newgrounds where
 * the page URL supplies ngio_session_id - so on exactly the machines people test
 * on the whole suite reported permanent skips, and the only way to run it was to
 * clear the SharedObject and start again.
 *
 * MUST RUN BEFORE anything loads medals while signed in. Its unlock test asserts
 * the medal is not flagged unlocked, which only holds while the cache reflects a
 * sessionless read.
 */
import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveNoSessionSuite extends ngiotest.LiveSuite {

	public function LiveNoSessionSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / No session";
	}

	public function setUp(done:Function):Void {
		var self:ngiotest.suites.LiveNoSessionSuite = this;

		// super.setUp performs the one-time NGIO.init(), so the session only
		// exists to be parked after it has run.
		super.setUp(function():Void {
			self.stashSession();
			done.call(null);
		});
	}

	public function tearDown(done:Function):Void {
		restoreSession();
		done.call(null);
	}

	public function build():Void {

		var self:ngiotest.suites.LiveNoSessionSuite = this;

		add("holds no session at all", function(t:ngiotest.TestContext):Void {
			// The precondition for everything below. After setUp this is true on
			// every machine, whether or not one was restored.
			t.assertFalse(NGIO.hasSession(), "no session is held");
			t.assertFalse(NGIO.hasUser(), "and no user");
			t.assertNull(self.getCore().sessionId, "no session id on Core");

			t.note(self.hasStashedSession()
			     ? "a restored session was parked for the duration of this suite, and is put " +
			       "back in tearDown - nothing was ended server-side"
			     : "nothing had opened a session yet, so this window was already open");
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
	 * Safety net: nothing in this suite opens a session, and setUp guarantees
	 * there is none, so this should never fire. It stays because a pass recorded
	 * against the wrong state is worse than a skip - if some future change
	 * starts a session mid-suite, this says so rather than quietly reporting
	 * green.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function skipUnlessSessionFree(t:ngiotest.TestContext):Boolean {
		if (NGIO.hasSession()) {
			t.skip("a session appeared during this suite, so this is no longer a no-session test");
			return true;
		}
		return false;
	}
}
