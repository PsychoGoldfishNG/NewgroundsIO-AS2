/**
 * LiveCrossAppSuite
 *
 * Exercises NGIO's loadExternal* methods - read-only access to another app's
 * medals, scores and cloud saves via the gateway's app_id parameter.
 *
 * Two things are being tested here, and the second matters more:
 *
 *  1. that a permitted cross-app read returns the other app's data
 *  2. that this app's own AppState is completely untouched by it
 *
 * AppState models exactly one app. A foreign medal list merged into it would
 * replace the local list wholesale and mark it loaded, so NGIO.getMedals() would
 * start handing the game another app's medals. Every test below re-checks the
 * local caches afterwards.
 *
 * The AS2 guard checks for `undefined` as well as `null` when reading app_id off
 * a result, because a result model that does not declare the property returns
 * undefined here where AS3 returns null.
 */
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.models.objects.Score;
import io.newgrounds.models.objects.ScoreBoard;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveCrossAppSuite extends ngiotest.LiveSuite {

	/** Snapshot of the local caches, taken before any cross-app call */
	private var localMedals:Array;
	private var localSaveSlots:Array;
	private var localMedalCount:Number;
	private var localSlotCount:Number;

	public function LiveCrossAppSuite() {
		super();
		this.localMedals = null;
		this.localSaveSlots = null;
		this.localMedalCount = -1;
		this.localSlotCount = -1;
	}

	public function getSuiteName():String {
		return "Live / Cross-app access";
	}

	public function setUp(done:Function):Void {
		var self:ngiotest.suites.LiveCrossAppSuite = this;

		super.setUp(function():Void {
			// Runs after LiveAppDataSuite, so these are populated. Held by
			// reference AND by count: the guard has to stop both a wholesale
			// replacement and an in-place merge.
			self.localMedals = NGIO.getMedals();
			self.localSaveSlots = NGIO.getSaveSlots();
			self.localMedalCount = (self.localMedals != null) ? self.localMedals.length : -1;
			self.localSlotCount = (self.localSaveSlots != null) ? self.localSaveSlots.length : -1;
			done.call(null);
		});
	}

	public function build():Void {

		var self:ngiotest.suites.LiveCrossAppSuite = this;
		var foreignApp:String = ngiotest.TestConfig.READABLE_FOREIGN_APP_ID;
		var foreignBoard:Number = ngiotest.TestConfig.READABLE_FOREIGN_SCOREBOARD_ID;

		//==================== ARGUMENT VALIDATION ====================

		add("rejects an empty external app id", function(t:ngiotest.TestContext):Void {
			t.assertThrows(function():Void {
				NGIO.loadExternalMedals(null, null, null);
			}, "null app id should throw");

			t.assertThrows(function():Void {
				NGIO.loadExternalMedals("", null, null);
			}, "empty app id should throw");
			t.done();
		});

		add("rejects this app's own id", function(t:ngiotest.TestContext):Void {
			// Passing your own id is a programming error, not a cross-app read:
			// it would behave like loadMedals() except uncached, which is a
			// miserable thing to debug later.
			var thrown = t.assertThrows(function():Void {
				NGIO.loadExternalMedals(ngiotest.TestConfig.APP_ID, null, null);
			}, "own app id should throw");

			if (thrown != null) {
				t.assertTrue(String(thrown.message).indexOf("own ID") >= 0,
					"and the message explains why: " + String(thrown.message));
			}
			t.done();
		});

		//==================== MEDALS ====================

		add("loads medals from an app that granted access", function(t:ngiotest.TestContext):Void {
			NGIO.loadExternalMedals(foreignApp, function(medals:Array, error):Void {

				if (!self.assertNoError(t, error, "loadExternalMedals succeeded")) {
					t.done();
					return;
				}

				if (t.assertNotNull(medals, "foreign medal list returned")) {
					t.assertTrue(medals.length > 0, "and it is not empty");

					for (var i:Number = 0; i < medals.length; i++) {
						var medal:io.newgrounds.models.objects.Medal = medals[i];
						t.assertIsType(medal, io.newgrounds.models.objects.Medal, "entry is a typed Medal");
						t.assertEquals(foreignApp, medal.foreignAppId,
							"medal " + medal.id + " is stamped with its source app");
					}
					t.note("app " + foreignApp + " returned " + medals.length + " medal(s)");
				}

				self.assertLocalCachesIntact(t);
				t.done();
			}, null);
		});

		add("foreign medals never enter the local cache", function(t:ngiotest.TestContext):Void {
			// The important one. Asserts identity, not just count: a merge would
			// have kept the array but rewritten the Medal objects in it.
			if (self.localMedals == null) {
				t.skip("local medals were not loaded, nothing to protect");
				return;
			}

			var namesBefore:String = self.describeMedals(self.localMedals);

			NGIO.loadExternalMedals(foreignApp, function(medals:Array, error):Void {

				t.assertStrictEquals(self.localMedals, NGIO.getMedals(),
					"getMedals() still returns the original local array");
				t.assertEquals(self.localMedalCount, NGIO.getMedals().length,
					"local medal count unchanged");
				t.assertEquals(namesBefore, self.describeMedals(NGIO.getMedals()),
					"local medal ids, names and values all unchanged");

				// Every local medal must still be findable by its own id
				for (var i:Number = 0; i < self.localMedals.length; i++) {
					var medal:io.newgrounds.models.objects.Medal = self.localMedals[i];
					t.assertStrictEquals(medal, NGIO.getMedal(medal.id),
						"local medal " + medal.id + " still resolves to the same instance");
					t.assertNull(medal.foreignAppId,
						"local medal " + medal.id + " was not stamped as foreign");
				}
				t.done();
			}, null);
		});

		//==================== SCORES ====================

		add("loads scores from an app that granted access", function(t:ngiotest.TestContext):Void {
			NGIO.loadExternalScores(foreignApp, foreignBoard, { period: "A", limit: 10 },
				function(scores:Array, error):Void {

					if (!self.assertNoError(t, error, "loadExternalScores succeeded")) {
						t.done();
						return;
					}

					if (t.assertNotNull(scores, "foreign score list returned")) {
						t.assertTrue(scores.length <= 10, "respects the requested limit");

						for (var i:Number = 0; i < scores.length; i++) {
							var score:io.newgrounds.models.objects.Score = scores[i];
							t.assertIsType(score, io.newgrounds.models.objects.Score, "entry is a typed Score");
							t.assertEquals(foreignApp, score.foreignAppId, "score is stamped with its source app");

							// Nested models must be stamped too - a caller can
							// easily end up holding just the User
							if (score.user != null) {
								t.assertEquals(foreignApp, score.user.foreignAppId, "nested user is stamped as well");
							}
						}
						t.note("board " + foreignBoard + " on app " + foreignApp + " returned " +
						       scores.length + " all-time score(s)");
					}

					self.assertLocalCachesIntact(t);
					t.done();
				}, null);
		});

		add("applies score filters to a cross-app read", function(t:ngiotest.TestContext):Void {
			NGIO.loadExternalScores(foreignApp, foreignBoard, { period: "A", limit: 1 },
				function(scores:Array, error):Void {
					if (self.assertNoError(t, error, "limited cross-app read succeeded")) {
						if (t.assertNotNull(scores, "scores returned")) {
							t.assertTrue(scores.length <= 1, "returned at most one score");
						}
					}
					t.done();
				}, null);
		});

		add("validates score filters the same way local reads do", function(t:ngiotest.TestContext):Void {
			t.assertThrows(function():Void {
				NGIO.loadExternalScores(foreignApp, foreignBoard, { limit: 0 }, null, null);
			}, "limit 0 should throw");

			t.assertThrows(function():Void {
				NGIO.loadExternalScores(foreignApp, foreignBoard, { limit: 101 }, null, null);
			}, "limit 101 should throw");

			t.assertThrows(function():Void {
				NGIO.loadExternalScores(foreignApp, foreignBoard, { user_id: "not-a-number" }, null, null);
			}, "mistyped user_id should throw");
			t.done();
		});

		add("a foreign scoreboard never enters the local board cache", function(t:ngiotest.TestContext):Void {
			var boardsBefore:Array = NGIO.getScoreBoards();
			if (boardsBefore == null) {
				t.skip("local scoreboards were not loaded, nothing to protect");
				return;
			}

			var fingerprint:String = self.describeBoards(boardsBefore);

			NGIO.loadExternalScores(foreignApp, foreignBoard, { period: "A", limit: 1 },
				function(scores:Array, error):Void {

					t.assertStrictEquals(boardsBefore, NGIO.getScoreBoards(),
						"getScoreBoards() still returns the original local array");
					t.assertEquals(fingerprint, self.describeBoards(NGIO.getScoreBoards()),
						"local board ids and names unchanged");
					t.assertNull(NGIO.getScoreBoard(foreignBoard),
						"the foreign board did not become locally addressable");
					t.done();
				}, null);
		});

		//==================== FOREIGN OBJECT BEHAVIOUR ====================
		//
		// A stamped ScoreBoard forwards its app_id on reads and refuses writes.
		// Only the gateway can confirm the parameter actually went out, so the
		// read half is asserted here rather than offline.

		add("a stamped board reads from the app it came from", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.core = self.getCore();
			board.id = foreignBoard;
			board.foreignAppId = foreignApp;

			board.getScores({ period: "A", limit: 5 }, function(scores:Array, error):Void {
				// This board id belongs to the other app. Getting real scores
				// back is proof the app_id was forwarded - without it the
				// gateway looks the id up against THIS app and returns 203.
				if (self.assertNoError(t, error, "foreign board getScores() succeeded")) {
					t.assertNotNull(scores, "and returned a score list");
				}
				self.assertLocalCachesIntact(t);
				t.done();
			}, null);
		});

		add("the same board without the stamp is rejected", function(t:ngiotest.TestContext):Void {
			// The negative control for the test above. If this ALSO passed, the
			// board id would simply be valid locally and the previous test would
			// prove nothing.
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.core = self.getCore();
			board.id = foreignBoard;

			board.getScores({ period: "A", limit: 5 }, function(scores:Array, error):Void {
				t.assertNotNull(error, "an unstamped foreign board id is refused");
				if (error != null) {
					t.note("gateway said: " + self.describeError(error));
				}
				t.done();
			}, null);
		});

		add("a cross-app read accepts the social filter", function(t:ngiotest.TestContext):Void {
			// 'social' is site-wide, not per-app: the friends list is a relation
			// between users, so "me and my friends" means the same thing on
			// another app's board. A social leaderboard shared across a series
			// of games is the main reason to want this.
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			NGIO.loadExternalScores(foreignApp, foreignBoard, { period: "A", limit: 10, social: true },
				function(scores:Array, error):Void {

					// An empty list is a legitimate pass - the user and their
					// friends may simply not have played that game. What is being
					// asserted is that the gateway ACCEPTS the filter on a
					// cross-app read, not that anyone scored.
					if (self.assertNoError(t, error, "social cross-app read succeeded")) {
						if (t.assertNotNull(scores, "scores returned")) {
							t.note("social read of board " + foreignBoard + " on app " + foreignApp +
							       " returned " + scores.length + " score(s)");
						}
					}
					self.assertLocalCachesIntact(t);
					t.done();
				}, null);
		});

		add("a stamped board accepts the social filter too", function(t:ngiotest.TestContext):Void {
			// Same thing through the model rather than the NGIO helper -
			// ScoreBoard.getScores must not gate 'social' on isForeign().
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.core = self.getCore();
			board.id = foreignBoard;
			board.foreignAppId = foreignApp;

			board.getScores({ period: "A", limit: 10, social: true }, function(scores:Array, error):Void {
				if (self.assertNoError(t, error, "foreign board social read succeeded")) {
					t.assertNotNull(scores, "scores returned");
				}
				t.done();
			}, null);
		});

		add("a foreign medal from the gateway refuses to unlock", function(t:ngiotest.TestContext):Void {
			// The offline suite proves the guard on a hand-stamped model. This
			// proves the stamp is really applied end to end, so the guard fires
			// on an object the gateway actually produced.
			NGIO.loadExternalMedals(foreignApp, function(medals:Array, error):Void {

				if (!self.assertNoError(t, error, "foreign medals loaded")) {
					t.done();
					return;
				}

				if (medals == null || medals.length == 0) {
					t.skip("that app returned no medals to test against");
					return;
				}

				var medal:io.newgrounds.models.objects.Medal = medals[0];
				t.assertTrue(medal.isForeign(), "the returned medal knows it is foreign");

				var thrown = t.assertThrows(function():Void {
					medal.unlock(null, null);
				}, "and refuses to unlock");

				if (thrown != null) {
					t.note(String(thrown.message));
				}
				t.done();
			}, null);
		});

		//==================== CLOUD SAVES ====================

		add("loads save slots from an app that granted access", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			NGIO.loadExternalSaveSlots(foreignApp, function(slots:Array, error):Void {

				if (!self.assertNoError(t, error, "loadExternalSaveSlots succeeded")) {
					t.done();
					return;
				}

				if (t.assertNotNull(slots, "foreign slot list returned")) {
					for (var i:Number = 0; i < slots.length; i++) {
						var slot:io.newgrounds.models.objects.SaveSlot = slots[i];
						t.assertIsType(slot, io.newgrounds.models.objects.SaveSlot, "entry is a typed SaveSlot");
						t.assertEquals(foreignApp, slot.foreignAppId,
							"slot " + slot.id + " is stamped with its source app");
					}
					t.note("app " + foreignApp + " returned " + slots.length + " save slot(s)");
				}

				self.assertLocalCachesIntact(t);
				t.done();
			}, null);
		});

		add("foreign save slots never enter the local cache", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}
			if (self.localSaveSlots == null) {
				t.skip("local save slots were not loaded, nothing to protect");
				return;
			}

			var slotsBefore:String = self.describeSlots(self.localSaveSlots);

			NGIO.loadExternalSaveSlots(foreignApp, function(slots:Array, error):Void {

				t.assertStrictEquals(self.localSaveSlots, NGIO.getSaveSlots(),
					"getSaveSlots() still returns the original local array");
				t.assertEquals(slotsBefore, self.describeSlots(NGIO.getSaveSlots()),
					"local slot ids, sizes and urls all unchanged");

				for (var i:Number = 0; i < self.localSaveSlots.length; i++) {
					var slot:io.newgrounds.models.objects.SaveSlot = self.localSaveSlots[i];
					t.assertNull(slot.foreignAppId, "local slot " + slot.id + " was not stamped as foreign");
				}
				t.done();
			}, null);
		});

		add("loads a single save slot from another app", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			NGIO.loadExternalSaveSlot(foreignApp, 1, function(slot:io.newgrounds.models.objects.SaveSlot, error):Void {

				if (!self.assertNoError(t, error, "loadExternalSaveSlot succeeded")) {
					t.done();
					return;
				}

				if (t.assertNotNull(slot, "a slot was returned")) {
					t.assertIsType(slot, io.newgrounds.models.objects.SaveSlot, "it is a typed SaveSlot");
					t.assertEquals(1, slot.id, "and it is the slot we asked for");
					t.assertEquals(foreignApp, slot.foreignAppId, "stamped with its source app");
				}

				self.assertLocalCachesIntact(t);
				t.done();
			}, null);
		});

		//==================== REFUSAL ====================

		add("refuses an app that has not granted access", function(t:ngiotest.TestContext):Void {
			NGIO.loadExternalMedals(ngiotest.TestConfig.UNREADABLE_FOREIGN_APP_ID,
				function(medals:Array, error):Void {

					var refused:Boolean = (error != null) || (medals == null);

					if (error != null) {
						t.note("refused: " + self.describeError(error));
					} else if (medals == null) {
						t.note("no error, but no medals returned either");
					} else {
						t.note("WARNING: app " + ngiotest.TestConfig.UNREADABLE_FOREIGN_APP_ID +
						       " returned " + medals.length + " medal(s) to an app it has not authorised");
					}

					t.assertTrue(refused, "unauthorised cross-app read is refused");
					self.assertLocalCachesIntact(t);
					t.done();
				}, null);
		});

		//==================== NON-INTERFERENCE ====================

		add("local calls still cache normally afterwards", function(t:ngiotest.TestContext):Void {
			// Guards against over-correcting: the AppState guard keys off "is
			// this a different app", not "does the result mention an app_id at
			// all". If it were the latter, ordinary loads would stop caching.
			NGIO.loadMedals(function(medals:Array, error):Void {
				if (!self.assertNoError(t, error, "local medal reload succeeded")) {
					t.done();
					return;
				}

				t.assertNotNull(NGIO.getMedals(), "local medals still cached");
				t.assertTrue(self.getCore().appState.hasLoaded("medals"), "still marked loaded");
				if (self.localMedalCount >= 0) {
					t.assertEquals(self.localMedalCount, NGIO.getMedals().length,
						"and the count is the local app's, not the foreign one's");
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================
	//
	// Public because the closures above reach them through `self`.

	/**
	 * Assert the local caches still look exactly as they did at setUp.
	 */
	public function assertLocalCachesIntact(t:ngiotest.TestContext):Void {
		if (localMedals != null) {
			t.assertStrictEquals(localMedals, NGIO.getMedals(), "local medal array untouched");
			t.assertEquals(localMedalCount, NGIO.getMedals().length, "local medal count untouched");
		}
		if (localSaveSlots != null) {
			t.assertStrictEquals(localSaveSlots, NGIO.getSaveSlots(), "local save slot array untouched");
			t.assertEquals(localSlotCount, NGIO.getSaveSlots().length, "local slot count untouched");
		}
	}

	/**
	 * A stable fingerprint of a medal list, so an in-place merge is detected
	 * even when the array identity and length survive.
	 */
	public function describeMedals(medals:Array):String {
		var parts:Array = [];
		for (var i:Number = 0; i < medals.length; i++) {
			parts.push(medals[i].id + ":" + medals[i].name + ":" + medals[i].value);
		}
		return parts.join("|");
	}

	public function describeSlots(slots:Array):String {
		var parts:Array = [];
		for (var i:Number = 0; i < slots.length; i++) {
			parts.push(slots[i].id + ":" + slots[i].size + ":" + slots[i].url);
		}
		return parts.join("|");
	}

	public function describeBoards(boards:Array):String {
		var parts:Array = [];
		for (var i:Number = 0; i < boards.length; i++) {
			parts.push(boards[i].id + ":" + boards[i].name);
		}
		return parts.join("|");
	}
}
