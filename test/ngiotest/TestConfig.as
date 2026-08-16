/**
 * TestConfig
 *
 * Every knob the test suite exposes, in one place.
 *
 * The app credentials below belong to the unpublished "Newgrounds.io AS2 test"
 * project, which exists purely for this suite. They are safe to keep in the
 * repo. Do NOT replace them with credentials for a published game: the live
 * suite posts scores, unlocks medals and writes cloud saves.
 *
 * ActionScript 2 has no `const`, so these are `static var` by necessity. Treat
 * them as constants - nothing in the suite writes to them.
 */
import io.newgrounds.Core;

class ngiotest.TestConfig {

	//==================== APP CREDENTIALS ====================

	/** "Newgrounds.io AS2 test" - unpublished, safe to commit */
	public static var APP_ID:String = "59735:NNSlBwZV";

	/**
	 * RC4 key for the app above, Base64-encoded.
	 *
	 * NOT AES. The AS2 library encrypts with io.newgrounds.encoders.RC4, which
	 * takes this Base64 string as-is and decodes it internally. RC4 is
	 * symmetric, so the same call decrypts - which is what OfflineCryptoSuite
	 * and NetworkLog both rely on.
	 */
	public static var ENCRYPTION_KEY:String = "UtKQ/4YaJ9qxl/0k1qPjMQ==";

	/**
	 * The test app has version control switched off, so there is no "current
	 * version" to compare against and clientDeprecated should come back false.
	 */
	public static var BUILD_VERSION:String = null;

	//==================== RUN CONTROL ====================

	/** Offline suites need no network and no login */
	public static var RUN_OFFLINE_TESTS:Boolean = true;

	/** Live suites talk to the real gateway */
	public static var RUN_LIVE_TESTS:Boolean = true;

	/**
	 * Debug mode tells the gateway to validate and reply normally without
	 * committing anything. That is what makes medal-unlock and score-post
	 * tests repeatable: nothing has to be re-locked between runs.
	 *
	 * Set false only when deliberately verifying that writes persist, and
	 * expect to re-lock the medal on the server afterwards.
	 */
	public static var USE_DEBUG_MODE:Boolean = true;

	/**
	 * When true, the live run pauses and asks the user to sign in through
	 * Passport. Set false to run only the tests that work for a guest;
	 * everything needing a user then reports as skipped.
	 */
	public static var REQUIRE_LOGIN:Boolean = true;

	/**
	 * When true, the runner asks for a click before starting the live
	 * suites, so the offline results can be read first (or live skipped).
	 */
	public static var CONFIRM_BEFORE_LIVE:Boolean = true;

	//==================== APP CONTENT ====================

	/**
	 * The custom event configured on the AS2 test app.
	 * CONFIRMED against the project settings, 2026-08-15.
	 *
	 * Note what a passing test can and cannot prove here. Undefined event names
	 * fail SILENTLY on the gateway by design - legacy support for games still
	 * sending names their config no longer defines - so a WRONG name would
	 * produce a successful response too. The test shows the component
	 * round-tripped; it is this constant being right that makes the event
	 * actually get recorded.
	 */
	public static var CUSTOM_EVENT:String = "ngio_unit_test";

	/**
	 * The custom referral configured on the AS2 test app.
	 * CONFIRMED 2026-08-15; it is aimed at https://www.newgrounds.io
	 *
	 * Unlike events, a bad referral name IS reported - Loader.loadReferral
	 * returns an error rather than a url - so LiveLoaderSuite asserts this one
	 * properly rather than treating a rejection as a configuration note.
	 *
	 * Its target is deliberately NOT checked against SITE_DOMAIN. A referral
	 * points wherever the author aimed it, and this one is aimed off
	 * newgrounds.com entirely.
	 */
	public static var CUSTOM_REFERRAL:String = "my_referral";

