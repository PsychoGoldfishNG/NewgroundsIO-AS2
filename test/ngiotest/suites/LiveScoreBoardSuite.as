/**
 * LiveScoreBoardSuite
 *
 * Covers the second encrypted component (ScoreBoard.postScore) plus the
 * filtering options on ScoreBoard.getScores.
 *
 * The test app has two boards - one standard, one incremental - and the suite
 * posts to whichever comes back first. In debug mode nothing is committed.
 */
import io.newgrounds.models.objects.Response;
import io.newgrounds.models.objects.Score;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.User;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveScoreBoardSuite extends ngiotest.LiveSuite {

	public function LiveScoreBoardSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / ScoreBoards";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveScoreBoardSuite = this;

		add("loads scores from a board", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			board.getScores({ period: "A", limit: 10 }, function(scores:Array, error):Void {
				if (!self.assertNoError(t, error, "getScores returned")) {
					t.done();
					return;
				}

				if (!t.assertNotNull(scores, "scores array returned")) {
					t.done();
					return;
				}

				t.assertTrue(scores.length <= 10, "respects the requested limit");
				t.note("board '" + board.name + "' returned " + scores.length + " all-time scores");

				for (var i:Number = 0; i < scores.length; i++) {
					var score:io.newgrounds.models.objects.Score = scores[i];
					t.assertIsType(score, io.newgrounds.models.objects.Score, "entry is a Score model");
					t.assertNotNull(score.formatted_value, "score carries a formatted value");

					// A board score always belongs to somebody; a null user here
					// means the nested cast silently dropped it.
					if (t.assertNotNull(score.user, "score carries a user")) {
						t.assertIsType(score.user, io.newgrounds.models.objects.User, "user is a User model");
					}
				}
				t.done();
			}, null);
		});

		add("honours the limit filter", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			board.getScores({ period: "A", limit: 1 }, function(scores:Array, error):Void {
				if (self.assertNoError(t, error, "limited getScores returned")) {
					if (t.assertNotNull(scores, "scores returned")) {
						t.assertTrue(scores.length <= 1, "returned at most one score");
					}
				}
				t.done();
			}, null);
		});

		//==================== SERVER-SIDE CLAMPING ====================
		//
		// These go through core.callComponent rather than ScoreBoard.getScores,
		// deliberately. The model THROWS on a limit outside 1-100 before
		// anything is sent, so the server's own clamping is unreachable from the
		// normal API - which means the behaviour the library's validation is
		// designed around has never actually been checked.
		//
		// The echoed limit/skip prove what the server DECIDED on any board.
		// Proving it actually stopped at 100 ROWS needs a board holding more
		// than 100 scores, which no test app has - hence
		// TestConfig.SCORE_RICH_APP_ID.

		add("server clamps an oversized limit to 100", function(t:ngiotest.TestContext):Void {
			self.clampTarget(t, function(appId:String, boardId:Number, isRich:Boolean):Void {

				self.requestScores(t, appId, boardId, { period: "A", limit: 500 }, function(result):Void {
					if (!ngiotest.TestConfig.SERVER_CLAMPS_SCORE_LIMIT) {
						t.note("sent limit 500, server used " + result.limit +
						       " - this gateway does not clamp (SERVER_CLAMPS_SCORE_LIMIT is false)");
						t.skip("server-side limit clamping is not enabled on this gateway");
						return;
					}

					// If this comes back as 500, the library is throwing on
					// values the server would have accepted, and the 1-100 rule
					// in the guide is wrong.
					t.assertEquals(100, result.limit, "limit 500 clamped to 100");

					if (result.scores == null) {
						t.note("sent limit 500, server used " + result.limit + " (no rows returned)");
					} else if (isRich) {
						// The real assertion, and only possible on a board with
						// more than 100 rows: a two-row board satisfies "at most
						// 100" without the clamp doing anything.
						t.assertEquals(100, result.scores.length,
							"and returned exactly 100 rows from a board that holds more");
						t.note("board " + boardId + " on " + appId + ": sent limit 500, server used " +
						       result.limit + " and returned " + result.scores.length + " rows");
					} else {
						t.assertTrue(result.scores.length <= 100, "and no more than 100 rows came back");
						t.note("sent limit 500, server used " + result.limit + ", got " + result.scores.length +
						       " rows - too few rows on this board to prove the row cap");
					}
					t.done();
				});
			});
		});

		add("server clamps a zero limit up to 1", function(t:ngiotest.TestContext):Void {
			// The floor matters as much as the ceiling: a caller who means
			// "none" silently gets one score. That is why the library rejects 0
			// rather than passing it through - and why that rejection matters
			// MORE before the clamp ships, since production currently returns an
			// empty list for limit 0.
			self.clampTarget(t, function(appId:String, boardId:Number, isRich:Boolean):Void {

				self.requestScores(t, appId, boardId, { period: "A", limit: 0 }, function(result):Void {
					if (!ngiotest.TestConfig.SERVER_CLAMPS_SCORE_LIMIT) {
						t.note("sent limit 0, server used " + result.limit + " and returned " +
						       ((result.scores == null) ? "no" : String(result.scores.length)) + " row(s)");
						t.skip("server-side limit clamping is not enabled on this gateway");
						return;
					}

					t.assertEquals(1, result.limit, "limit 0 clamped up to 1");
					if (isRich && result.scores != null) {
						t.assertEquals(1, result.scores.length, "and returned exactly one row");
					}
					t.note("sent limit 0, server used " + result.limit);
					t.done();
				});
			});
		});

		add("server does not cap how far scores can be skipped", function(t:ngiotest.TestContext):Void {
			// Paging depth is not capped - the 1-100 rule is about page SIZE
			// only, so a large skip must be accepted rather than clamped.
			//
			// Deliberately does NOT assert that the echoed skip equals what was
			// sent. Production echoed skip+1 for a while (send 0, get 1; send
			// 500, get 501) - a server-side off-by-one, since fixed on the
			// development branch and confirmed unused by any NGIO library.
			//
			// Asserting equality would have failed for a reason that was never
			// the library's, so this asserts the contractual part - that a large
			// skip is ACCEPTED and not capped - and notes any mismatch. The note
			// disappearing is how the deploy gets noticed, without the test
			// going red while the fix is in flight.
			self.clampTarget(t, function(appId:String, boardId:Number, isRich:Boolean):Void {

				self.requestScores(t, appId, boardId, { period: "A", limit: 10, skip: 500 }, function(result):Void {
					t.assertTrue(result.skip >= 500, "a skip of 500 was not capped, server reported " + result.skip);

					if (result.skip != 500) {
						t.note("NOTE: sent skip 500, server echoed " + result.skip +
						       " - the echoed skip is not a round-trip of the request");
					} else {
						t.note("sent skip 500, server used " + result.skip);
					}
					t.done();
				});
			});
		});

		add("accepts every documented period", function(t:ngiotest.TestContext):Void {
			// D/W/M/Y/A are the documented values. A rejected period would mean
			// the parameter is not reaching the server correctly.
			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			var periods:Array = ["D", "W", "M", "Y", "A"];
			var remaining:Object = { count: periods.length };

			// Each request is armed by a helper rather than inline, so the
			// period is bound to that call. An AS2 closure captures the
			// enclosing scope rather than a snapshot of it, so a callback
			// reading the loop variable later would see whatever the loop
			// finished on - here, "A" five times over.
			for (var i:Number = 0; i < periods.length; i++) {
				self.probePeriod(t, board, periods[i], remaining);
			}
		});

		add("accepts the social filter on a local board", function(t:ngiotest.TestContext):Void {
			// A GAP IN THE AS3 SUITE, filled here rather than carried across.
			// The AS3 README claims to cover "every documented getScores filter"
			// but never exercises 'social' locally at all - which is precisely
			// how a wrong change to it survived long enough to be shipped to
			// four repositories.
			//
			// Asserted LOOSELY on purpose. A social read legitimately returns an
			// empty list when the user and their friends have not played this
			// game, so this asserts that the filter is ACCEPTED and the response
			// is well formed - not that anybody scored.
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			board.getScores({ period: "A", limit: 10, social: true }, function(scores:Array, error):Void {
				if (!self.assertNoError(t, error, "social getScores accepted")) {
					t.done();
					return;
				}

				if (t.assertNotNull(scores, "a scores array came back, even if empty")) {
					for (var i:Number = 0; i < scores.length; i++) {
						t.assertIsType(scores[i], io.newgrounds.models.objects.Score, "entry is a Score model");
					}
					t.note("social read returned " + scores.length + " score(s) - an empty list is a valid result here");
				}
				t.done();
			}, null);
		});

		add("posts a score", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			var value:Number = 1000 + Math.floor(Math.random() * 9000);
			board.postScore(value, null, function(score:io.newgrounds.models.objects.Score, error):Void {
				if (!self.assertNoError(t, error, "postScore accepted")) {
					t.done();
					return;
				}

				if (t.assertNotNull(score, "server echoed the posted score")) {
					t.assertIsType(score, io.newgrounds.models.objects.Score, "is a Score model");
					t.assertNotNull(score.formatted_value, "carries a formatted value");
					t.note("posted " + value + ", server returned " + score.value +
					       " (" + score.formatted_value + ")");
				}
				t.done();
			}, null);
		});

		add("posts a tagged score", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			board.postScore(4242, "unit-test", function(score:io.newgrounds.models.objects.Score, error):Void {
				if (self.assertNoError(t, error, "tagged postScore accepted")) {
					if (t.assertNotNull(score, "server echoed the score")) {
						t.assertEquals("unit-test", score.tag, "tag round-tripped");
					}
				}
				t.done();
			}, null);
		});

		add("filters scores by tag", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			board.getScores({ period: "A", limit: 10, tag: "unit-test" }, function(scores:Array, error):Void {
				if (self.assertNoError(t, error, "tag-filtered getScores returned")) {
					if (t.assertNotNull(scores, "scores returned")) {
						for (var i:Number = 0; i < scores.length; i++) {
							t.assertEquals("unit-test", scores[i].tag, "every result carries the requested tag");
						}
						t.note(scores.length + " score(s) tagged 'unit-test'");
					}
				}
				t.done();
			}, null);
		});

		add("filters scores by user", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var board:io.newgrounds.models.objects.ScoreBoard = self.firstBoard();
			if (board == null) {
				t.skip("no scoreboards loaded");
				return;
			}

			var signedIn:io.newgrounds.models.objects.User = self.getUser();

			board.getScores({ period: "A", limit: 10, user_id: signedIn.id }, function(scores:Array, error):Void {
				if (self.assertNoError(t, error, "user-filtered getScores returned")) {
					if (t.assertNotNull(scores, "scores returned")) {
						for (var i:Number = 0; i < scores.length; i++) {
							if (scores[i].user != null) {
								t.assertEquals(signedIn.id, scores[i].user.id, "every result belongs to the requested user");
							}
						}
					}
				}
				t.done();
			}, null);
		});

		add("rejects an unknown board id", function(t:ngiotest.TestContext):Void {
			var bogus:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			bogus.core = self.getCore();
			bogus.id = 99999999;

			bogus.getScores({ period: "A", limit: 1 }, function(scores:Array, error):Void {
				t.assertNotNull(error, "server rejected the unknown board id");
				if (error != null) {
					t.note("server said: " + self.describeError(error));
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================
	//
	// Public because the closures above reach them through `self`.

	public function firstBoard():io.newgrounds.models.objects.ScoreBoard {
		var boards:Array = NGIO.getScoreBoards();
		if (boards == null || boards.length == 0) {
			return null;
		}
		return boards[0];
	}

	/**
	 * One period probe, with the period bound to this call rather than read
	 * from a loop variable.
	 *
	 * @param remaining A shared counter object; the test finishes when it hits
	 *                  zero. An object rather than a Number because AS2 captures
	 *                  variables by reference to the scope, and reassigning a
	 *                  captured Number from five callbacks is exactly the kind
	 *                  of thing that works until it does not.
	 */
	public function probePeriod(t:ngiotest.TestContext, board:io.newgrounds.models.objects.ScoreBoard,
	                            period:String, remaining:Object):Void {
		var self:ngiotest.suites.LiveScoreBoardSuite = this;

		board.getScores({ period: period, limit: 1 }, function(scores:Array, error):Void {
			self.assertNoError(t, error, "period '" + period + "' accepted");
			remaining.count--;
			if (remaining.count == 0) {
				t.done();
			}
		}, null);
	}

	/**
	 * Picks the board the clamp probes should run against.
	 *
	 * Prefers TestConfig.SCORE_RICH_APP_ID, which is the only way to tell a
	 * working row cap from a board that simply holds fewer than 100 rows. Falls
	 * back to a local board, where the echoed limit is still meaningful, and
	 * skips only when there is no board at all.
	 *
	 * Calls back as onTarget(appId, boardId, isRich) - appId empty for local.
	 */
	public function clampTarget(t:ngiotest.TestContext, onTarget:Function):Void {
		var richApp:String = ngiotest.TestConfig.SCORE_RICH_APP_ID;

		if (richApp != null && richApp.length > 0) {
			onTarget(richApp, ngiotest.TestConfig.SCORE_RICH_BOARD_ID, true);
			return;
		}

		var board:io.newgrounds.models.objects.ScoreBoard = firstBoard();
		if (board == null) {
			t.skip("no scoreboards loaded");
			return;
		}
		onTarget("", board.id, false);
	}

	/**
	 * Calls ScoreBoard.getScores through Core, skipping the model's own argument
	 * validation.
	 *
	 * ScoreBoard.getScores() throws on a limit outside 1-100, which is correct
	 * for game code but makes the server's clamping impossible to observe. Going
	 * through callComponent sends exactly what we ask, so the server can answer
	 * for itself.
	 *
	 * An empty appId reads this app's own board; otherwise the read is
	 * cross-app, and that app must have granted access to APP_ID.
	 *
	 * Fails the test and finishes it on any error, so callers only handle the
	 * success case.
	 */
	public function requestScores(t:ngiotest.TestContext, appId:String, boardId:Number,
	                              params:Object, onResult:Function):Void {
		var self:ngiotest.suites.LiveScoreBoardSuite = this;

		params.id = boardId;

		if (appId != null && appId.length > 0) {
			params.app_id = appId;
		}

		getCore().callComponent("ScoreBoard.getScores", params, function(response:io.newgrounds.models.objects.Response, callbackParams):Void {

			if (response == null || response.success !== true) {
				self.assertNoError(t, (response != null) ? response.error : null, "raw getScores request succeeded");
				t.done();
				return;
			}

			var result = response.getResult();

			if (result == null) {
				t.fail("response did not carry a getScores result");
				t.done();
				return;
			}

			if (result.success !== true) {
				self.assertNoError(t, result.error, "getScores component succeeded");
				t.done();
				return;
			}

			onResult(result);
		}, null, null);
	}
}
