/**
 * LiveAppDataSuite
 *
 * Batch-loads the app's catalogue (medals, scoreboards, save slots) in a single
 * request and checks it against what the test app is configured with.
 *
 * Runs before the medal/scoreboard/cloud save suites, which rely on the caches
 * this populates.
 *
 * The expected counts live in TestConfig and are asserted, so if the AS2 test
 * app's configuration changes on Newgrounds these fail until TestConfig is
 * updated to match. That is deliberate - a silently drifting app config is
 * exactly the thing that makes a later live failure impossible to explain.
 */
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.models.objects.ScoreBoard;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveAppDataSuite extends ngiotest.LiveSuite {

	public function LiveAppDataSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / App data";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveAppDataSuite = this;

		add("batch-loads medals, scoreboards and save slots", function(t:ngiotest.TestContext):Void {
			// One loadData() call for three properties should produce one
			// request carrying three components, not three requests.
			t.status("Loading app data...");

			NGIO.loadAppData(["medals", "scoreBoards", "saveSlots"], function(error):Void {
				if (!self.assertNoError(t, error, "batch load completed")) {
					t.done();
					return;
				}

				var state = self.getCore().appState;
				t.assertTrue(state.hasLoaded("medals"), "medals marked loaded");
				t.assertTrue(state.hasLoaded("scoreBoards"), "scoreBoards marked loaded");
				t.assertTrue(state.hasLoaded("saveSlots"), "saveSlots marked loaded");
				t.done();
			}, null);
		});

		add("returns the configured medals", function(t:ngiotest.TestContext):Void {
			var medals:Array = NGIO.getMedals();
			if (!t.assertNotNull(medals, "medal list cached")) {
				t.done();
				return;
			}

			t.assertEquals(ngiotest.TestConfig.EXPECTED_MEDAL_COUNT, medals.length,
				"medal count matches the app configuration");

			for (var i:Number = 0; i < medals.length; i++) {
				var medal:io.newgrounds.models.objects.Medal = medals[i];

				t.assertTrue(medal.id > 0, "medal has a real id");
				t.assertNotNull(medal.name, "medal " + medal.id + " has a name");
				t.assertNotNull(medal.icon, "medal " + medal.id + " has an icon url");
				t.assertTrue(medal.difficulty >= 1 && medal.difficulty <= 5,
					"medal " + medal.id + " difficulty is 1-5, got " + medal.difficulty);

				// Not "> 0": a medal worth 0 points is a legitimate Newgrounds
				// configuration - medals report 0 until they have been unlocked
				// once outside debug mode - and asserting otherwise made the AS3
				// suite fail on the app's own data rather than on a library
				// fault. Worth surfacing as a note, since an unintended 0 is
				// still worth noticing.
				t.assertTrue(medal.value >= 0, "medal " + medal.id + " has a non-negative point value");
				if (medal.value == 0) {
					t.note("NOTE: medal " + medal.id + " (" + medal.name + ") is worth 0 points");
				}

				t.note(medal.toString() + " (" + medal.value + "pts, difficulty " + medal.difficulty +
				       ", unlocked=" + medal.unlocked + ")");
			}
			t.done();
		});

		add("looks a medal up by id", function(t:ngiotest.TestContext):Void {
			var medals:Array = NGIO.getMedals();
			if (medals == null || medals.length == 0) {
				t.skip("no medals loaded");
				return;
			}

			var first:io.newgrounds.models.objects.Medal = medals[0];
			var found = NGIO.getMedal(first.id);

			t.assertNotNull(found, "getMedal() found the medal");
			t.assertStrictEquals(first, found, "returns the cached instance, not a copy");
			t.assertNull(NGIO.getMedal(-1), "unknown medal id returns null");
			t.done();
		});

		add("returns the configured scoreboards", function(t:ngiotest.TestContext):Void {
			var boards:Array = NGIO.getScoreBoards();
			if (!t.assertNotNull(boards, "scoreboard list cached")) {
				t.done();
				return;
			}

			t.assertEquals(ngiotest.TestConfig.EXPECTED_SCOREBOARD_COUNT, boards.length,
				"scoreboard count matches the app configuration");

			for (var i:Number = 0; i < boards.length; i++) {
				var board:io.newgrounds.models.objects.ScoreBoard = boards[i];
				t.assertTrue(board.id > 0, "board has a real id");
				t.assertNotNull(board.name, "board " + board.id + " has a name");
				t.note("ScoreBoard #" + board.id + " - " + board.name);
			}
			t.done();
		});

		add("looks a scoreboard up by id", function(t:ngiotest.TestContext):Void {
			var boards:Array = NGIO.getScoreBoards();
			if (boards == null || boards.length == 0) {
				t.skip("no scoreboards loaded");
				return;
			}

			var first:io.newgrounds.models.objects.ScoreBoard = boards[0];
			t.assertStrictEquals(first, NGIO.getScoreBoard(first.id), "returns the cached instance");
			t.assertNull(NGIO.getScoreBoard(-1), "unknown board id returns null");
			t.done();
		});

		add("returns the configured save slots", function(t:ngiotest.TestContext):Void {
			var slots:Array = NGIO.getSaveSlots();
			if (!t.assertNotNull(slots, "save slot list cached")) {
				t.done();
				return;
			}

			t.assertEquals(ngiotest.TestConfig.EXPECTED_SAVE_SLOT_COUNT, slots.length,
				"save slot count matches the app configuration");

			for (var i:Number = 0; i < slots.length; i++) {
				var slot:io.newgrounds.models.objects.SaveSlot = slots[i];
				t.assertTrue(slot.id > 0, "slot has a real id");

				// A slot with data must carry both a url and a size; one without
				// either is a half-populated response.
				if (slot.hasData()) {
					t.assertTrue(slot.size > 0, "slot " + slot.id + " with data reports a size");
					t.assertNotNull(slot.datetime, "slot " + slot.id + " with data reports a datetime");
				}
			}

			t.note(self.countUsedSlots(slots) + " of " + slots.length + " slots currently hold data");
			t.done();
		});

		add("rejects an unknown property name", function(t:ngiotest.TestContext):Void {
			// Guards against a silent no-op when a caller mistypes a name.
			//
			// This is one of the tests that only became meaningful once
			// AppState stopped validating names with Array.indexOf, which AVM1
			// does not have: the check returned undefined, the comparison never
			// matched, and every misspelled property name was accepted.
			t.assertThrows(function():Void {
				NGIO.loadAppData(["medalz"], null, null);
			}, "loadAppData rejects a misspelled property");
			t.done();
		});

		add("loads the user's total medal score", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			NGIO.loadMedalScore(function(score:Number, error):Void {
				if (self.assertNoError(t, error, "medal score loaded")) {
					t.assertTrue(score >= 0, "score is not negative, got " + score);
					t.assertEquals(score, NGIO.getMedalScore(), "cached on AppState");
					t.note("medal score for this app: " + score);
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================

	/** Public because the closures above reach it through `self`. */
	public function countUsedSlots(slots:Array):Number {
		var used:Number = 0;
		for (var i:Number = 0; i < slots.length; i++) {
			if (slots[i].hasData()) {
				used++;
			}
		}
		return used;
	}
}