	/**
	 * The domain the test app's official and author urls are expected to use.
	 *
	 * This is an assumption about THIS APP's configuration, not a rule of the
	 * API. Those two urls are generated when a project is created, using the
	 * values of whichever environment created it, and an author can edit them
	 * afterwards to point anywhere at all. Change this if the test app's urls
	 * are ever customised, and change it alongside Core.GATEWAY_URL when
	 * testing against a different environment.
	 *
	 * Deliberately not applied to loadMoreGames or loadNewgrounds: those are
	 * hardcoded server-side to production newgrounds.com by design, on every
	 * environment.
	 */
	public static var SITE_DOMAIN:String = "newgrounds.com";

	/**
	 * Medals configured on the test app.
	 *
	 * THREE as of 2026-08-15, matching the AS3 test app. It had one until then,
	 * which was a real coverage limit: with a single medal there is no locked
	 * medal to leave alone, so "unlocking one medal does not unlock another"
	 * could not be told apart from "unlock did nothing at all".
	 *
	 * LiveMedalSuite still guards that case on this constant, so it skips itself
	 * with a reason rather than failing if the app is ever reduced again.
	 */
	public static var EXPECTED_MEDAL_COUNT:Number = 3;

	/** Scoreboards configured on the test app (one standard, one incremental) */
	public static var EXPECTED_SCOREBOARD_COUNT:Number = 2;

	/** Cloud save slots configured on the test app */
	public static var EXPECTED_SAVE_SLOT_COUNT:Number = 10;

	/** Save slot the CloudSave suite writes raw text to */
	public static var TEST_SAVE_SLOT_ID:Number = 1;

	/**
	 * A second scratch slot, used by the structured round-trip test.
	 *
	 * It needs its own slot rather than reusing the one above. The save-data
	 * url the gateway returns is cache-busted only to the second
	 * (...sav?1786656297), so two writes to the same slot inside one second
	 * produce byte-identical urls - and the player then serves the first body
	 * from cache for the second read. That made the round-trip test fail
	 * against the *previous* test's payload on the AS3 suite. Separate slots
	 * mean separate filenames, so the tests cannot alias each other.
	 */
	public static var TEST_SAVE_SLOT_ID_ALT:Number = 2;

	//==================== FAILURE DIAGNOSTICS ====================

	/**
	 * When true, a failing test prints the raw JSON exchanged with the gateway
	 * during that test. Passing tests never print traffic, so the report stays
	 * readable.
	 *
	 * Encrypted `secure` payloads are decrypted for display using
	 * ENCRYPTION_KEY, so a failed medal unlock shows what the server actually
	 * received.
	 */
	public static var CAPTURE_PACKETS_ON_FAILURE:Boolean = true;

	/**
	 * Trace every packet as it happens, pass or fail, via
	 * Core.debugNetworkCalls. Noisy and interleaved with test output - for when
	 * a failure is not reproducing and you want the full picture.
	 */
	public static var TRACE_ALL_PACKETS:Boolean = false;

	/** Indent captured JSON. Off gives compact one-line packets. */
	public static var PRETTY_PRINT_PACKETS:Boolean = true;

	/** Cap on how much of a single packet is printed. 0 means no limit. */
	public static var MAX_CAPTURED_PACKET_CHARS:Number = 4000;

	/** How many packets to retain per test before dropping older ones */
	public static var MAX_CAPTURED_PACKETS:Number = 12;

	//==================== CROSS-APP ACCESS ====================

	/**
	 * "Newgrounds.IO test" - a separate app that has granted this one read-only
	 * access via the app_id parameter on Medal.getList, ScoreBoard.getScores,
	 * CloudSave.loadSlot and CloudSave.loadSlots.
	 *
	 * Used to prove two things: that cross-app reads work, and - more
	 * importantly - that the data they return never lands in this app's
	 * AppState caches.
	 */
	public static var READABLE_FOREIGN_APP_ID:String = "39685:NJ1KkPGb";

