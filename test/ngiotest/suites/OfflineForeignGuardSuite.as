/**
 * OfflineForeignGuardSuite
 *
 * The write guards on objects loaded from another app.
 *
 * Cross-app access is read-only - no component that writes accepts an app_id -
 * so every write method refuses to run on an object carrying foreignAppId.
 * These tests need no network: the guard fires before anything is sent, which
 * is the whole point of it.
 *
 * Two AS2 differences from the AS3 suite, both cosmetic:
 *  - the guard is public rather than protected, because AS2 has no protected.
 *  - it throws a plain Error, not an ArgumentError, which AS2 does not have.
 *    The assertions read the message rather than the type, so nothing here
 *    depends on that either way.
 */
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.models.objects.ScoreBoard;

import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineForeignGuardSuite extends ngiotest.TestSuite {

	/** Any app id that is not ours. Nothing is sent, so it need not exist. */
	private static var OTHER_APP:String = "39685:NJ1KkPGb";

	public function OfflineForeignGuardSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Offline / Foreign object guards";
	}

	public function build():Void {

		var self:ngiotest.suites.OfflineForeignGuardSuite = this;
		var otherApp:String = ngiotest.suites.OfflineForeignGuardSuite.OTHER_APP;

		//==================== isForeign ====================

		add("isForeign reflects the stamp", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			t.assertFalse(medal.isForeign(), "an unstamped model is local");

			medal.foreignAppId = otherApp;
			t.assertTrue(medal.isForeign(), "a stamped model is foreign");
			t.done();
		});

		add("an empty stamp is not a foreign object", function(t:ngiotest.TestContext):Void {
			// A stamp that never took must read as local, or a bug in the
			// stamping path would start blocking ordinary local writes - turning
			// a cross-app nicety into a broken game.
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.foreignAppId = "";

			t.assertFalse(medal.isForeign(), "empty string is not a foreign app id");
			t.assertDoesNotThrow(function():Void {
				medal.unlock(null, null);
			}, "so unlock() is not blocked");
			t.done();
		});

		add("an unset stamp is undefined in AS2, and still reads as local", function(t:ngiotest.TestContext):Void {
			// AS2-specific, and the reason isForeign() exists rather than
			// callers testing foreignAppId directly. BaseObject declares
			// foreignAppId with a null initialiser, but a model built by a path
			// that never touched it can still hand back undefined - and
			// `undefined != null` is FALSE in AS2 while `undefined === null` is
			// true, so a direct comparison is easy to get subtly wrong.
			//
			// isForeign() sidesteps all of it by checking length instead.
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.foreignAppId = undefined;

			t.assertFalse(medal.isForeign(), "undefined is not a foreign app id");
			t.assertDoesNotThrow(function():Void {
				medal.unlock(null, null);
			}, "and unlock() is not blocked");
			t.done();
		});

		//==================== Medal ====================

		add("a foreign medal refuses to unlock", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 88366;
			medal.name = "Skull Punk";
			medal.foreignAppId = otherApp;

			var thrown = t.assertThrows(function():Void {
				medal.unlock(null, null);
			}, "unlock() on a foreign medal throws");

			if (thrown != null) {
				t.assertTrue(String(thrown.message).indexOf(otherApp) >= 0,
					"the message names the app it came from");
				t.assertTrue(String(thrown.message).indexOf("unlock()") >= 0,
					"and the method that was refused");
				t.note(String(thrown.message));
			}
			t.done();
		});

		add("a local medal is not blocked", function(t:ngiotest.TestContext):Void {
			// With no core attached, unlock() is a no-op rather than a network
			// call - so reaching the end without throwing is exactly the
			// assertion we want.
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 88366;

			t.assertDoesNotThrow(function():Void {
				medal.unlock(null, null);
			}, "unlock() on a local medal is allowed");
			t.done();
		});

		//==================== ScoreBoard ====================

		add("a foreign scoreboard refuses to post", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.id = 5853;
			board.name = "Cross-app board";
			board.foreignAppId = otherApp;

			var thrown = t.assertThrows(function():Void {
				board.postScore(100, null, null, null);
			}, "postScore() on a foreign board throws");

			if (thrown != null) {
				t.assertTrue(String(thrown.message).indexOf("postScore()") >= 0,
					"the message names the refused method: " + String(thrown.message));
			}
			t.done();
		});

		add("a foreign scoreboard still allows reads", function(t:ngiotest.TestContext):Void {
			// Reading is the one thing cross-app access does allow, so
			// getScores() must not be caught by the guard. It forwards the
			// app_id the board was loaded with - asserted live, since only the
			// gateway can confirm the parameter went out.
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.id = 5853;
			board.foreignAppId = otherApp;

			t.assertDoesNotThrow(function():Void {
				board.getScores(null, null, null);
			}, "getScores() on a foreign board is allowed");
			t.done();
		});

		add("a foreign scoreboard accepts the social filter", function(t:ngiotest.TestContext):Void {
			// Explicit because this was got wrong once and reversed across all
			// four repos. The friends list is a site-wide relation between
			// users, not a per-app one, so "me and my friends" means the same
			// thing on another app's board - a social leaderboard shared across
			// a series of games is one of the better reasons to use cross-app
			// access at all. The schema scopes the friends list to no app
			// whatsoever.
			//
			// It is still gated on a session, because the gateway ignores
			// 'social' when it cannot tell who the user is - but that gate lives
			// in getScores(), not in the foreign guard.
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.id = 5853;
			board.foreignAppId = otherApp;

			t.assertDoesNotThrow(function():Void {
				board.getScores({ social: true }, null, null);
			}, "social is not gated on isForeign()");
			t.done();
		});

		//==================== SaveSlot ====================
		//
		// The important ones. Medal and scoreboard ids are globally unique, so a
		// misdirected write is rejected by the gateway - confusing, but
		// harmless. SaveSlot.id is a per-app SLOT NUMBER and every app has a
		// slot 1, so an unguarded write through a foreign slot SUCCEEDS,
		// silently destroying the player's own save.

		add("a foreign save slot refuses saveData", function(t:ngiotest.TestContext):Void {
			var slot:io.newgrounds.models.objects.SaveSlot = self.foreignSlot();

			var thrown = t.assertThrows(function():Void {
				slot.saveData({ score: 1 }, null, null);
			}, "saveData() on a foreign slot throws");

			if (thrown != null) {
				t.assertTrue(String(thrown.message).indexOf("slot 1") >= 0,
					"and warns which of OUR slots it would have hit");
				t.note(String(thrown.message));
			}
			t.done();
		});

		add("a foreign save slot refuses saveDataRaw", function(t:ngiotest.TestContext):Void {
			var slot:io.newgrounds.models.objects.SaveSlot = self.foreignSlot();

			var thrown = t.assertThrows(function():Void {
				slot.saveDataRaw("payload", null, null);
			}, "saveDataRaw() on a foreign slot throws");

			if (thrown != null) {
				t.assertTrue(String(thrown.message).indexOf("saveDataRaw()") >= 0,
					"naming the low-level method, not the wrapper: " + String(thrown.message));
			}
			t.done();
		});

		add("a foreign save slot refuses clearData", function(t:ngiotest.TestContext):Void {
			var slot:io.newgrounds.models.objects.SaveSlot = self.foreignSlot();

			t.assertThrows(function():Void {
				slot.clearData(null, null);
			}, "clearData() on a foreign slot throws");
			t.done();
		});

		add("a foreign save slot still allows loading", function(t:ngiotest.TestContext):Void {
			// loadDataRaw reads the absolute URL the server returned with the
			// slot. It needs no app context, so it works cross-app unchanged -
			// and being able to read another app's saves is the reason
			// loadExternalSaveSlots exists at all.
			//
			// The url is blanked first so this stays offline: an empty slot
			// short-circuits to the callback without a load.
			var slot:io.newgrounds.models.objects.SaveSlot = self.foreignSlot();
			slot.url = null;

			var called:Boolean = false;
			slot.loadDataRaw(function(data:String, error):Void {
				called = true;
				t.assertNull(data, "an empty slot loads as null rather than throwing");
			}, null);

			t.assertTrue(called, "and the callback ran");
			t.done();
		});

		//==================== the guard is per-object ====================

		add("stamping one object does not block its siblings", function(t:ngiotest.TestContext):Void {
			// stampForeign walks a whole result, so a bug there could mark more
			// than it should. Confirm the flag is read per-object.
			var foreign:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			foreign.id = 1;
			foreign.foreignAppId = otherApp;

			var local:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			local.id = 2;

			t.assertThrows(function():Void {
				foreign.unlock(null, null);
			}, "the stamped medal is blocked");

			t.assertDoesNotThrow(function():Void {
				local.unlock(null, null);
			}, "the unstamped one beside it is not");
			t.done();
		});

		add("the stamp is per-instance, not shared through the prototype", function(t:ngiotest.TestContext):Void {
			// AS2-specific, and worth its own case. A property whose only
			// assignment is its declaration initialiser lives on the PROTOTYPE
			// until something writes it on an instance. If foreignAppId were
			// ever written through the prototype instead of the instance, every
			// model of that class in the session would turn foreign at once and
			// the game would stop being able to save.
			var stamped:io.newgrounds.models.objects.SaveSlot = self.foreignSlot();
			var fresh:io.newgrounds.models.objects.SaveSlot = new io.newgrounds.models.objects.SaveSlot();
			fresh.id = 1;

			t.assertTrue(stamped.isForeign(), "the stamped slot is foreign");
			t.assertFalse(fresh.isForeign(), "a slot constructed afterwards is not");

			t.assertDoesNotThrow(function():Void {
				fresh.saveDataRaw("payload", null, null);
			}, "and it can still be written to");
			t.done();
		});
	}

	//==================== HELPERS ====================

	/**
	 * Slot 1 of another app - the case that would otherwise eat our own slot 1.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function foreignSlot():io.newgrounds.models.objects.SaveSlot {
		var slot:io.newgrounds.models.objects.SaveSlot = new io.newgrounds.models.objects.SaveSlot();
		slot.id = 1;
		slot.url = "//uploads.ungrounded.net/example.sav";
		slot.foreignAppId = ngiotest.suites.OfflineForeignGuardSuite.OTHER_APP;
		return slot;
	}
}
