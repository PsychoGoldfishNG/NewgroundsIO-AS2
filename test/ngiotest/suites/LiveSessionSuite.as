/**
 * LiveSessionSuite
 *
 * Proves a session can be obtained at all, before anything depends on one.
 *
 * SPLIT: the Passport half lives in LiveSignInSuite, so LiveGuestSuite can run
 * between the two. A guest session only exists between "we have a session" and
 * "a user signed in", and a suite is the unit the runner schedules - the guest
 * tests could not sit in that window while both halves were one suite.
 *
 * Order is therefore:
 *
 *   Live / No session     parks any restored session, so it always runs
 *   Live / Session        this suite - a session appears
 *   Live / Guest session  parks any login, gets a real guest session, ends it
 *   Live / Sign-in        Passport attaches a user, or one is already attached
 *
 * Everything after that depends on being signed in.
 *
 * EACH SUITE MAKES THE STATE IT TESTS. That is what lets a single run cover all
 * three session states on any machine, whatever the tester is logged into, with
 * no prompt and no state-dependent skips. App.endSession is covered by
 * LiveGuestSuite, on the throwaway guest session it created - not on the
 * tester's own login, which is why it no longer needs consent.
 */
import io.newgrounds.SessionStatus;

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

				// Either answer is fine and both are worth recording: a machine
				// with a remembered login lands here signed in, a clean one lands
				// here as a guest, and the suites below handle both without
				// asking.
				t.note(NGIO.hasUser()
				     ? "a remembered login was restored and verified"
				     : "no login was remembered, so this is a guest session");
				t.done();
			}, null);
		});
	}
}