	/**
	 * A scoreboard belonging to READABLE_FOREIGN_APP_ID.
	 *
	 * It has to be hardcoded: ScoreBoard.getBoards does not accept an app_id,
	 * so there is no supported way to discover another app's board ids at
	 * runtime. This is the board the AS3 suite reads.
	 */
	public static var READABLE_FOREIGN_SCOREBOARD_ID:Number = 5853;

	/**
	 * An app that has NOT granted this one access, so a read should be refused.
	 *
	 * The AS3 test app: 05-information-for-testing.md records that neither test
	 * app shares with the other.
	 */
	public static var UNREADABLE_FOREIGN_APP_ID:String = "61512:1uYiEl7d";

	//==================== CLAMPING PROBE ====================

	/**
	 * Whether the gateway under test clamps score limits into 1-100.
	 *
	 * FALSE for production as of 2026-08-14: it passes `limit` through
	 * unchanged, and `limit: 0` returns an empty list rather than one score.
	 * The clamp exists on the development branch and has not shipped.
	 *
	 * When false the three clamp probes still RUN and still report exactly what
	 * the server did - they just record it as a note instead of failing, so an
	 * unshipped feature does not sit as a permanent red mark. Flip it to true
	 * once the clamp deploys, and they become assertions again.
	 *
	 * Worth flipping deliberately rather than deleting the tests: the rule the
	 * library enforces (reject a limit outside 1-100) is written against the
	 * clamped behaviour, so it is worth knowing the day it changes.
	 */
	public static var SERVER_CLAMPS_SCORE_LIMIT:Boolean = false;

	/**
	 * An app and board known to hold well over 100 scores, read cross-app.
	 *
	 * The clamp tests prove the LIMIT was honoured from the result's echo on
	 * any board. Proving the server actually stopped at 100 ROWS needs a board
	 * with more than 100 rows in it - "at most 100" is satisfied trivially by a
	 * board holding two.
	 *
	 * EMPTY BY DEFAULT, deliberately. With no board configured the tests fall
	 * back to a local one, check the echo, and say in their note that the row
	 * cap is unproven - so a green run never claims more than it verified.
	 * Setting this to a board that turns out to hold FEWER than 100 rows would
	 * fail the run for a reason that has nothing to do with the library.
	 */
	public static var SCORE_RICH_APP_ID:String = "";

	/** A board on SCORE_RICH_APP_ID holding more than 100 scores */
	public static var SCORE_RICH_BOARD_ID:Number = 0;

	//==================== TIMING ====================

	/**
	 * Pause between LIVE test cases, in milliseconds. 0 disables pacing.
	 *
	 * 750ms is a TEMPORARY measure, set at the gateway owner's direction to keep
	 * a full run inside the current allowance until the server-side limit is
	 * updated. Drop it back to 100 once that ships.
	 *
	 * It works because the limit is a count per TIME WINDOW: at roughly one
	 * request per case, spacing the cases out spreads a ~70-request run across
	 * enough seconds that it no longer piles into one window.
	 *
	 * What is actually known, since this is a knob worth tuning from evidence
	 * rather than feel:
	 *
	 *   100ms   ~60 requests in ~25s   REFUSED on request 60   (2026-08-15)
	 *   1200ms  71 requests, no refusal                        (2026-08-16)
	 *   750ms   untested when set
	 *
	 * Lowering it is low-risk to try: since the run now stops itself at the
	 * first dead request, guessing too low costs a short burst of honest skips
	 * rather than a cascade of failures and false passes. See LiveSuite.
	 *
	 * This does NOT contradict the earlier finding that pacing the Loader suite
	 * alone changed nothing - see LOADER_PACING_MS. Slowing the last suite leaves
	 * the fifty-odd requests before it just as dense, so the window is already
	 * spent by the time the pacing starts. Only pacing the WHOLE run moves
	 * requests between windows.
	 *
	 * Two honest limits on it:
	 *
	 *  - It paces CASES, not calls. A test that makes three gateway calls still
	 *    bursts them. It happens to work out at close to one call per case here,
	 *    which is why per-case pacing is a good enough approximation.
	 *  - It paces EVERY live case, including ones that skip or make no request at
	 *    all - roughly a sixth of them. That is wasted time rather than protection;
	 *    pacing only after a case that actually hit the network would cost less
	 *    for the same request density.
	 *  - It dominates the run. At 1200ms the pacing alone was ~102s of a ~120s
	 *    suite; the actual work is closer to 20s. 750ms brings the pacing to ~64s.
	 *
	 * Offline suites are never paced - they make no requests, and slowing them
	 * would only make the suite feel broken.
	 */
	public static var LIVE_TEST_PACING_MS:Number = 1200;

