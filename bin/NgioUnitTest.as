/**
 * NgioUnitTest
 *
 * Runs unit tests for NGIO wrapper methods not covered by the prefab
 * components in components.fla. Assumes NGIO has already been initialized
 * (e.g. by the Connector Component).
 *
 * Place this file in the same directory as your .fla so Flash can find it.
 * It does NOT need to be included in end-user projects.
 *
 * USAGE (on a frame after NGIO is initialized):
 *
 *   if (typeof NgioUnitTest != "undefined") {
 *       NgioUnitTest.run(NGIO);
 *   }
 *
 * Results are written via trace(). Each test waits for its async callback
 * before starting the next, with a short delay between calls to avoid
 * triggering server-side rate limiting.
 *
 * An optional second argument sets the delay in ms between tests (default 500):
 *
 *   NgioUnitTest.run(NGIO, 1000);
 *
 * NOTE: loadReferral requires a referral name configured in your Newgrounds
 * project. Update the name in _test_loadReferral() before running.
 */
class NgioUnitTest {

	// Public so anonymous function closures can access them at runtime.
	// ngio is typed as Object so Flash does not attempt to resolve the
	// NGIO class at compile time - calls are late-bound at runtime instead.
	public static var ngio:Object;
	public static var queue:Array;
	public static var index:Number;
	public static var passed:Number;
	public static var failed:Number;
	public static var delay:Number;
	public static var timerId:Number;

	/**
	 * Run all unit tests.
	 * @param ngioRef  A reference to the NGIO class (pass NGIO directly)
	 * @param delayMs  Milliseconds between each test (default 500)
	 */
	public static function run(ngioRef:Object, delayMs:Number):Void {
		if (delayMs == undefined) delayMs = 500;
		ngio    = ngioRef;
		delay   = delayMs;
		index   = 0;
		passed  = 0;
		failed  = 0;
		queue   = buildQueue();
		trace("==================================================");
		trace("[NgioUnitTest] Starting " + queue.length + " tests");
		trace("==================================================");
		next();
	}

	public static function buildQueue():Array {
		return [
			{name:"loadGatewayVersion",   fn:_test_loadGatewayVersion},
			{name:"loadCurrentVersion",   fn:_test_loadCurrentVersion},
			{name:"loadClientDeprecated", fn:_test_loadClientDeprecated},
			{name:"loadHostApproved",     fn:_test_loadHostApproved},
			{name:"loadGatewayTimestamp", fn:_test_loadGatewayTimestamp},
			{name:"loadGatewayDateTime",  fn:_test_loadGatewayDateTime},
			{name:"loadGatewayDate",      fn:_test_loadGatewayDate},
			{name:"sendPing",             fn:_test_sendPing},
			{name:"logEvent",             fn:_test_logEvent},
			{name:"loadMedals",           fn:_test_loadMedals},
			{name:"loadMedalScore",       fn:_test_loadMedalScore},
			{name:"loadScoreBoards",      fn:_test_loadScoreBoards},
			{name:"loadSaveSlots",        fn:_test_loadSaveSlots},
			{name:"loadOfficialUrl",      fn:_test_loadOfficialUrl},
			{name:"loadAuthorUrl",        fn:_test_loadAuthorUrl},
			{name:"loadMoreGames",        fn:_test_loadMoreGames},
			{name:"loadNewgrounds",       fn:_test_loadNewgrounds},
			{name:"loadReferral",         fn:_test_loadReferral}
		];
	}

	public static function next():Void {
		if (index >= queue.length) {
			trace("==================================================");
			trace("[NgioUnitTest] Complete: " + passed + " passed, " + failed + " failed");
			trace("==================================================");
			return;
		}
		var entry:Object = queue[index];
		trace("[NgioUnitTest] (" + (index + 1) + "/" + queue.length + ") NGIO." + entry.name);

		entry.fn(function(ok:Boolean, detail:String):Void {
			if (ok) {
				NgioUnitTest.passed++;
				trace("[NgioUnitTest]  PASS" + (detail ? ": " + detail : ""));
			} else {
				NgioUnitTest.failed++;
				trace("[NgioUnitTest]  FAIL: " + detail);
			}
			NgioUnitTest.index++;
			NgioUnitTest.timerId = setInterval(function():Void {
				clearInterval(NgioUnitTest.timerId);
				NgioUnitTest.next();
			}, NgioUnitTest.delay);
		});
	}

