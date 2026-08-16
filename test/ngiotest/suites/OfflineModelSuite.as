/**
 * OfflineModelSuite
 *
 * Behaviour hand-written onto individual models: string formatting, session
 * clearing, and the argument validation ScoreBoard.getScores does before it
 * ever touches the network.
 */
import io.newgrounds.AppState;
import io.newgrounds.Core;
import io.newgrounds.Errors;
import io.newgrounds.SessionStatus;
import io.newgrounds.helpers.HttpStatusHelper;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.NgioError;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.models.objects.Score;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.User;

import ngiotest.TestConfig;
import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineModelSuite extends ngiotest.TestSuite {

	public function OfflineModelSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Offline / Models";
	}

	public function build():Void {

		var self:ngiotest.suites.OfflineModelSuite = this;

		//==================== toString ====================

		add("models describe themselves usefully", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 12;
			medal.name = "Winner";
			t.assertEquals("Medal #12 - Winner", medal.toString(), "populated medal");

			var emptyMedal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			t.assertEquals("Medal #0 - null", emptyMedal.toString(), "empty medal");

			var user:io.newgrounds.models.objects.User = new io.newgrounds.models.objects.User();
			user.name = "Tester";
			t.assertEquals("Tester", user.toString(), "populated user");

			var emptyUser:io.newgrounds.models.objects.User = new io.newgrounds.models.objects.User();
			t.assertEquals("null", emptyUser.toString(), "empty user");

			var score:io.newgrounds.models.objects.Score = new io.newgrounds.models.objects.Score();
			score.value = 500;
			t.assertEquals("Score Value: 500", score.toString(), "populated score");

			var ngioError:io.newgrounds.models.objects.NgioError = new io.newgrounds.models.objects.NgioError();
			ngioError.message = "Something broke";
			t.assertEquals("Something broke", ngioError.toString(), "populated error");

			var emptyError:io.newgrounds.models.objects.NgioError = new io.newgrounds.models.objects.NgioError();
			t.assertEquals("null", emptyError.toString(), "empty error");
			t.done();
		});

		//==================== SESSION ====================

		add("Session.clearSessionData() resets every field", function(t:ngiotest.TestContext):Void {
			var session:io.newgrounds.models.objects.Session = new io.newgrounds.models.objects.Session();
			session.id = "sess-1";
			session.user = new io.newgrounds.models.objects.User();
			session.passport_url = "https://example.com/passport";
			session.expired = true;
			session.remember = true;
			session.verified = true;
			session.preauthenticatedId = "sess-1";

			session.clearSessionData();

			t.assertNull(session.id, "id cleared");
			t.assertNull(session.user, "user cleared");
			t.assertNull(session.passport_url, "passport url cleared");
			t.assertFalse(session.expired, "expired reset");
			t.assertFalse(session.remember, "remember reset");
			t.assertFalse(session.verified, "verified reset");
			t.assertEquals("", session.preauthenticatedId, "preauthenticated id cleared");
			t.done();
		});

		add("Session.isPreauthenticated() only matches the same id", function(t:ngiotest.TestContext):Void {
			var session:io.newgrounds.models.objects.Session = new io.newgrounds.models.objects.Session();
			t.assertFalse(session.isPreauthenticated(), "empty session is not preauthenticated");

			session.preauthenticatedId = "from-url";
			session.id = "different";
			t.assertFalse(session.isPreauthenticated(), "different id is not preauthenticated");

			session.id = "from-url";
			t.assertTrue(session.isPreauthenticated(), "matching id is preauthenticated");
			t.done();
		});

		add("Medal.clearSessionData() only clears the unlocked flag", function(t:ngiotest.TestContext):Void {
			// Medal metadata is app-scoped and survives logout; only the
			// per-user unlock state is session-scoped.
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 5;
			medal.name = "Keep me";
			medal.value = 25;
			medal.unlocked = true;

			medal.clearSessionData();

			t.assertFalse(medal.unlocked, "unlocked reset");
			t.assertEquals(5, medal.id, "id retained");
			t.assertEquals("Keep me", medal.name, "name retained");
			t.assertEquals(25, medal.value, "value retained");
			t.done();
		});

		//==================== SAVESLOT ====================

		add("SaveSlot.hasData() keys off the url", function(t:ngiotest.TestContext):Void {
			var slot:io.newgrounds.models.objects.SaveSlot = new io.newgrounds.models.objects.SaveSlot();
			t.assertFalse(slot.hasData(), "fresh slot has no data");

			slot.url = "//example.com/save";
			t.assertTrue(slot.hasData(), "slot with a url has data");

			slot.url = null;
			t.assertFalse(slot.hasData(), "cleared slot has no data");
			t.done();
		});

		add("SaveSlot.loadDataRaw() short-circuits on an empty slot", function(t:ngiotest.TestContext):Void {
			// Must call back rather than hang, and must not attempt a request.
			var slot:io.newgrounds.models.objects.SaveSlot = new io.newgrounds.models.objects.SaveSlot();
			slot.id = 1;

			slot.loadDataRaw(function(data:String, error):Void {
				t.assertNull(data, "no data returned");
				t.assertNull(error, "and it is not treated as an error");
				t.done();
			}, null);
		});

		//==================== SCOREBOARD ARGUMENT VALIDATION ====================

		add("ScoreBoard.getScores() rejects an out-of-range limit", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.id = 1;

			t.assertThrows(function():Void {
				board.getScores({ limit: 0 }, null, null);
			}, "limit 0 should throw");

			t.assertThrows(function():Void {
				board.getScores({ limit: 101 }, null, null);
			}, "limit 101 should throw");

			t.assertThrows(function():Void {
				board.getScores({ limit: -5 }, null, null);
			}, "negative limit should throw");

			t.note("This rejection matters MORE while the gateway does not clamp: on production as of " +
			       "2026-08-14 a limit of 0 returns an empty list rather than one score, so without this " +
			       "check the caller would silently get nothing.");
			t.done();
		});

		add("ScoreBoard.getScores() rejects mistyped user filters", function(t:ngiotest.TestContext):Void {
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.id = 1;

			t.assertThrows(function():Void {
				board.getScores({ user_id: "not-a-number" }, null, null);
			}, "string user_id should throw");

			t.assertThrows(function():Void {
				board.getScores({ user_name: 12345 }, null, null);
			}, "numeric user_name should throw");

			t.assertThrows(function():Void {
				board.getScores({ user: "not-a-user" }, null, null);
			}, "string user should throw");
			t.done();
		});

		add("ScoreBoard.getScores() accepts the documented limits", function(t:ngiotest.TestContext):Void {
			// core is null, so these stop after validation without any request.
			var board:io.newgrounds.models.objects.ScoreBoard = new io.newgrounds.models.objects.ScoreBoard();
			board.id = 1;

			// Untyped catch: AS2 lets any value be thrown, so a typed one could
			// miss the throw entirely and turn a failure into a pass.
			try {
				board.getScores({ limit: 1 }, null, null);
				board.getScores({ limit: 100 }, null, null);
				board.getScores({ period: "A", skip: 20 }, null, null);
				board.getScores({ user_id: 42 }, null, null);
				board.getScores({ user_name: "Tester" }, null, null);
				board.getScores(null, null, null);
				t.assert(true, "valid filters accepted");
			} catch (e) {
				t.fail("valid filters should not throw, got: " + t.describeThrown(e));
			}
			t.done();
		});

		//==================== ERRORS ====================

		add("Errors maps codes to messages", function(t:ngiotest.TestContext):Void {
			var errors = io.newgrounds.Errors;

			t.assertEquals("Your session has expired.", errors.getDefaultMessage(errors.EXPIRED_SESSION), "104");
			t.assertEquals("You must be logged in to do that.", errors.getDefaultMessage(errors.LOGIN_REQUIRED), "110");
			t.assertEquals("An unknown error has occurred.", errors.getDefaultMessage(errors.UNKNOWN), "0");
			t.assertEquals("An unknown error has occurred.", errors.getDefaultMessage(99999), "unmapped code falls back");
			t.done();
		});

		add("Errors.getError() builds an NgioError", function(t:ngiotest.TestContext):Void {
			var errors = io.newgrounds.Errors;

			var fallback = errors.getError(0, null, false);
			t.assertIsType(fallback, io.newgrounds.models.objects.NgioError, "default is an NgioError");
			t.assertEquals(0, fallback.code, "default code is UNKNOWN");
			t.assertEquals("An unknown error has occurred.", fallback.message, "default message");

			var coded = errors.getError(errors.INVALID_MEDAL_ID, null, false);
			t.assertEquals(202, coded.code, "code retained");
			t.assertEquals(errors.getDefaultMessage(202), coded.message, "default message for the code");

			var custom = errors.getError(errors.INVALID_MEDAL_ID, "Medal 5 is not ours", false);
			t.assertEquals("Medal 5 is not ours", custom.message, "custom message replaces the default");

			var appended = errors.getError(errors.INVALID_MEDAL_ID, "Medal 5 is not ours", true);
			t.assertEquals(errors.getDefaultMessage(202) + " Medal 5 is not ours", appended.message,
				"appended message follows the default");

			var emptyCustom = errors.getError(errors.INVALID_MEDAL_ID, "", true);
			t.assertEquals(errors.getDefaultMessage(202), emptyCustom.message,
				"an empty custom message does not produce a trailing space");
			t.done();
		});

		add("Errors survives its lazily built message table", function(t:ngiotest.TestContext):Void {
			// AS2-specific. The message map cannot be an object literal, because
			// AS2 literals do not take numeric keys, so it is built on first use
			// and cached in a static. A second call has to hit the cache rather
			// than rebuild or return undefined.
			var errors = io.newgrounds.Errors;

			var first:String = errors.getDefaultMessage(202);
			var second:String = errors.getDefaultMessage(202);

			t.assertEquals(first, second, "repeated lookups agree");
			t.assertTrue(first.length > 0, "and are not empty");
			t.done();
		});

		//==================== APPSTATE ====================

		add("AppState guards its property names", function(t:ngiotest.TestContext):Void {
			var state:io.newgrounds.AppState = self.freshAppState();

			t.assertThrows(function():Void {
				state.hasLoaded("nonsense");
			}, "hasLoaded rejects an unknown name");

			t.assertThrows(function():Void {
				state.markLoaded("nonsense");
			}, "markLoaded rejects an unknown name");

			t.assertThrows(function():Void {
				state.loadData(["meddles"], null, null);
			}, "loadData rejects a misspelled name");

			t.assertThrows(function():Void {
				state.loadData([], null, null);
			}, "loadData rejects an empty list");
			t.done();
		});

		add("AppState tracks what has been loaded", function(t:ngiotest.TestContext):Void {
			var state:io.newgrounds.AppState = self.freshAppState();
			var names:Array = io.newgrounds.AppState.dataProperties;

			for (var i:Number = 0; i < names.length; i++) {
				t.assertFalse(state.hasLoaded(names[i]), names[i] + " starts unloaded");
			}

			state.markLoaded("medals");
			t.assertTrue(state.hasLoaded("medals"), "medals marked as loaded");
			t.assertFalse(state.hasLoaded("scoreBoards"), "other properties unaffected");

			// Marking twice must not corrupt the list
			state.markLoaded("medals");
			t.assertTrue(state.hasLoaded("medals"), "still loaded after a duplicate mark");
			t.done();
		});

		add("AppState exposes the documented data properties", function(t:ngiotest.TestContext):Void {
			var expected:Array = ["gatewayVersion", "currentVersion", "hostApproved",
			                      "saveSlots", "scoreBoards", "medals", "medalScore"];
			var actual:Array = io.newgrounds.AppState.dataProperties;

			t.assertEquals(expected.length, actual.length, "property count");

			// An indexed search, not Array.indexOf - AVM1 does not have that
			// method, and reaching for it here is exactly the mistake this suite
			// found inside AppState itself.
			for (var i:Number = 0; i < expected.length; i++) {
				var found:Boolean = false;
				for (var j:Number = 0; j < actual.length; j++) {
					if (actual[j] === expected[i]) {
						found = true;
						break;
					}
				}
				t.assertTrue(found, expected[i] + " is a data property");
			}
			t.done();
		});

		add("AppState derives session status from session state", function(t:ngiotest.TestContext):Void {
			var state:io.newgrounds.AppState = self.freshAppState();
			var statuses = io.newgrounds.SessionStatus;

			state.session.id = null;
			t.assertEquals(statuses.UNINITIALIZED, state.getSessionStatus().status, "no session id");

			state.session.id = "sess-1";
			t.assertEquals(statuses.UNVERIFIED, state.getSessionStatus().status, "id but no passport url");

			state.session.passport_url = "https://example.com/passport";
			t.assertEquals(statuses.NOT_LOGGED_IN, state.getSessionStatus().status, "guest session");

			state.passportIsOpen = true;
			t.assertEquals(statuses.WAITING_FOR_PASSPORT, state.getSessionStatus().status, "passport open");

			state.session.user = new io.newgrounds.models.objects.User();
			var loggedIn:io.newgrounds.SessionStatus = state.getSessionStatus();
			t.assertEquals(statuses.LOGGED_IN, loggedIn.status, "user attached");
			t.assertNotNull(loggedIn.user, "status carries the user");
			t.done();
		});

		add("AppState reports an expired session as EXPIRED", function(t:ngiotest.TestContext):Void {
			var state:io.newgrounds.AppState = self.freshAppState();
			state.session.id = "sess-1";
			state.session.expired = true;

			t.assertEquals(io.newgrounds.SessionStatus.EXPIRED, state.getSessionStatus().status, "expired flag");
			t.done();
		});

		add("AppState maps session error codes to statuses", function(t:ngiotest.TestContext):Void {
			var errors = io.newgrounds.Errors;
			var statuses = io.newgrounds.SessionStatus;

			var expired:io.newgrounds.AppState = self.freshAppState();
			expired.session.id = "sess-1";
			expired.session.error = errors.getError(errors.EXPIRED_SESSION, null, false);
			t.assertEquals(statuses.EXPIRED, expired.getSessionStatus().status, "104 maps to EXPIRED");

			var cancelled:io.newgrounds.AppState = self.freshAppState();
			cancelled.session.id = "sess-1";
			cancelled.session.error = errors.getError(errors.CANCELLED_SESSION, null, false);
			t.assertEquals(statuses.LOGIN_CANCELLED, cancelled.getSessionStatus().status, "111 maps to LOGIN_CANCELLED");

			var other:io.newgrounds.AppState = self.freshAppState();
			other.session.id = "sess-1";
			other.session.error = errors.getError(errors.SERVER_ERROR, null, false);
			var status:io.newgrounds.SessionStatus = other.getSessionStatus();
			t.assertEquals(statuses.ERROR, status.status, "500 maps to ERROR");
			t.assertNotNull(status.error, "and carries the error through");
			t.done();
		});

		add("AppState reports a URL-supplied session id", function(t:ngiotest.TestContext):Void {
			var state:io.newgrounds.AppState = self.freshAppState();
			state.session.id = "from-url";
			state.session.preauthenticatedId = "from-url";

			t.assertEquals(io.newgrounds.SessionStatus.SESSION_ID_PROVIDED, state.getSessionStatus().status,
				"preauthenticated id is reported distinctly");
			t.done();
		});

		//==================== HTTP STATUS MAPPING ====================
		//
		// AS2 gets even less from the player than AS3 does: LoadVars.onData
		// receives a body or nothing at all, and CoreTransportHelper synthesises
		// 200 or 500 from that. HttpStatusHelper is ported anyway - it is what
		// lets AS2 report a real status the day one is available, and it keeps
		// both libraries answering the same question the same way. Read its
		// class comment before assuming AS2 knows more than it does.

		add("maps known HTTP statuses onto Errors codes", function(t:ngiotest.TestContext):Void {
			var statusHelper = io.newgrounds.helpers.HttpStatusHelper;
			var errors = io.newgrounds.Errors;

			t.assertEquals(errors.BAD_REQUEST, statusHelper.codeForStatus(400), "400");
			t.assertEquals(errors.USER_FORBIDDEN, statusHelper.codeForStatus(403), "403");
			t.assertEquals(errors.NOT_FOUND, statusHelper.codeForStatus(404), "404");
			t.assertEquals(errors.TOO_MANY_REQUESTS, statusHelper.codeForStatus(429), "429");
			t.assertEquals(errors.SERVER_ERROR, statusHelper.codeForStatus(500), "500");
			t.assertEquals(errors.SERVER_UNAVAILABLE, statusHelper.codeForStatus(503), "503");
			t.assertEquals(errors.GATEWAY_TIMEOUT, statusHelper.codeForStatus(504), "504");
			t.done();
		});

		add("falls back by status class for unlisted codes", function(t:ngiotest.TestContext):Void {
			// A 502 must still read as a server problem rather than an
			// unrecognised code with a useless message.
			var statusHelper = io.newgrounds.helpers.HttpStatusHelper;
			var errors = io.newgrounds.Errors;

			t.assertEquals(errors.SERVER_ERROR, statusHelper.codeForStatus(502), "502 is a server error");
			t.assertEquals(errors.SERVER_ERROR, statusHelper.codeForStatus(599), "599 is a server error");
			t.assertEquals(errors.BAD_REQUEST, statusHelper.codeForStatus(418), "418 is a bad request");
			t.assertEquals(errors.BAD_REQUEST, statusHelper.codeForStatus(451), "451 is a bad request");
			t.done();
		});

		add("treats an unreported status as an invalid response", function(t:ngiotest.TestContext):Void {
			// 0 is the COMMON case, and in AS2 very nearly the only case, since
			// LoadVars reports no status whatsoever. It must never be mistaken
			// for a real code.
			var statusHelper = io.newgrounds.helpers.HttpStatusHelper;

			t.assertEquals(io.newgrounds.Errors.INVALID_RESPONSE, statusHelper.codeForStatus(0),
				"no status reported");

			var described:String = statusHelper.describe(0, "The gateway request");
			t.assertTrue(described.indexOf("no HTTP status") >= 0,
				"and the message says so rather than inventing a code: " + described);
			t.done();
		});

		add("treats a 2xx with a bad body as an invalid response", function(t:ngiotest.TestContext):Void {
			// The case a status code cannot diagnose: the request succeeded and
			// the BODY was the problem. Only parsing catches it, so the message
			// has to point at the body rather than the transport.
			var statusHelper = io.newgrounds.helpers.HttpStatusHelper;

			t.assertEquals(io.newgrounds.Errors.INVALID_RESPONSE, statusHelper.codeForStatus(200),
				"200 reaching the mapper means the body failed");

			var described:String = statusHelper.describe(200, "The gateway request");
			t.assertTrue(described.indexOf("body") >= 0,
				"and the message blames the body: " + described);
			t.done();
		});

		add("builds an error carrying the status and any detail", function(t:ngiotest.TestContext):Void {
			var error = io.newgrounds.helpers.HttpStatusHelper.errorForStatus(503, "Loading scores", "Load failed");

			t.assertNotNull(error, "an error model is returned");
			t.assertEquals(io.newgrounds.Errors.SERVER_UNAVAILABLE, error.code, "carries the mapped code");
			t.assertTrue(String(error.message).indexOf("503") >= 0, "names the status");
			t.assertTrue(String(error.message).indexOf("Loading scores") >= 0, "names what failed");
			t.assertTrue(String(error.message).indexOf("Load failed") >= 0, "keeps the underlying detail");
			t.note(String(error.message));
			t.done();
		});
	}

	//==================== HELPERS ====================

	/**
	 * An AppState with a known-empty session.
	 *
	 * The AppState constructor restores any session id previously saved to local
	 * storage, so a run that had logged in would otherwise leak state into these
	 * offline assertions. Clearing the session here makes the suite independent
	 * of run order and of whatever is on disk.
	 *
	 * Public because the closures above reach it through `self`.
	 */
	public function freshAppState():io.newgrounds.AppState {
		var core:io.newgrounds.Core =
			new io.newgrounds.Core("unit-test:appstate", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

		var state:io.newgrounds.AppState = core.appState;

		state.session = new io.newgrounds.models.objects.Session();
		state.session.id = null;
		state.passportIsOpen = false;
		state.medals = null;
		state.scoreBoards = null;
		state.saveSlots = null;

		return state;
	}
}
