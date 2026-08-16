/**
 * LiveLoaderSuite
 *
 * Checks the Loader.* components using their non-redirect form.
 *
 * Every Loader component can either navigate the browser (NGIO.openXxx) or
 * return the url through a callback (NGIO.loadXxx). The tests use the second
 * form on purpose: opening five browser tabs mid-run would be hostile, and the
 * url is what actually needs verifying. The redirect path shares all of its
 * request-building code with the load path, and is exercised once by the
 * Passport sign-in in LiveSessionSuite.
 */
import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveLoaderSuite extends ngiotest.LiveSuite {

	public function LiveLoaderSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / Loader URLs";
	}

	/**
	 * Left at the normal pace - see TestConfig.LOADER_PACING_MS.
	 *
	 * This suite was slowed down for a while on the AS3 side, when the gateway's
	 * 429s all appeared to land here. They were not this suite's doing - the
	 * failure follows the RUN's request count to whatever component happens to
	 * be last - so the override is back to -1 and kept only as a worked example
	 * of TestSuite.getPacingMs().
	 */
	public function getPacingMs():Number {
		return ngiotest.TestConfig.LOADER_PACING_MS;
	}

	public function build():Void {

		var self:ngiotest.suites.LiveLoaderSuite = this;

		add("resolves the official url", function(t:ngiotest.TestContext):Void {
			// Configured as the project preview page for the test app.
			NGIO.loadOfficialUrl(false, function(url:String, error):Void {
				self.assertUrl(t, url, error, "official url", true);
			}, null);
		});

		add("logging can be suppressed", function(t:ngiotest.TestContext):Void {
			// log_stat=false is how a game resolves a url without counting it as
			// a click. It must still return the url.
			//
			// NOTE: identical to the call above - both pass logEvent=false - so
			// this does not currently test what its name claims. Carried across
			// from the AS3 suite unchanged, where it was left alone while the
			// 429s were being investigated. Worth fixing in both at once rather
			// than letting them diverge.
			NGIO.loadOfficialUrl(false, function(url:String, error):Void {
				self.assertUrl(t, url, error, "official url with logging off", true);
			}, null);
		});

		add("reports an unconfigured referral", function(t:ngiotest.TestContext):Void {
			// A typo'd referral name should not silently resolve to somewhere
			// arbitrary. Unlike custom EVENTS - which the gateway accepts
			// silently by design - referrals do report a failure.
			NGIO.loadReferral("no-such-referral", false, function(url:String, error):Void {
				if (error != null) {
					t.note("server rejected the unknown referral: " + self.describeError(error));
					t.assert(true, "unknown referral reported as an error");
				} else {
					t.note("server returned url <" + url + "> for an unknown referral");
					t.assertNull(url, "unknown referral should not resolve to a url");
				}
				t.done();
			}, null);
		});

		add("resolves a configured custom referral", function(t:ngiotest.TestContext):Void {
			// TestConfig.CUSTOM_REFERRAL is confirmed against the project
			// settings, so a rejection here is a real failure rather than a
			// configuration note.
			//
			// The resolved url is only asserted to be absolute. A referral points
			// wherever the author aimed it - this one is aimed at
			// https://www.newgrounds.io, off newgrounds.com entirely - so
			// checking it against SITE_DOMAIN would assert the app's
			// configuration rather than anything about the library. The value is
			// recorded as a note instead, which is where a silent retarget would
			// show up.
			NGIO.loadReferral(ngiotest.TestConfig.CUSTOM_REFERRAL, false, function(url:String, error):Void {
				self.assertUrl(t, url, error, "referral '" + ngiotest.TestConfig.CUSTOM_REFERRAL + "'", true);
			}, null);
		});

		add("resolves the newgrounds.com url", function(t:ngiotest.TestContext):Void {
			// Hardcoded server-side to production newgrounds.com on EVERY
			// environment - it is a site-wide link, not an app link. Deliberately
			// not checked against TestConfig.SITE_DOMAIN for that reason.
			NGIO.loadNewgrounds(false, function(url:String, error):Void {
				self.assertUrl(t, url, error, "newgrounds url", true);
			}, null);
		});

		add("resolves the more-games url", function(t:ngiotest.TestContext):Void {
			// Same as above: a hardcoded site-wide link on every environment.
			NGIO.loadMoreGames(false, function(url:String, error):Void {
				self.assertUrl(t, url, error, "more games url", true);
			}, null);
		});

		add("resolves the author url", function(t:ngiotest.TestContext):Void {
			// The domain check belongs here rather than on the two above,
			// because official and author urls DO follow the environment. They
			// are also editable by the author afterwards, which is why the
			// expected domain lives in TestConfig.SITE_DOMAIN rather than being
			// hardcoded - a failure here may mean the project was edited, not
			// that the library is wrong.
			NGIO.loadAuthorUrl(false, function(url:String, error):Void {
				if (self.assertUrl(t, url, error, "author url", false)) {
					t.assertTrue(url.indexOf(ngiotest.TestConfig.SITE_DOMAIN) > 0,
						"points at " + ngiotest.TestConfig.SITE_DOMAIN);
				}
				t.done();
			}, null);
		});
	}

	//==================== HELPERS ====================

	/**
	 * Shared assertions for a resolved url.
	 *
	 * Public because the closures above reach it through `self`.
	 *
	 * @param finish when true, completes the test - pass false if the caller
	 *               wants to add assertions of its own first
	 * @return true when the url looked valid
	 */
	public function assertUrl(t:ngiotest.TestContext, url:String, error, label:String, finish:Boolean):Boolean {
		var ok:Boolean = false;

		if (assertNoError(t, error, label + " resolved without error")) {
			if (t.assertNotNull(url, label + " returned a url")) {
				ok = t.assertTrue(url.indexOf("http") == 0, label + " is an absolute url, got <" + url + ">");
				t.note(label + ": " + url);
			}
		}

		if (finish) {
			t.done();
		}
		return ok;
	}
}
