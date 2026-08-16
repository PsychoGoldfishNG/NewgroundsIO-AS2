/**
 * LiveGatewaySuite
 *
 * The first live suite to run. Everything here works for a guest, so if these
 * fail the problem is connectivity, app credentials or sandbox permissions -
 * not session handling. Worth reading first when a live run goes wrong.
 *
 * If EVERY test in this suite fails, check Publish Settings first: Local
 * playback security must be "Access network only". Set to "Access local files
 * only" - which is how the .fla ships - the player blocks every gateway request
 * from the IDE with no error a test can see.
 */
import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveGatewaySuite extends ngiotest.LiveSuite {

	public function LiveGatewaySuite() {
		super();
	}

	public function getSuiteName():String {
		return "Live / Gateway";
	}

	public function build():Void {

		// AS2 closures do not capture `this`, so every callback below reaches
		// the suite's helpers through `self`.
		var self:ngiotest.suites.LiveGatewaySuite = this;

		add("ping reaches the gateway", function(t:ngiotest.TestContext):Void {
			// If this one test fails and everything else in the live run fails
			// with it, treat it as "no route to the server" rather than chasing
			// individual components.
			NGIO.sendPing(function(pong:String, error):Void {
				if (self.assertNoError(t, error, "ping returned without error")) {
					t.assertEquals("pong", pong, "server answered pong");
				}
				t.done();
			}, null);
		});

		add("reports the gateway version", function(t:ngiotest.TestContext):Void {
			NGIO.loadGatewayVersion(function(version:String, error):Void {
				if (self.assertNoError(t, error, "gateway version loaded")) {
					if (t.assertNotNull(version, "version string present")) {
						t.assertTrue(version.length > 0, "version string is not empty");
						t.note("gateway version " + version);
					}
					t.assertEquals(version, NGIO.getGatewayVersion(), "cached on AppState");
				}
				t.done();
			}, null);
		});

		add("server time is close to local time", function(t:ngiotest.TestContext):Void {
			// A wildly wrong result here usually means the timestamp lost
			// precision somewhere, which then breaks anything comparing dates.
			NGIO.loadGatewayTimestamp(function(timestamp:Number, error):Void {
				if (self.assertNoError(t, error, "timestamp loaded")) {
					if (t.assertNotNull(timestamp, "timestamp present")) {
						var localSeconds:Number = new Date().getTime() / 1000;
						t.assertWithin(localSeconds, timestamp, 86400,
							"server timestamp is within a day of local time");
						t.note("server unix time " + timestamp);
					}
				}
				t.done();
			}, null);
		});

		add("returns an ISO 8601 datetime", function(t:ngiotest.TestContext):Void {
			NGIO.loadGatewayDateTime(function(datetime:String, error):Void {
				if (self.assertNoError(t, error, "datetime loaded")) {
					if (t.assertNotNull(datetime, "datetime present")) {
						// e.g. 2026-08-13T10:15:00+00:00
						t.assertTrue(datetime.length >= 19, "datetime is long enough to be ISO 8601");
						t.assertTrue(datetime.indexOf("T") == 10, "has a T separator at index 10");
						t.assertTrue(datetime.indexOf("-") == 4, "has a year-month separator at index 4");
						t.note("server datetime " + datetime);
					}
				}
				t.done();
			}, null);
		});

		add("converts server time to a Date", function(t:ngiotest.TestContext):Void {
			NGIO.loadGatewayDate(function(date:Date, error):Void {
				if (self.assertNoError(t, error, "date loaded")) {
					if (t.assertNotNull(date, "date present")) {
						t.assertIsType(date, Date, "is a Date instance");
						// getFullYear(), not the AS3 .fullYear property - AS2's
						// Date is the ECMAScript one, with no such accessor.
						t.assertTrue(date.getFullYear() >= 2024, "year is plausible, got " + date.getFullYear());
					}
				}
				t.done();
			}, null);
		});

		add("reports whether this host is approved", function(t:ngiotest.TestContext):Void {
			// The test app runs in viral mode with nothing blocked, so any host -
			// including the local IDE sandbox - should be approved.
			NGIO.loadHostApproved(function(approved:Boolean, error):Void {
				if (self.assertNoError(t, error, "host license loaded")) {
					t.assertTrue(approved, "host approved for a viral-mode app");
					t.assertEquals(approved, NGIO.getHostApproved(), "cached on AppState");
				}
				t.done();
			}, null);
		});

		add("reports the app version state", function(t:ngiotest.TestContext):Void {
			// The test app has version control switched off, so there is no
			// published version to be behind.
			NGIO.loadCurrentVersion(function(version:String, error):Void {
				if (self.assertNoError(t, error, "current version loaded")) {
					t.note("current version reported as " + version);
					t.assertFalse(NGIO.getClientDeprecated(),
						"client is not deprecated when version control is off");
				}
				t.done();
			}, null);
		});

		add("logs a custom event", function(t:ngiotest.TestContext):Void {
			// Asserts only that the call is ACCEPTED, and that is the ceiling
			// however well configured the app is: the gateway accepts undefined
			// event names silently BY DESIGN - legacy support for games still
			// sending names their config no longer defines - so a successful
			// response cannot distinguish a recorded event from a discarded one.
			//
			// TestConfig.CUSTOM_EVENT is confirmed against the project settings,
			// which is what makes the event actually land. The test just proves
			// the component round-tripped.
			NGIO.logEvent(ngiotest.TestConfig.CUSTOM_EVENT, function(error):Void {
				self.assertNoError(t, error, "logEvent('" + ngiotest.TestConfig.CUSTOM_EVENT + "')");
				t.done();
			}, null);
		});

		add("an event the app does not define is handled without throwing", function(t:ngiotest.TestContext):Void {
			// Confirmed with the API owner as deliberate: undefined event names
			// fail silently rather than erroring. Recorded as an observation,
			// not asserted either way - which side enforces the event list is a
			// server policy decision, not a client contract.
			NGIO.logEvent("definitely-not-a-real-event", function(error):Void {
				if (error == null) {
					t.note("gateway accepted an undefined event name without complaint (this is the documented behaviour)");
				} else {
					t.note("gateway rejected the undefined event: " + self.describeError(error));
				}
				t.assert(true, "undefined event name handled without throwing");
				t.done();
			}, null);
		});
	}
}
