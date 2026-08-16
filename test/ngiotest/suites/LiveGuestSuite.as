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
 * THIS SUITE MAKES ITS OWN WINDOW, so it runs on every machine in every login
 * state, without a prompt and without signing the tester out.
 *
 * Unlike LiveNoSessionSuite it cannot do that locally. "This session has no
 * user" is a judgement the SERVER makes, so faking it client-side would leave a
 * session the gateway still considers signed in, and every refusal below would
 * fail. What it does instead:
 *
 *   1. Park any signed-in session (LiveSuite.stashSession - purely local).
 *   2. Ask the gateway for a genuine guest session, which is what checkSession
 *      does when it finds no session id.
 *   3. Run the refusal tests against that real guest session.
 *   4. End it - which is where App.endSession gets its only coverage, on a
 *      session nobody needs afterwards.
 *   5. Put the parked session back and re-verify it, so everything downstream
 *      is signed in again.
 *
 * Step 4 is why no prompt is needed any more. Ending a throwaway guest session
 * costs the tester nothing, whereas ending THEIRS needed consent.
 *
 * MUST RUN BEFORE anything loads medals while signed in: the guest read below
 * asserts that no medal comes back unlocked.
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

		add("obtains a guest session, whatever state the run started in", function(t:ngiotest.TestContext):Void {
			// Three possible starting points, all handled:
			//
			//   already a guest    nothing to do - a fresh machine reaches this
			//                      naturally after LiveSessionSuite
			//   signed in          park the session locally, then ask the
			//                      gateway for a guest one
			//   no session         just ask for one
			//
			// Parking is local only; the signed-in session stays alive
			// server-side and is put back by the last case in this suite.
			if (NGIO.hasSession() && !NGIO.hasUser()) {
				t.assert(true, "already holding a guest session");
				t.note("guest session was already in place: " + self.getCore().sessionId);
				t.done();
				return;
			}

			if (NGIO.hasUser()) {
				t.note("parking the signed-in session locally - it is not ended, and is " +
				       "restored by the last case in this suite");
				self.stashSession();
			}

			// THE WAIT IS NOT PADDING. NgioAuthHelper throttles checkSession to
			// one server call every CHECKSESSION_THROTTLE_TIME (3) seconds, and
			// the suites before this one spent that budget. Called inside the
			// window, checkSession answers locally AND WITHOUT STARTING A NEW
			// SESSION - so this would silently do nothing and every case below
			// would fail for the wrong reason.
			//
			// Worth knowing outside the tests too: a game that calls endSession()
			// and immediately checkSession() gets no new session and a misleading
			// status. It has to wait out the throttle, exactly like this.
			self.afterThrottle(function():Void {
				NGIO.checkSession(function(status:io.newgrounds.SessionStatus):Void {
					if (!t.assertNotNull(status, "checkSession returned a status")) {
						t.done();
						return;
					}

					t.note("session status: " + status.status);

					t.assertNotEquals(io.newgrounds.SessionStatus.ERROR, status.status,
						"a guest session could be started" +
						((status.error != null) ? " (" + self.describeError(status.error) + ")" : ""));
					t.assertTrue(NGIO.hasSession(), "a session id is held");
					t.assertFalse(NGIO.hasUser(), "and it carries no user, which is what makes it a guest");

					var newId:String = self.getCore().sessionId;
					if (t.assertNotNull(newId, "the guest session has an id")) {
						// When a signed-in session was parked, the gateway must
						// have issued a genuinely different one rather than
						// handing the old one back.
						if (self.hasStashedSession()) {
							t.assertNotEquals(self.getStashedId(), newId,
								"the guest session is a new one, not the parked login");
						}
					}

					t.done();
				}, null);
			});
		});

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

		add("offers a passport url", function(t:ngiotest.TestContext):Void {
			// Moved here from LiveSignInSuite, where it could only run if the
			// tester was not already signed in - and that suite is where signing
			// in happens, so on any machine with a remembered login it was a
			// permanent skip. A passport url is a property of a GUEST session,
			// which is exactly what this suite guarantees.
			if (self.skipUnlessGuest(t)) {
				return;
			}

			var passportUrl:String = self.getCore().appState.session.passport_url;
			if (t.assertNotNull(passportUrl, "passport url supplied by the server")) {
				t.assertTrue(passportUrl.indexOf("http") == 0, "passport url is absolute");
				t.note(passportUrl);
			}
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

		//==================== ENDING IT ====================

		add("ends the guest session", function(t:ngiotest.TestContext):Void {
			// App.endSession's only coverage, and the reason it needs no prompt:
			// the session being ended is the throwaway one this suite created,
			// so nobody's login is at stake.
			//
			// Worth knowing before reading the assertions: endSession() hands its
			// callback NOTHING - no result, no error. Both libraries are written
			// that way, so there is no success flag to check and the only way to
			// tell whether it worked is to inspect the state afterwards.
			// NgioAuthHelper also calls appState.clearSession() SYNCHRONOUSLY,
			// right after dispatching the component rather than inside its
			// callback, so the local session is already gone by the time the
			// callback runs.
			//
			// A consequence of both: these assertions describe the LOCAL effect,
			// which happens whatever the server replies. They pin the library's
			// contract, not the gateway's.
			if (!NGIO.hasSession()) {
				t.skip("no guest session was established, so there is nothing to end");
				return;
			}

			var endingId:String = self.getCore().sessionId;
			NGIO.endSession(function():Void {
				t.assertFalse(NGIO.hasSession(), "no session is held after endSession");
				t.assertFalse(NGIO.hasUser(), "and no user");
				t.assertNull(self.getCore().sessionId, "Core reports no session id");
				t.assertNull(self.getUser(), "getUser() returns null");

				// clearSessionData() nulls preauthenticatedId too, so not even a
				// URL-supplied session survives this.
				t.assertFalse(self.getCore().appState.session.isPreauthenticated(),
					"no pre-authenticated id survives either");

				t.note("ended guest session " + endingId);

				// Deliberately not claiming what the machine is left holding.
				// clearSession() wipes the stored id here, but if a login is
				// restored by the next case the library saves it again whenever
				// the server re-verifies it with remember set - so the end state
				// depends on the server's answer, not on this.
				t.note("clearSession() also wiped the stored session id; whether anything is " +
				       "remembered for next time depends on what the server says when the " +
				       "parked login is re-verified below");
				t.done();
			}, null);
		});

		add("restores a usable session afterwards", function(t:ngiotest.TestContext):Void {
			// Everything downstream needs a session, and most of it needs a
			// signed-in one. This puts back whatever was parked and asks the
			// server to verify it; with nothing parked it simply starts a fresh
			// session for the Passport suite to work from.
			var hadStash:Boolean = self.hasStashedSession();

			self.restoreSession();

			self.afterThrottle(function():Void {
				NGIO.checkSession(function(status:io.newgrounds.SessionStatus):Void {
					if (!t.assertNotNull(status, "checkSession returned a status")) {
						t.done();
						return;
					}

					t.assertNotEquals(io.newgrounds.SessionStatus.ERROR, status.status,
						"a session is available again" +
						((status.error != null) ? " (" + self.describeError(status.error) + ")" : ""));
					t.assertTrue(NGIO.hasSession(), "a session id is held");

					if (hadStash) {
						// The parked login was never ended server-side, so it has
						// to come back attached to its user.
						t.assertTrue(NGIO.hasUser(), "the parked login is signed in again");
						t.note("restored the signed-in session for " +
						       ((self.getUser() != null) ? self.getUser().name : "(unknown)"));
					} else {
						t.note("no login was parked, so this is a fresh guest session for " +
						       "the sign-in suite to work from");
					}

					t.done();
				}, null);
			});
		});
	}

	//==================== HELPERS ====================

	// afterThrottle() now lives on LiveSuite - LiveSignOutSuite needs it too.

	/**
	 * Skip unless we are genuinely in guest state.
	 *
	 * The first case establishes that state from any starting point, so this
	 * should not fire. It stays as a safety net: if the first case failed to get
	 * a guest session, the refusal tests below would otherwise report green for
	 * the wrong reason - a call "was rejected" reads the same whether the guard
	 * worked or the session was never right.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function skipUnlessGuest(t:ngiotest.TestContext):Boolean {
		if (!NGIO.hasSession()) {
			t.skip("no guest session was established - see the first case in this suite");
			return true;
		}
		if (NGIO.hasUser()) {
			t.skip("a user is attached, so this is not a guest session - " +
			       "the first case in this suite should have prevented that");
			return true;
		}
		return false;
	}
}