	/**
	 * Pause before each Loader.* case specifically. -1 uses the value above.
	 *
	 * -1 because the Loader suite turned out not to be special. It was slowed
	 * to 2000 on the AS3 side while the 429s all appeared to land there; moving
	 * the suite earlier in the run showed those failures follow the RUN's
	 * request count, not the component.
	 *
	 * Worth being precise about WHY that failed, because pacing the whole run
	 * does work (see LIVE_TEST_PACING_MS). Slowing only the last suite leaves
	 * every request before it just as tightly packed, so the window is already
	 * spent before the pacing begins. The lesson was that pacing has to apply to
	 * the whole run, not that pacing is useless.
	 *
	 * Left in place rather than deleted: TestSuite.pacingMs is a reasonable
	 * thing to have, and this is the obvious worked example of using it.
	 */
	public static var LOADER_PACING_MS:Number = -1;

	/** Default watchdog for a single test */
	public static var TEST_TIMEOUT_MS:Number = 20000;

	/** Watchdog for tests that wait on a human (Passport sign-in, live gate) */
	public static var INTERACTIVE_TIMEOUT_MS:Number = 300000;

	/** How often to re-check the session while waiting for Passport */
	public static var SESSION_POLL_INTERVAL_MS:Number = 4000;

	/**
	 * How long to wait before a checkSession that MUST reach the server.
	 *
	 * NgioAuthHelper throttles checkSession to one server call every
	 * CHECKSESSION_THROTTLE_TIME (3) seconds. Inside that window it answers
	 * locally with a synthetic status and does NOT start a new session, so a
	 * test that needs a genuine round trip has to wait the throttle out first.
	 *
	 * Comfortably above 3000 rather than exactly 3000: the throttle compares
	 * wall-clock times, and landing on the boundary would make the test a coin
	 * flip. SESSION_POLL_INTERVAL_MS is 4000 for the same reason.
	 */
	public static var SESSION_THROTTLE_WAIT_MS:Number = 4000;

	//==================== DEVELOPMENT GATEWAY ====================

	/**
	 * Point the library at a different gateway before anything is initialised.
	 *
	 * Unlike AS3, where Core.GATEWAY_URL is a const and has to be edited in the
	 * library source, the AS2 one is a plain static var - so a development host
	 * can be selected from here at runtime and reverted by deleting one line.
	 *
	 * NO DEVELOPMENT HOSTNAME IS COMMITTED. Uncomment and fill in the
	 * assignment below when you need one, and take it back out before
	 * committing. The runner prints whichever gateway is in force in its
	 * header, so a report always records the server that produced it.
	 *
	 * Remember the app credentials have to change with the host - the
	 * development environment has its own database and its own app ids. See
	 * AUDIT/05-information-for-testing.md.
	 */
	public static function applyGatewayOverride():Void {
		// io.newgrounds.Core.GATEWAY_URL = "https://DEV-HOST/gateway_v3.php";
		// io.newgrounds.Core.POLICY_FILE_URL = "https://DEV-HOST/crossdomain.xml";
	}

	//==================== DERIVED ====================

	/**
	 * The gateway the library will actually use. Read from Core rather than
	 * duplicated, so an override above shows up in the report instead of
	 * silently changing what the suite exercised.
	 */
	public static function gatewayUrl():String {
		return io.newgrounds.Core.GATEWAY_URL;
	}
}