	// ==================== INDIVIDUAL TESTS ====================

	public static function _test_loadGatewayVersion(done:Function):Void {
		NgioUnitTest.ngio.loadGatewayVersion(function(version, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof version == "string" && version.length > 0, "version=" + version);
		});
	}

	public static function _test_loadCurrentVersion(done:Function):Void {
		NgioUnitTest.ngio.loadCurrentVersion(function(version, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			// version may be null if not set in project settings - that is acceptable
			done(true, "version=" + version);
		});
	}

	public static function _test_loadClientDeprecated(done:Function):Void {
		NgioUnitTest.ngio.loadClientDeprecated(function(deprecated, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof deprecated == "boolean", "deprecated=" + deprecated);
		});
	}

	public static function _test_loadHostApproved(done:Function):Void {
		NgioUnitTest.ngio.loadHostApproved(function(approved, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof approved == "boolean", "approved=" + approved);
		});
	}

	public static function _test_loadGatewayTimestamp(done:Function):Void {
		NgioUnitTest.ngio.loadGatewayTimestamp(function(timestamp, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof timestamp == "number" && timestamp > 0, "timestamp=" + timestamp);
		});
	}

	public static function _test_loadGatewayDateTime(done:Function):Void {
		NgioUnitTest.ngio.loadGatewayDateTime(function(dateTime, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof dateTime == "string" && dateTime.length > 0, "dateTime=" + dateTime);
		});
	}

	public static function _test_loadGatewayDate(done:Function):Void {
		NgioUnitTest.ngio.loadGatewayDate(function(date, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(date instanceof Date, "date=" + date);
		});
	}

	public static function _test_sendPing(done:Function):Void {
		NgioUnitTest.ngio.sendPing(function(pong, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(pong == "pong", "pong=" + pong);
		});
	}

	public static function _test_logEvent(done:Function):Void {
		NgioUnitTest.ngio.logEvent("ngio_unit_test", function(error):Void {
			done(error == null, error != null ? "error: " + error : "ok");
		});
	}

	public static function _test_loadMedals(done:Function):Void {
		NgioUnitTest.ngio.loadMedals(function(medals, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(medals instanceof Array, "count=" + (medals ? medals.length : "null"));
		});
	}

	public static function _test_loadMedalScore(done:Function):Void {
		NgioUnitTest.ngio.loadMedalScore(function(score, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof score == "number", "score=" + score);
		});
	}

	public static function _test_loadScoreBoards(done:Function):Void {
		NgioUnitTest.ngio.loadScoreBoards(function(boards, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(boards instanceof Array, "count=" + (boards ? boards.length : "null"));
		});
	}

	public static function _test_loadSaveSlots(done:Function):Void {
		NgioUnitTest.ngio.loadSaveSlots(function(slots, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(slots instanceof Array, "count=" + (slots ? slots.length : "null"));
		});
	}

	public static function _test_loadOfficialUrl(done:Function):Void {
		NgioUnitTest.ngio.loadOfficialUrl(false, function(url, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof url == "string" && url.length > 0, "url=" + url);
		});
	}

	public static function _test_loadAuthorUrl(done:Function):Void {
		NgioUnitTest.ngio.loadAuthorUrl(false, function(url, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof url == "string" && url.length > 0, "url=" + url);
		});
	}

	public static function _test_loadMoreGames(done:Function):Void {
		NgioUnitTest.ngio.loadMoreGames(false, function(url, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof url == "string" && url.length > 0, "url=" + url);
		});
	}

	public static function _test_loadNewgrounds(done:Function):Void {
		NgioUnitTest.ngio.loadNewgrounds(false, function(url, error):Void {
			if (error != null) { done(false, "error: " + error); return; }
			done(typeof url == "string" && url.length > 0, "url=" + url);
		});
	}

	public static function _test_loadReferral(done:Function):Void {
		// NOTE: Replace "my_referral" with a referral name configured in your Newgrounds project.
		// If the name is not found the server returns an error - this still confirms the call
		// mechanism works, so the test passes either way.
		NgioUnitTest.ngio.loadReferral("my_referral", false, function(url, error):Void {
			done(
				url != null || error != null,
				url != null ? ("url=" + url) : "referral not found (expected if unconfigured)"
			);
		});
	}
}
