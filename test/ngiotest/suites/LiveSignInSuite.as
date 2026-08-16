/**
 * LiveSignInSuite
 *
 * The Passport half of the session flow: get a user attached to the guest
 * session LiveSessionSuite established, then confirm what that gives us.
 *
 * SPLIT OUT OF LiveSessionSuite so LiveGuestSuite can run between them. A guest
 * session only exists between "we have a session" and "a user signed in", and a
 * suite is the unit the runner schedules - so the guest tests could not sit in
 * that window while both halves lived in one suite.
 *
 * This is the only suite that waits on a human.
 */
import io.newgrounds.SessionStatus;
import io.newgrounds.helpers.AppStateBootstrapHelper;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.User;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveSignInSuite extends ngiotest.LiveSuite {

	/**
	 * setInterval id for the Passport poll, kept so it can be stopped.
	 *
	 * AS2 has no Timer class. setInterval repeats until cleared, which is
	 * exactly what a poll wants - but it also means a forgotten id keeps firing
	 * for the rest of the session, so every exit path below clears it.
	 */
	private var pollIntervalId:Number;

	public function LiveSignInSuite() {
		super();
		this.pollIntervalId = 0;
	}

	public function getSuiteName():String {
		return "Live / Sign-in";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveSignInSuite = this;

		// "offers a passport url for a guest session" lives in LiveGuestSuite,
		// not here. It could only ever run when the tester was NOT already
		// signed in, and this suite is where a user gets attached - so on any
		// machine with a remembered login it reported a permanent skip. The
		// guest suite guarantees a guest session, which is precisely the state
		// that carries a passport_url.

		// Deliberately generous: this test is bounded by how fast a person can
		// sign in, not by the network.
		addSlow("signs in through Passport", ngiotest.TestConfig.INTERACTIVE_TIMEOUT_MS, function(t:ngiotest.TestContext):Void {
			if (self.isSignedIn()) {
				t.note("already signed in as " + self.getUser().name);
				t.assert(true, "session already carries a user");
				t.done();
				return;
			}

			if (!ngiotest.TestConfig.REQUIRE_LOGIN) {
				t.skip("TestConfig.REQUIRE_LOGIN is false");
				return;
			}

			t.prompt(
				"SIGN IN REQUIRED\n\n" +
				"Click below to open the Newgrounds sign-in page in your browser.\n" +
				"Approve the app, then return here - the test detects it automatically.\n\n" +
				"(Set TestConfig.REQUIRE_LOGIN = false to skip every test that needs a user.)",
				"Open Newgrounds sign-in",
				function():Void {
					if (!NGIO.openPassport("_blank")) {
						t.fail("openPassport() refused to open - no session, or no passport url");
						t.done();
						return;
					}
					t.status("Waiting for you to finish signing in...\n\nThis test gives up after " +
					         Math.round(ngiotest.TestConfig.INTERACTIVE_TIMEOUT_MS / 1000) + " seconds.");
					self.pollForUser(t);
				}
			);
		});

		add("exposes the signed-in user", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var signedIn:io.newgrounds.models.objects.User = self.getUser();
			if (t.assertNotNull(signedIn, "getUser() returned a user")) {
				t.assertIsType(signedIn, io.newgrounds.models.objects.User, "is a User model");
				t.assertTrue(signedIn.id > 0, "user has a real id");
				t.assertNotNull(signedIn.name, "user has a name");
				t.assertTrue(signedIn.name.length > 0, "user name is not empty");
				t.note("signed in as " + signedIn.name + " (id " + signedIn.id + ", supporter=" + signedIn.supporter + ")");
			}

			t.assertTrue(NGIO.hasUser(), "hasUser() agrees");
			t.assertTrue(NGIO.hasSession(), "hasSession() agrees");
			t.done();
		});

		add("saves the session id locally when the server says remember", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			// The auto-login half of the sign-out suite's contract, from the other
			// end: LiveSignOutSuite proves the stored id is REMOVED on sign-out,
			// and this proves it was PUT THERE in the first place - and only when
			// the server asked for it.
			var session:io.newgrounds.models.objects.Session = self.getCore().appState.session;
			if (!t.assertNotNull(session, "a session object is held")) {
				t.done();
				return;
			}

			var storageKey:String = self.getCore().appState.sessionStorageKey;
			var storedId:String = io.newgrounds.helpers.AppStateBootstrapHelper.getSavedSessionId(storageKey);
			var hasStored:Boolean = (storedId != null && storedId != undefined && storedId.length > 0);

			t.note("session.remember = " + session.remember +
			       ", storage " + (hasStored ? "holds an id" : "is empty"));

			// SKIPPED RATHER THAN INVERTED when remember is false, and the reason
			// is not squeamishness - it is that the opposite assertion would be
			// unsound. finalizeSessionPersistenceState only ever WRITES on
			// remember=true; it never clears on false. So an id sitting in storage
			// during a remember=false run may be a perfectly legitimate leftover
			// from an earlier remembered login, and "storage is empty" is not
			// something this run can require.
			//
			// Choosing not to be remembered is a real answer to the question, so it
			// reads as a skip with the reason stated, not a failure.
			if (session.remember !== true) {
				t.skip("the server did not ask us to remember this session" +
				       (hasStored ? " (an id from an earlier remembered login is still stored)" : ""));
				return;
			}

			t.assertTrue(hasStored, "a session id was written to local storage");
			t.assertEquals(session.id, storedId, "and it is THIS session's id");
			t.note("this machine will auto-log-in on the next run; " +
			       "the Live / Sign-out suite is what removes it again");
			t.done();
		});

		add("reports LOGGED_IN without another round trip", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			// Once a user is attached, checkSession short-circuits locally. If
			// this ever starts taking a network round trip, every poll during a
			// Passport wait becomes a server request.
			var settledStatus:io.newgrounds.SessionStatus = null;

			NGIO.checkSession(function(status:io.newgrounds.SessionStatus):Void {
				settledStatus = status;
			}, null);

			// A local answer means the callback has already run by the time
			// checkSession() returns; a network answer leaves it null.
			if (!t.assertNotNull(settledStatus, "checkSession answered locally, without a round trip")) {
				t.done();
				return;
			}

			t.assertEquals(io.newgrounds.SessionStatus.LOGGED_IN, settledStatus.status, "status is LOGGED_IN");
			t.assertNotNull(settledStatus.user, "status carries the user");
			t.done();
		});

		add("keepAlive pings without disturbing the session", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var beforeId:String = self.getCore().sessionId;
			NGIO.keepAlive();

			// keepAlive is fire-and-forget, so give the request a moment and
			// then confirm it did not clear or replace the session. setInterval
			// repeats, so the handler clears its own id first to behave as a
			// one-shot.
			var settleId:Number = 0;
			settleId = setInterval(function():Void {
				clearInterval(settleId);
				t.assertTrue(NGIO.hasUser(), "still signed in after keepAlive");
				t.assertEquals(beforeId, self.getCore().sessionId, "session id unchanged");
				t.done();
			}, 2000);
		});
	}

	public function tearDown(done:Function):Void {
		stopPolling();
		done.call(null);
	}

	//==================== PASSPORT POLLING ====================

	/**
	 * Re-check the session on an interval until a user appears.
	 *
	 * The interval is deliberately longer than NgioAuthHelper's 3 second
	 * checkSession throttle - polling faster than the throttle just returns the
	 * previous cached answer and never reaches the server.
	 *
	 * Public because the prompt handler above reaches it through `self`.
	 */
	public function pollForUser(t:ngiotest.TestContext):Void {
		stopPolling();

		var self:ngiotest.suites.LiveSignInSuite = this;

		pollIntervalId = setInterval(function():Void {
			if (t.isFinished()) {
				self.stopPolling();
				return;
			}

			NGIO.checkSession(function(status:io.newgrounds.SessionStatus):Void {
				if (t.isFinished()) {
					return;
				}

				if (status.status == io.newgrounds.SessionStatus.LOGGED_IN) {
					self.stopPolling();
					t.assertNotNull(status.user, "signed-in status carries a user");
					t.note("signed in as " + status.user.name);
					t.done();
					return;
				}

				if (status.status == io.newgrounds.SessionStatus.LOGIN_CANCELLED) {
					self.stopPolling();
					t.skip("sign-in was cancelled");
					return;
				}

				if (status.status == io.newgrounds.SessionStatus.ERROR) {
					self.stopPolling();
					t.fail("sign-in failed: " + self.describeError(status.error));
					t.done();
				}
			}, null);
		}, ngiotest.TestConfig.SESSION_POLL_INTERVAL_MS);
	}

	/** Public for the same reason as pollForUser - reached from a closure. */
	public function stopPolling():Void {
		if (pollIntervalId != 0) {
			clearInterval(pollIntervalId);
			pollIntervalId = 0;
		}
	}
}
