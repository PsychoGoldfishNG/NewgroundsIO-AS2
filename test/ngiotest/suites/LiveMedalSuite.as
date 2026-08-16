/**
 * LiveMedalSuite
 *
 * Exercises the secure (encrypted) Medal.unlock path end to end.
 *
 * With TestConfig.USE_DEBUG_MODE on - the default - the gateway validates and
 * answers normally without committing the unlock, so this suite is repeatable
 * and nothing has to be re-locked between runs. Switch debug mode off only when
 * deliberately verifying persistence, and expect to re-lock afterwards.
 *
 * The test app carries three medals as of 2026-08-15, matching the AS3 one. It
 * had one until then, which cost the "unlocking one medal does not unlock
 * another" case below - that test still guards on
 * TestConfig.EXPECTED_MEDAL_COUNT and skips itself with a reason rather than
 * failing, so reducing the app again degrades the suite honestly instead of
 * turning it red.
 */
import io.newgrounds.Errors;
import io.newgrounds.models.objects.Medal;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveMedalSuite extends ngiotest.LiveSuite {

	public function LiveMedalSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / Medals";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveMedalSuite = this;

		add("unlocks a medal", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var medal:io.newgrounds.models.objects.Medal = self.pickMedal();
			if (medal == null) {
				t.skip("no medals available to unlock");
				return;
			}

			var scoreBefore:Number = NGIO.getMedalScore();
			t.note("unlocking " + medal.toString() + " (was unlocked=" + medal.unlocked + ")");
			t.status("Unlocking " + medal.name + "...");

			medal.unlock(function(unlockedMedal:io.newgrounds.models.objects.Medal, error):Void {
				if (!self.assertNoError(t, error, "unlock accepted by the server")) {
					t.done();
					return;
				}

				t.assertStrictEquals(medal, unlockedMedal, "callback receives the same Medal instance");
				t.assertTrue(unlockedMedal.unlocked, "medal is flagged unlocked");
				t.note("medal score now " + NGIO.getMedalScore() + " (was " + scoreBefore + ")");
				t.done();
			}, null);
		});

		add("unlocking again is not an error", function(t:ngiotest.TestContext):Void {
			// Games unlock medals opportunistically and will re-send an unlock
			// the player already has. That has to be a no-op, not a failure the
			// game surfaces to the player.
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var medal:io.newgrounds.models.objects.Medal = self.pickMedal();
			if (medal == null) {
				t.skip("no medals available to unlock");
				return;
			}

			medal.unlock(function(unlockedMedal:io.newgrounds.models.objects.Medal, error):Void {
				if (self.assertNoError(t, error, "repeat unlock accepted")) {
					t.assertTrue(unlockedMedal.unlocked, "medal remains unlocked");
				}
				t.done();
			}, null);
		});

		add("unlocking one medal does not unlock another", function(t:ngiotest.TestContext):Void {
			// Needs two medals to mean anything: with only one there is no
			// second, still-locked medal to check, so "the unlock landed on the
			// right medal" and "the unlock did nothing at all" produce identical
			// observations.
			//
			// The app has three now, so this runs. The guard stays because the
			// medal count is server-side configuration that can change without
			// anyone touching this repo, and a suite that quietly stops proving
			// something is worse than one that says so.
			if (ngiotest.TestConfig.EXPECTED_MEDAL_COUNT < 2) {
				t.skip("the AS2 test app has only " + ngiotest.TestConfig.EXPECTED_MEDAL_COUNT +
				       " medal - two or more are needed to tell a targeted unlock from a no-op");
				return;
			}

			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var medals:Array = NGIO.getMedals();
			if (medals == null || medals.length < 2) {
				t.skip("fewer than two medals were returned by the server");
				return;
			}

			var target:io.newgrounds.models.objects.Medal = medals[0];
			var bystander:io.newgrounds.models.objects.Medal = medals[1];
			var bystanderWasUnlocked:Boolean = bystander.unlocked;

			target.unlock(function(unlockedMedal:io.newgrounds.models.objects.Medal, error):Void {
				if (self.assertNoError(t, error, "unlock accepted")) {
					t.assertTrue(target.unlocked, "the targeted medal is unlocked");
					t.assertEquals(bystanderWasUnlocked, bystander.unlocked,
						"the other medal's state was not touched");
				}
				t.done();
			}, null);
		});

		add("rejects an unknown medal id", function(t:ngiotest.TestContext):Void {
			// The encrypted payload still has to reach the server intact for it
			// to be able to tell us the id is wrong - so a 202 here is also
			// evidence the RC4 round-trip worked.
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var bogus:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			bogus.core = self.getCore();
			bogus.id = 99999999;

			bogus.unlock(function(unlockedMedal:io.newgrounds.models.objects.Medal, error):Void {
				if (t.assertNotNull(error, "server rejected the unknown medal id")) {
					t.assertEquals(io.newgrounds.Errors.INVALID_MEDAL_ID, error.code,
						"reported as INVALID_MEDAL_ID (202)");
					t.note("server said: " + self.describeError(error));
				}
				t.assertFalse(unlockedMedal.unlocked, "failed unlock did not flag the medal");
				t.done();
			}, null);
		});

		// REMOVED: "refuses a session-gated unlock when signed out".
		//
		// It could never run. This suite is registered after sign-in, so its own
		// guard - skip if isSignedIn() - fired on every run a developer actually
		// does, and the test reported [SKIP] "this path cannot be reached"
		// forever. It was coverage on paper only.
		//
		// Both halves of what it meant to test now live where they are reachable:
		// LiveNoSessionSuite covers the refusal with no session at all, and
		// LiveGuestSuite covers it with a guest session and no user. Those two
		// states behave differently and neither was previously exercised live.

		add("re-reads the medal list after unlocking", function(t:ngiotest.TestContext):Void {
			// The list is updated in place, so cached Medal references held by
			// game code have to stay valid across a reload.
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var before:Array = NGIO.getMedals();
			if (before == null || before.length == 0) {
				t.skip("no medals loaded");
				return;
			}

			var firstBefore:io.newgrounds.models.objects.Medal = before[0];

			NGIO.loadMedals(function(medals:Array, error):Void {
				if (!self.assertNoError(t, error, "medal list reloaded")) {
					t.done();
					return;
				}

				if (t.assertNotNull(medals, "list returned")) {
					t.assertEquals(before.length, medals.length, "medal count unchanged");
					t.assertStrictEquals(firstBefore, medals[0],
						"existing Medal instances are updated in place, not replaced");
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================

	/**
	 * Choose a medal to unlock, preferring one that is still locked so the test
	 * exercises a state change rather than a repeat.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function pickMedal():io.newgrounds.models.objects.Medal {
		var medals:Array = NGIO.getMedals();
		if (medals == null || medals.length == 0) {
			return null;
		}

		for (var i:Number = 0; i < medals.length; i++) {
			if (!medals[i].unlocked) {
				return medals[i];
			}
		}

		return medals[0];
	}
}
