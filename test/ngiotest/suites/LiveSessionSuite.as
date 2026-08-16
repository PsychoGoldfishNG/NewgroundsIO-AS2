/**
 * LiveSessionSuite
 *
 * Gets a session, and offers to end an existing one.
 *
 * SPLIT: the Passport half now lives in LiveSignInSuite, so LiveGuestSuite can
 * run between the two. A guest session only exists between "we have a session"
 * and "a user signed in", and a suite is the unit the runner schedules - the
 * guest tests could not sit in that window while both halves were one suite.
 *
 * Order is therefore:
 *
 *   Live / No session     nothing has opened a session yet
 *   Live / Session        this suite - a session appears, and may be ended
 *   Live / Guest session  session id, no user (only if one was ended)
 *   Live / Sign-in        Passport attaches a user
 *
 * Everything after that depends on being signed in.
 */
import io.newgrounds.SessionStatus;
import io.newgrounds.models.objects.User;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveSessionSuite extends ngiotest.LiveSuite {

	public function LiveSessionSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / Session";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveSessionSuite = this;

		add("obtains a session from the server", function(t:ngiotest.TestContext):Void {
			t.status("Contacting Newgrounds for a session...");

			NGIO.checkSession(function(status:io.newgrounds.SessionStatus):Void {
				if (!t.assertNotNull(status, "checkSession returned a status")) {
					t.done();
					return;
				}

				t.note("session status: " + status.status);

				t.assertNotEquals(io.newgrounds.SessionStatus.ERROR, status.status,
					"status is not ERROR" + ((status.error != null) ? " (" + self.describeError(status.error) + ")" : ""));
				t.assertTrue(NGIO.hasSession(), "a session id is held locally");
				t.assertNotNull(self.getCore().sessionId, "session id is readable from Core");
				t.done();
			}, null);
		});

		// Placed HERE on purpose: after the session exists, before anything that
		// depends on who is signed in. Ending the session later would invalidate
		// the medal, score and cloud save suites; ending it earlier would have
		// nothing to end.
		//
		// It is also the only way App.endSession gets covered at all. The
		// component needs a real signed-in session to be worth calling, and the
		// only moment one reliably exists is the moment we find a saved one.
		//
		// Choosing to end it is also the ONLY way LiveGuestSuite runs - ending a
		// session is what creates the guest state it tests.
		addSlow("ends an existing session on request", ngiotest.TestConfig.INTERACTIVE_TIMEOUT_MS, function(t:ngiotest.TestContext):Void {
			if (!self.isSignedIn()) {
				t.skip("no saved session was found, so there is nothing to end");
				return;
			}

			var previousName:String = self.getUser().name;
			var previousId:String = self.getCore().sessionId;

			// An unanswered prompt is a clean stop, not a failure - the same
			// treatment LiveGateSuite gives its confirmation gate. Keeping the
			// existing session is the safe default, so a timeout lands there.
			t.onTimeout = function():Void {
				t.skip("nobody chose - keeping the existing session for " + previousName);
			};

			t.promptChoice(
				"A SAVED SESSION WAS FOUND\n\n" +
				"You are already signed in as " + previousName + ".\n\n" +
				"Keep it, and the sign-in test below is skipped.\n" +
				"End it, and App.endSession is tested, the guest-session suite runs,\n" +
				"and you can sign in fresh afterwards.\n\n" +
				"(Ending it is the only way 'Live / Guest session' gets to run.)",

				"Keep this login",
				function():Void {
					t.skip("kept the existing session for " + previousName);
				},

				"End session and sign in fresh",
				function():Void {
					t.status("Ending the session...");
					self.endSessionThenRestart(t, previousName, previousId);
				}
			);
		});
	}

	//==================== ENDING A SESSION ====================

	/**
	 * Run App.endSession, check it actually took effect, then get a fresh guest
	 * session so the tests below have something to work with.
	 *
	 * Public because the prompt handler above reaches it through `self`.
	 *
	 * Worth knowing before reading the assertions: endSession() hands its
	 * callback NOTHING - no result, no error. Both libraries are written that
	 * way, so there is no success flag to check and the only way to tell whether
	 * it worked is to look at the state afterwards. NgioAuthHelper also calls
	 * appState.clearSession() SYNCHRONOUSLY, right after dispatching the
	 * component rather than inside its callback, so the local session is already
	 * gone by the time the callback runs. That is what the first group below
	 * pins - if either behaviour changes, these assertions say so.
	 */
	public function endSessionThenRestart(t:ngiotest.TestContext, previousName:String, previousId:String):Void {
		var self:ngiotest.suites.LiveSessionSuite = this;

		NGIO.endSession(function():Void {
			t.assertFalse(NGIO.hasUser(), "no user is attached after endSession");
			t.assertFalse(NGIO.hasSession(), "no session is held after endSession");
			t.assertNull(self.getUser(), "getUser() returns null");
			t.note("ended the session that belonged to " + previousName);

			// Now recover, so the guest suite and the Passport tests have a
			// session to work from. Without this the rest of the run would be
			// testing a library with no session at all, which is a different
			// thing from a signed-out one - and is already covered by
			// LiveNoSessionSuite.
			//
			// THE WAIT IS NOT PADDING. NgioAuthHelper throttles checkSession to
			// one server call every CHECKSESSION_THROTTLE_TIME (3) seconds, and
			// the previous test just used that budget. Called inside the window
			// this returns a synthetic UNVERIFIED without contacting the server
			// AND WITHOUT STARTING A NEW SESSION - so the recovery would silently
			// do nothing and every assertion below would fail for the wrong
			// reason.
			//
			// Worth knowing outside the tests too: a game that calls endSession()
			// and immediately checkSession() gets no new session and a misleading
			// status. It has to wait out the throttle, exactly like this.
			t.status("Waiting out the checkSession throttle, then starting a new session...");

			self.afterThrottle(function():Void {
				t.status("Getting a fresh guest session...");

				NGIO.checkSession(function(status:io.newgrounds.SessionStatus):Void {
					if (!t.assertNotNull(status, "checkSession returned a status after endSession")) {
						t.done();
						return;
					}

					t.note("session status after ending: " + status.status);

					t.assertNotEquals(io.newgrounds.SessionStatus.ERROR, status.status,
						"a new session could be started" +
						((status.error != null) ? " (" + self.describeError(status.error) + ")" : ""));
					t.assertTrue(NGIO.hasSession(), "a replacement session id is held");

					// The point of the whole test: the server issued a DIFFERENT
					// session, rather than handing back the one we just ended.
					var newId:String = self.getCore().sessionId;
					if (t.assertNotNull(newId, "replacement session has an id")) {
						t.assertNotEquals(previousId, newId, "the replacement is a new session, not the old one");
					}

					// A brand new session is a guest session. If a user is still
					// attached here, endSession did not really end anything - and
					// LiveGuestSuite, which runs next, would skip every case.
					t.assertFalse(NGIO.hasUser(), "the replacement session has no user attached");

					t.done();
				}, null);
			});
		}, null);
	}

	/**
	 * Run something once the checkSession throttle has expired.
	 *
	 * setInterval rather than a Timer because AS2 has neither Timer nor a
	 * one-shot setTimeout worth relying on; the handler clears its own id first
	 * so it behaves as a one-shot. The id is not stored on the instance because
	 * this is fire-and-forget and self-cancelling.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function afterThrottle(action:Function):Void {
		var waitId:Number = 0;
		waitId = setInterval(function():Void {
			clearInterval(waitId);
			action.call(null);
		}, ngiotest.TestConfig.SESSION_THROTTLE_WAIT_MS);
	}
}
