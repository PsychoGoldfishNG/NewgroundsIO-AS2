/**
 * LiveGuestSuite
 *
 * What the gateway allows a client holding a GUEST session - a real session id
 * with no user attached to it.
 *
 * This is the third of three states, and the only one that had no coverage at
 * all:
 *
 *   1. no session      hasSession() false, hasUser() false   LiveNoSessionSuite
 *   2. GUEST session   hasSession() TRUE,  hasUser() false   this suite
 *   3. signed in       hasSession() true,  hasUser() true    everything else
 *
 * The distinction matters because it is where the library and the server
 * disagree about what "session-gated" means. BaseComponent.requiresSession is
 * satisfied by a session ID alone as far as the envelope is concerned, but
 * hasValidProperties() also demands session.user - and nothing in build/ ever
 * calls hasValidProperties(). So in guest state the request is built, sent, and
 * refused by the server. These tests pin that refusal.
 *
 * WHEN IT RUNS. Only in the window opened by LiveSessionSuite's "ends an
 * existing session on request" test, between ending a saved session and signing
 * in again through Passport. Choose "Keep this login" and every case here skips,
 * which costs nothing. That makes the coverage opt-in per run rather than
 * guaranteed - the alternative was signing the tester out unasked.
 */
import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveGuestSuite extends ngiotest.LiveSuite {

	public function LiveGuestSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / Guest session";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveGuestSuite = this;

		add("holds a session id but no user", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessGuest(t)) {
				return;
			}

			t.assertTrue(NGIO.hasSession(), "a session exists");
			t.assertFalse(NGIO.hasUser(), "but no user is attached");
			t.assertNotNull(self.getCore().sessionId, "the session has an id");
			t.assertNull(self.getUser(), "getUser() returns null");
			t.note("guest session " + self.getCore().sessionId);
			t.done();
		});

		add("a guest can load medals and scoreboards", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessGuest(t)) {
				return;
			}

			// LOADS them rather than reading the cache, for two reasons. It is
			// the actual claim worth testing - reads stay open to a guest, only
			// writes and per-user queries close - and it makes this suite
			// self-sufficient. LiveNoSessionSuite skips entirely when the host
			// supplies a session id in the URL, so nothing may have populated the
			// caches by the time we get here.
			// "scoreBoards", capital B - see AppState.dataProperties.
			NGIO.loadAppData(["medals", "scoreBoards"], function(error):Void {
				if (!self.assertNoError(t, error, "a guest can load medals and scoreboards")) {
					t.done();
					return;
				}

				var medals:Array = NGIO.getMedals();
				var boards:Array = NGIO.getScoreBoards();

				if (t.assertNotNull(medals, "medals came back")) {
					t.assertEquals(ngiotest.TestConfig.EXPECTED_MEDAL_COUNT, medals.length,
						"all medals are visible to a guest");

					// A guest has no unlock history, so nothing should claim to
					// be unlocked.
					var anyUnlocked:Boolean = false;
					for (var i:Number = 0; i < medals.length; i++) {
						if (medals[i].unlocked === true) {
							anyUnlocked = true;
						}
					}
					t.assertFalse(anyUnlocked, "no medal reads as unlocked for a guest");
				}

				if (t.assertNotNull(boards, "scoreboards came back")) {
					t.assertEquals(ngiotest.TestConfig.EXPECTED_SCOREBOARD_COUNT, boards.length,
						"all scoreboards are visible to a guest");
				}

				t.assertFalse(NGIO.hasUser(), "and reading them did not attach a user");
				t.done();
			}, null);
		});

		add("unlocking a medal as a guest is refused", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessGuest(t)) {
				return;
			}

			var medals:Array = NGIO.getMedals();
			if (medals == null || medals.length == 0) {
				t.skip("no medals loaded");
				return;
			}

			var medal:io.newgrounds.models.objects.Medal = medals[0];
			medal.unlock(function(unlockedMedal:io.newgrounds.models.objects.Medal, error):Void {
				if (t.assertNotNull(error, "the unlock was refused")) {
					t.note("server said: " + self.describeError(error));
				}
				t.assertFalse(unlockedMedal.unlocked, "and the medal is not flagged unlocked");
				t.done();
			}, null);
		});

		add("posting a score as a guest is refused", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessGuest(t)) {
				return;
			}

			var boards:Array = NGIO.getScoreBoards();
			if (boards == null || boards.length == 0) {
				t.skip("no scoreboards loaded");
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = boards[0];
			board.postScore(1, null, function(postedBoard, error):Void {
				if (t.assertNotNull(error, "the post was refused")) {
					t.note("server said: " + self.describeError(error));
				}
				t.done();
			}, null);
		});

		add("cloud saves are refused for a guest", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessGuest(t)) {
				return;
			}

			// REGRESSION TEST as well as a guest test. This is the pair of calls
			// that found AppState.loadData swallowing component-level errors: the
			// gateway answered {"success":true, result:[... error 110 "User is
			// not logged in" ...]} and loadData, which only inspected the
			// RESPONSE-level error, handed the caller (slots, null). A game would
			// have read that as "this user has no saves".
			NGIO.loadSaveSlots(function(slots:Array, error):Void {
				if (t.assertNotNull(error, "loading save slots was refused")) {
					t.assertEquals(110, error.code, "and refused specifically for not being logged in");
					t.note("server said: " + self.describeError(error));
				}
				t.done();
			}, null);
		});

		add("the medal score is refused for a guest", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessGuest(t)) {
				return;
			}

			// Medal.getMedalScore is session-gated for an obvious reason - there
			// is no "your total" without a "you". Same loadData path as the test
			// above, so it pins the same fix from a second component.
			NGIO.loadMedalScore(function(medalScore:Number, error):Void {
				if (t.assertNotNull(error, "the medal score request was refused")) {
					t.assertEquals(110, error.code, "and refused specifically for not being logged in");
					t.note("server said: " + self.describeError(error));
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================

	/**
	 * Skip unless we are genuinely in guest state.
	 *
	 * Checked per test rather than once for the suite, because signing in is a
	 * human action that can complete at any moment - though in practice the
	 * Passport suite runs after this one, so the window stays open throughout.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function skipUnlessGuest(t:ngiotest.TestContext):Boolean {
		if (!NGIO.hasSession()) {
			t.skip("no session at all - see Live / No session for that state");
			return true;
		}
		if (NGIO.hasUser()) {
			t.skip("a user is signed in, so this is not a guest session " +
			       "(choose 'End session and sign in fresh' to reach this state)");
			return true;
		}
		return false;
	}
}
