/**
 * OfflineWireFormatSuite
 *
 * Builds the exact JSON envelope Core would put on the wire, and reads back
 * canned server replies through the exact path Core uses - without opening a
 * socket.
 *
 * This is where a protocol regression is cheapest to catch. A live test that
 * fails here tells you "the server said no"; this suite tells you which field
 * was wrong. Per line of code it is the best value in the suite.
 */
import io.newgrounds.BaseComponent;
import io.newgrounds.Core;
import io.newgrounds.Errors;
import io.newgrounds.encoders.JSON;
import io.newgrounds.encoders.RC4;
import io.newgrounds.helpers.HttpRequestHelper;
import io.newgrounds.helpers.HttpResponseHelper;
import io.newgrounds.models.objects.Execute;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.objects.Request;
import io.newgrounds.models.objects.Response;
import io.newgrounds.models.objects.SaveSlot;

import ngiotest.TestConfig;
import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineWireFormatSuite extends ngiotest.TestSuite {

	private var core:io.newgrounds.Core;

	public function OfflineWireFormatSuite() {
		super();
		this.core = null;
	}

	public function getSuiteName():String {
		return "Offline / Wire format";
	}

	public function setUp(done:Function):Void {
		core = new io.newgrounds.Core("unit-test:wire", ngiotest.TestConfig.ENCRYPTION_KEY, "1.2.3", true);
		done.call(null);
	}

	public function build():Void {

		var self:ngiotest.suites.OfflineWireFormatSuite = this;

		//==================== OUTGOING ====================

		add("request envelope carries app_id, debug and execute", function(t:ngiotest.TestContext):Void {
			var envelope:Object = self.buildEnvelope(self.makeExecute("Gateway", "ping", null, null), null);

			t.assertEquals("unit-test:wire", envelope.app_id, "app_id");
			t.assertStrictEquals(true, envelope.debug, "debug flag set from Core");
			t.assertNotNull(envelope.execute, "execute present");
			t.assertFalse(envelope.hasOwnProperty("session_id"), "no session_id when there is no session");
			t.done();
		});

		add("request envelope omits debug when it is off", function(t:ngiotest.TestContext):Void {
			// The gateway treats the PRESENCE of "debug" as the switch, so a
			// literal `debug: false` would still put the app in debug mode.
			var liveCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:live", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var request:io.newgrounds.models.objects.Request = new io.newgrounds.models.objects.Request();
			request.core = liveCore;
			request.app_id = liveCore.appId;
			request.debug = liveCore.useDebugMode;
			request.setExecute(self.makeExecute("Gateway", "ping", null, liveCore));

			var envelope:Object = io.newgrounds.helpers.HttpRequestHelper.buildGatewayRequestObject(request);
			t.assertFalse(envelope.hasOwnProperty("debug"), "debug key absent entirely");
			t.done();
		});

		add("request envelope includes session_id when present", function(t:ngiotest.TestContext):Void {
			var envelope:Object = self.buildEnvelope(self.makeExecute("Gateway", "ping", null, null), "session-xyz");
			t.assertEquals("session-xyz", envelope.session_id, "session_id passed through");
			t.done();
		});

		add("a plain component serializes as component + parameters", function(t:ngiotest.TestContext):Void {
			var envelope:Object = self.buildEnvelope(
				self.makeExecute("ScoreBoard", "getScores", { id: 6510, limit: 10, period: "D" }, null), null);

			var execute:Object = envelope.execute;
			t.assertEquals("ScoreBoard.getScores", execute.component, "component path");
			t.assertNotNull(execute.parameters, "parameters present");
			t.assertEquals(6510, execute.parameters.id, "id parameter");
			t.assertEquals(10, execute.parameters.limit, "limit parameter");
			t.assertEquals("D", execute.parameters.period, "period parameter");
			t.assertFalse(execute.hasOwnProperty("secure"), "not encrypted");
			t.done();
		});

		add("omitted component parameters are dropped, not sent as null", function(t:ngiotest.TestContext):Void {
			// ScoreBoard.getScores declares eight properties. Only the three
			// supplied above should reach the wire - sending `"tag": null` or
			// `"app_id": null` would have the gateway filter on a null tag, or
			// read the request as a cross-app lookup of app "null".
			//
			// It works because prepareForJson() is toObject(true, true), and the
			// true for excludeNulls is what drops them.
			var execute:Object = self.buildEnvelope(
				self.makeExecute("ScoreBoard", "getScores", { id: 6510, limit: 10, period: "D" }, null), null).execute;

			t.assertFalse(execute.parameters.hasOwnProperty("tag"), "tag omitted");
			t.assertFalse(execute.parameters.hasOwnProperty("app_id"), "app_id omitted");
			t.assertFalse(execute.parameters.hasOwnProperty("user"), "user omitted");
			t.assertFalse(execute.parameters.hasOwnProperty("social"), "social omitted");
			t.done();
		});

		add("a secure component serializes as an encrypted blob only", function(t:ngiotest.TestContext):Void {
			// Medal.unlock is flagged isSecure. The envelope must expose only
			// {secure: "..."} - leaking the plain component alongside it would
			// defeat the encryption entirely.
			var envelope:Object = self.buildEnvelope(self.makeExecute("Medal", "unlock", { id: 4242 }, null), "session-xyz");
			var execute:Object = envelope.execute;

			t.assertTrue(execute.hasOwnProperty("secure"), "secure key present");
			t.assertFalse(execute.hasOwnProperty("component"), "component name not leaked");
			t.assertFalse(execute.hasOwnProperty("parameters"), "parameters not leaked");

			var inner:Object = io.newgrounds.encoders.JSON.decode(self.decrypt(execute.secure));
			t.assertEquals("Medal.unlock", inner.component, "encrypted component path");
			t.assertEquals(4242, inner.parameters.id, "encrypted parameter");
			t.done();
		});

		add("a queue of components serializes as an execute array", function(t:ngiotest.TestContext):Void {
			var request:io.newgrounds.models.objects.Request = new io.newgrounds.models.objects.Request();
			request.core = self.core;
			request.app_id = self.core.appId;
			request.setExecuteList([
				self.makeExecute("Gateway", "ping", null, null),
				self.makeExecute("Medal", "getList", null, null),
				self.makeExecute("ScoreBoard", "getBoards", null, null)
			]);

			var envelope:Object = io.newgrounds.helpers.HttpRequestHelper.buildGatewayRequestObject(request);
			var executeArray:Array = envelope.execute;

			if (!t.assertNotNull(executeArray, "execute is an array")) {
				t.done();
				return;
			}

			t.assertEquals(3, executeArray.length, "all three components present");
			t.assertEquals("Gateway.ping", executeArray[0].component, "first component");
			t.assertEquals("Medal.getList", executeArray[1].component, "second component");
			t.assertEquals("ScoreBoard.getBoards", executeArray[2].component, "third component");
			t.done();
		});

		add("a mixed queue encrypts only the secure entries", function(t:ngiotest.TestContext):Void {
			var request:io.newgrounds.models.objects.Request = new io.newgrounds.models.objects.Request();
			request.core = self.core;
			request.app_id = self.core.appId;
			request.setExecuteList([
				self.makeExecute("Gateway", "ping", null, null),
				self.makeExecute("Medal", "unlock", { id: 1 }, null)
			]);

			var executeArray:Array = io.newgrounds.helpers.HttpRequestHelper.buildGatewayRequestObject(request).execute;

			t.assertEquals("Gateway.ping", executeArray[0].component, "plain entry stays plain");
			t.assertTrue(executeArray[1].hasOwnProperty("secure"), "secure entry is encrypted");
			t.done();
		});

		add("the whole envelope survives JSON encoding", function(t:ngiotest.TestContext):Void {
			var envelope:Object = self.buildEnvelope(self.makeExecute("Medal", "unlock", { id: 7 }, null), "session-xyz");
			var json:String = io.newgrounds.encoders.JSON.encode(envelope, false);
			var reparsed:Object = io.newgrounds.encoders.JSON.decode(json);

			t.assertEquals("unit-test:wire", reparsed.app_id, "app_id survived");
			t.assertEquals("session-xyz", reparsed.session_id, "session_id survived");
			t.assertTrue(reparsed.execute.hasOwnProperty("secure"), "secure blob survived");

			var inner:Object = io.newgrounds.encoders.JSON.decode(self.decrypt(reparsed.execute.secure));
			t.assertEquals(7, inner.parameters.id, "and still decrypts after the JSON round-trip");
			t.done();
		});

		add("the encrypted blob is Base64-safe inside JSON", function(t:ngiotest.TestContext):Void {
			// AS2-specific. RC4 output goes through the library's own Base64,
			// whose alphabet includes '+' and '/' - both harmless in JSON - but
			// the encoder that wraps it escapes everything outside printable
			// ASCII. If a stray high byte ever reached the string, it would be
			// escaped to \uXXXX and the server's base64_decode would fail with
			// error 201 rather than anything that names the real cause.
			var envelope:Object = self.buildEnvelope(self.makeExecute("Medal", "unlock", { id: 7 }, null), null);
			var blob:String = String(envelope.execute.secure);

			var json:String = io.newgrounds.encoders.JSON.encode(envelope, false);
			t.assertEquals(-1, json.indexOf("\\u"), "no character in the envelope needed a unicode escape");
			t.assertTrue(json.indexOf(blob) >= 0, "the blob appears verbatim in the JSON");
			t.done();
		});

		add("Execute rejects having both component and secure", function(t:ngiotest.TestContext):Void {
			var execute:io.newgrounds.models.objects.Execute = new io.newgrounds.models.objects.Execute();
			t.assertFalse(execute.hasValidProperties(), "neither set is invalid");

			execute.component = "Medal.unlock";
			t.assertTrue(execute.hasValidProperties(), "component alone is valid");

			execute.secure = "abc";
			t.assertFalse(execute.hasValidProperties(), "both set is invalid");

			execute.component = null;
			t.assertTrue(execute.hasValidProperties(), "secure alone is valid");
			t.done();
		});

		//==================== INCOMING ====================

		add("parses a single-result response into a typed result", function(t:ngiotest.TestContext):Void {
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"app_id":"unit-test:wire","success":true,' +
				'"result":{"component":"Gateway.ping","data":{"success":true,"pong":"pong"}}}'
			);

			t.assertTrue(response.success, "response success");
			t.assertFalse(response.resultIsList(), "single result, not a list");

			var result = response.getResult();
			if (t.assertNotNull(result, "result created")) {
				t.assertEquals("Gateway.ping", result.objectName, "typed as Gateway.ping");
				t.assertTrue(result.success, "result success");
			}
			t.done();
		});

		add("parses a multi-result response into a list", function(t:ngiotest.TestContext):Void {
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"app_id":"unit-test:wire","success":true,"result":[' +
				'{"component":"Gateway.ping","data":{"success":true}},' +
				'{"component":"Medal.getList","data":{"success":true,"medals":[{"id":1,"name":"A","value":5}]}}' +
				']}'
			);

			t.assertTrue(response.resultIsList(), "reports a list");

			var results:Array = response.getResultList();
			if (!t.assertNotNull(results, "result list created")) {
				t.done();
				return;
			}

			t.assertEquals(2, results.length, "both results present");
			t.assertEquals("Gateway.ping", results[0].objectName, "first is Gateway.ping");
			t.assertEquals("Medal.getList", results[1].objectName, "second is Medal.getList");

			var medals:Array = results[1].medals;
			if (t.assertNotNull(medals, "nested medals parsed")) {
				t.assertEquals(1, medals.length, "one medal");
				t.assertIsType(medals[0], io.newgrounds.models.objects.Medal, "medal is typed");
				t.assertEquals("A", medals[0].name, "medal name");
			}
			t.done();
		});

		add("parses nested objects inside a result", function(t:ngiotest.TestContext):Void {
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"success":true,"result":{"component":"App.checkSession","data":{"success":true,' +
				'"session":{"id":"sess-1","expired":false,"user":{"id":42,"name":"Tester","supporter":true}}}}}'
			);

			var result = response.getResult();
			if (!t.assertNotNull(result, "result created")) {
				t.done();
				return;
			}

			var session = result.session;
			if (t.assertNotNull(session, "session parsed")) {
				t.assertEquals("sess-1", session.id, "session id");
				if (t.assertNotNull(session.user, "user parsed")) {
					t.assertEquals(42, session.user.id, "user id");
					t.assertEquals("Tester", session.user.name, "user name");
					t.assertTrue(session.user.supporter, "supporter flag");
				}
			}
			t.done();
		});

		add("parses an array-of-SaveSlot result", function(t:ngiotest.TestContext):Void {
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"success":true,"result":{"component":"CloudSave.loadSlots","data":{"success":true,"slots":[' +
				'{"id":1,"size":128,"datetime":"2026-01-01T00:00:00+00:00","timestamp":1767225600,"url":"//example.com/1"},' +
				'{"id":2,"size":0}' +
				']}}}'
			);

			var slots:Array = response.getResult().slots;
			if (!t.assertNotNull(slots, "slots parsed")) {
				t.done();
				return;
			}

			t.assertEquals(2, slots.length, "two slots");
			t.assertIsType(slots[0], io.newgrounds.models.objects.SaveSlot, "slot is typed");
			t.assertEquals(128, slots[0].size, "slot size");
			t.assertTrue(slots[0].hasData(), "slot with a url has data");
			t.assertFalse(slots[1].hasData(), "slot without a url has no data");
			t.done();
		});

		add("propagates a response-level error onto the result", function(t:ngiotest.TestContext):Void {
			// A request-level failure has no per-result error, but callers check
			// result.error. Without propagation they see a null error on a
			// failed call and report success.
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"success":false,"error":{"message":"Invalid App ID.","code":200},' +
				'"result":{"component":"Gateway.ping","data":{"success":false}}}'
			);

			if (t.assertNotNull(response.error, "response error parsed")) {
				t.assertEquals(200, response.error.code, "response error code");
			}

			var result = response.getResult();
			if (t.assertNotNull(result, "result present")) {
				t.assertNotNull(result.error, "error pushed down to the result");
				t.assertEquals(200, result.error.code, "same code on the result");
			}
			t.done();
		});

		add("keeps a result's own error rather than overwriting it", function(t:ngiotest.TestContext):Void {
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"success":false,"error":{"message":"outer","code":200},' +
				'"result":{"component":"Medal.unlock","data":{"success":false,"error":{"message":"inner","code":202}}}}'
			);

			var result = response.getResult();
			if (t.assertNotNull(result.error, "result kept an error")) {
				t.assertEquals(202, result.error.code, "the result's own error wins");
			}
			t.done();
		});

		add("ignores result entries the factory cannot type", function(t:ngiotest.TestContext):Void {
			// A future gateway component this build has never heard of must not
			// take the whole response down with it.
			var response:io.newgrounds.models.objects.Response = self.importResponse(
				'{"success":true,"result":[' +
				'{"component":"Gateway.ping","data":{"success":true}},' +
				'{"component":"Future.method","data":{"success":true}},' +
				'{"component":"malformed","data":{"success":true}}' +
				']}'
			);

			var results:Array = response.getResultList();
			if (t.assertNotNull(results, "surviving results returned")) {
				t.assertEquals(1, results.length, "only the known component survived");
				t.assertEquals("Gateway.ping", results[0].objectName, "and it is the right one");
			}
			t.done();
		});

		add("survives a failed component that returns no payload", function(t:ngiotest.TestContext):Void {
			// Regression test for a bug the AS3 suite found on its first run.
			// A rejected Medal.unlock returns an error and no 'medal', and
			// AppState's merge used to read medal.id straight off that null.
			//
			// AS2 is where this is WORSE, not better. AS3 threw #1009, which at
			// least announced itself; AS2 tolerates reading a property off null,
			// so every id comparison in the merge quietly became
			// `id == undefined` and matched nothing at all. Same guard, added
			// for the same reason, so the two libraries stay comparable.
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:nullpayload", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			// Populate the medal cache first - the crash only reached the merge
			// when there was an existing collection to merge into.
			var seed:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(seed, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,"medals":[' +
				'{"id":10,"name":"Alpha","value":5}]}}}'
			));
			t.assertEquals(1, syncCore.appState.medals.length, "medal cached for the merge to find");

			var response:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.unlock","data":{"success":false,' +
				'"error":{"message":"The medal id (99999999) does not match any medals for this app.","code":202}}}}'
			));

			var result = response.getResult();
			if (t.assertNotNull(result, "result model built")) {
				t.assertFalse(result.success, "result reports failure");
				if (t.assertNotNull(result.error, "the server's own error survived")) {
					t.assertEquals(202, result.error.code, "and it is the real 202, not a generic 505");
				}
			}

			t.assertNull(response.error, "no spurious response-level error was invented");
			t.assertEquals(1, syncCore.appState.medals.length, "cached medals left intact");
			t.assertFalse(syncCore.appState.hasLoaded("medalScore"),
				"a rejected unlock does not mark medalScore as loaded");
			t.assertEquals(0, syncCore.appState.medalScore, "and does not overwrite the cached score");
			t.done();
		});

		add("a failed list component does not cache an empty result", function(t:ngiotest.TestContext):Void {
			// Same family: caching the missing payload and marking it loaded
			// would make hasLoaded() report true for data that never arrived,
			// which silences the "call loadMedals() first" warning.
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:failedlist", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":false,' +
				'"error":{"message":"You must be logged in to do that.","code":110}}}}'
			));

			t.assertNull(syncCore.appState.medals, "nothing cached");
			t.assertFalse(syncCore.appState.hasLoaded("medals"), "and not reported as loaded");
			t.done();
		});

		add("does not cache medals loaded from another app", function(t:ngiotest.TestContext):Void {
			// Medal.getList accepts an app_id, letting an approved app read a
			// different app's medals. The result echoes that id back. Those
			// medals belong to somebody else and must not become ours -
			// otherwise NGIO.getMedals() starts returning the wrong game's
			// medals, and hasLoaded('medals') claims they are ours.
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:crossapp", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var foreign:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(foreign, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,' +
				'"app_id":"39685:NJ1KkPGb","medals":[{"id":900,"name":"Foreign","value":5}]}}}'
			));

			t.assertNull(syncCore.appState.medals, "foreign medals were not cached");
			t.assertFalse(syncCore.appState.hasLoaded("medals"), "and medals are not marked loaded");

			// The caller still gets the data - it is only barred from AppState
			var result = foreign.getResult();
			if (t.assertNotNull(result, "the caller still receives the result")) {
				t.assertEquals(1, result.medals.length, "with the foreign medals intact");
				t.assertEquals("39685:NJ1KkPGb", result.app_id, "and the source app id");
			}
			t.done();
		});

		add("a foreign medal list cannot overwrite a loaded local one", function(t:ngiotest.TestContext):Void {
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:crossapp2", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			// Load our own medals first
			var local:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(local, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,"medals":[' +
				'{"id":10,"name":"Ours","value":5}]}}}'
			));
			t.assertEquals(1, syncCore.appState.medals.length, "local medals cached");

			// Then read another app's - this used to merge straight over the top
			var foreign:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(foreign, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,' +
				'"app_id":"39685:NJ1KkPGb","medals":[{"id":10,"name":"Theirs","value":999}]}}}'
			));

			t.assertEquals(1, syncCore.appState.medals.length, "medal count unchanged");
			t.assertEquals("Ours", syncCore.appState.medals[0].name, "our medal was not renamed");
			t.assertEquals(5, syncCore.appState.medals[0].value, "our medal kept its value");
			t.done();
		});

		add("does not cache save slots loaded from another app", function(t:ngiotest.TestContext):Void {
			// The quieter half of the same problem: cloud save slots are
			// per-app, so a foreign slot list overwriting ours would have the
			// game reading and writing against the wrong slot metadata.
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:crossapp3", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var foreign:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(foreign, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"CloudSave.loadSlots","data":{"success":true,' +
				'"app_id":"39685:NJ1KkPGb","slots":[{"id":1,"size":99,"url":"//example.com/theirs"}]}}}'
			));

			t.assertNull(syncCore.appState.saveSlots, "foreign slots were not cached");
			t.assertFalse(syncCore.appState.hasLoaded("saveSlots"), "and slots are not marked loaded");
			t.done();
		});

		add("still caches results that carry our own app id", function(t:ngiotest.TestContext):Void {
			// The guard keys off "is this a DIFFERENT app", not merely "is
			// app_id present" - so a gateway that echoed our own id on every
			// call must not switch off caching entirely.
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,' +
				'"app_id":"' + ngiotest.TestConfig.APP_ID + '","medals":[{"id":10,"name":"Ours","value":5}]}}}'
			));

			if (t.assertNotNull(syncCore.appState.medals, "our own medals were cached")) {
				t.assertEquals(1, syncCore.appState.medals.length, "one medal cached");
			}
			t.assertTrue(syncCore.appState.hasLoaded("medals"), "and marked loaded");
			t.done();
		});

		add("synchronises parsed results into AppState", function(t:ngiotest.TestContext):Void {
			// The response path is what actually populates NGIO.getMedals().
			var syncCore:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:sync", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			t.assertFalse(syncCore.appState.hasLoaded("medals"), "medals start unloaded");

			var response:io.newgrounds.models.objects.Response = self.newResponse(syncCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,"medals":[' +
				'{"id":10,"name":"Alpha","value":5},{"id":20,"name":"Beta","value":10}]}}}'
			));

			t.assertTrue(syncCore.appState.hasLoaded("medals"), "medals marked as loaded");
			if (t.assertNotNull(syncCore.appState.medals, "medals cached on AppState")) {
				t.assertEquals(2, syncCore.appState.medals.length, "both medals cached");
			}
			t.done();
		});

		add("two Cores do not share one AppState's loaded-data record", function(t:ngiotest.TestContext):Void {
			// AS2-specific regression guard. AppState.dataLoaded is an array
			// whose only initialiser used to be at its declaration, which in AS2
			// means it lived on the PROTOTYPE until something wrote it on an
			// instance - so markLoaded() on one Core pushed into an array every
			// other Core was also reading.
			//
			// A game with a single Core would never notice. This suite builds a
			// Core per test, so it would have noticed constantly, and in exactly
			// the confusing way where tests pass or fail by run order.
			var loaded:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:sharing-a", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			var response:io.newgrounds.models.objects.Response = self.newResponse(loaded);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":{"component":"Medal.getList","data":{"success":true,"medals":[' +
				'{"id":10,"name":"Alpha","value":5}]}}}'
			));
			t.assertTrue(loaded.appState.hasLoaded("medals"), "the first Core loaded its medals");

			var fresh:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:sharing-b", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			t.assertFalse(fresh.appState.hasLoaded("medals"), "a second Core starts with nothing loaded");
			t.assertNull(fresh.appState.medals, "and no medals");
			t.done();
		});

		add("hasLoaded and markLoaded reject names outside dataProperties", function(t:ngiotest.TestContext):Void {
			// AS2-specific regression guard, and the reason the one above can be
			// trusted. Both methods validate their argument with a linear search
			// over AppState.dataProperties - which was written as Array.indexOf,
			// a method AVM1 does not have. It returned undefined, so
			// `undefined == -1` never fired the throw, `undefined != -1` was
			// always true, and the result was that hasLoaded() answered TRUE for
			// everything while markLoaded() recorded nothing.
			var probe:io.newgrounds.Core =
				new io.newgrounds.Core("unit-test:loadednames", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			var state = probe.appState;

			t.assertThrows(function():Void {
				state.hasLoaded("noSuchProperty");
			}, "hasLoaded rejects an unknown name");

			t.assertThrows(function():Void {
				state.markLoaded("noSuchProperty");
			}, "markLoaded rejects an unknown name");

			t.assertDoesNotThrow(function():Void {
				state.hasLoaded("medals");
			}, "and accepts a real one");

			t.assertFalse(state.hasLoaded("medals"), "which reports false before anything is loaded");
			state.markLoaded("medals");
			t.assertTrue(state.hasLoaded("medals"), "and true afterwards");
			t.done();
		});

		//==================== COMPONENT-LEVEL FAILURE REPORTING ====================

		add("a successful response carrying a refused component reports an error", function(t:ngiotest.TestContext):Void {
			// Regression test. AppState.loadData inspected only the RESPONSE
			// level error, so this exact shape - a request that succeeded while
			// the component inside it was refused - reached the caller as
			// (appState, null): no data and no reason.
			//
			// It is the ordinary shape of "you are not logged in", not an exotic
			// one, and NGIO.loadSaveSlots / loadMedalScore / loadAppData all went
			// through it. A game would have read the silence as "this user has no
			// saves".
			var failCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(failCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":[{"component":"CloudSave.loadSlots","data":{"success":false,' +
				'"error":{"message":"User is not logged in.","code":110}}}]}'
			));

			t.assertTrue(response.success, "the response itself succeeded");
			t.assertNull(response.error, "and carries no response-level error");

			var found = io.newgrounds.AppState.firstResultError(response);
			if (t.assertNotNull(found, "but the component-level error is still found")) {
				t.assertEquals(110, found.code, "and it is the server's own 110, not a generic code");
				t.note("component-level error: [" + found.code + "] " + found.message);
			}
			t.done();
		});

		add("a wholly successful response reports no error", function(t:ngiotest.TestContext):Void {
			// The other half: firstResultError must not invent a failure, or
			// every successful load would start reporting one.
			var okCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(okCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":[' +
				'{"component":"Medal.getList","data":{"success":true,"medals":[]}},' +
				'{"component":"ScoreBoard.getBoards","data":{"success":true,"scoreboards":[]}}' +
				']}'
			));

			t.assertNull(io.newgrounds.AppState.firstResultError(response), "no error found");
			t.done();
		});

		add("a partly failed batch reports the first failure", function(t:ngiotest.TestContext):Void {
			// loadData batches several components into one request, so one can
			// fail while others succeed - ask for medals and saveSlots as a guest
			// and exactly this comes back. Reporting the first error keeps the
			// callback signature unchanged; the properties that did load are
			// still cached, and hasLoaded() can tell them apart.
			var mixedCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(mixedCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":[' +
				'{"component":"Medal.getList","data":{"success":true,"medals":[]}},' +
				'{"component":"CloudSave.loadSlots","data":{"success":false,' +
				'"error":{"message":"User is not logged in.","code":110}}}' +
				']}'
			));

			var found = io.newgrounds.AppState.firstResultError(response);
			if (t.assertNotNull(found, "the failure inside a mixed batch is found")) {
				t.assertEquals(110, found.code, "and reports the failing component's code");
			}

			// The point of the third layer: the error has to say WHERE. An
			// envelope can carry several components, so "something failed" is not
			// an answer a caller can act on.
			var detailed:Array = io.newgrounds.AppState.resultErrors(response);
			if (t.assertEquals(1, detailed.length, "exactly one component failed")) {
				t.assertEquals("CloudSave.loadSlots", detailed[0].component,
					"and it is named, not anonymous");
				t.note("failed component: " + detailed[0].component +
				       " -- [" + detailed[0].error.code + "] " + detailed[0].error.message);
			}

			// The successful half still landed.
			t.assertTrue(mixedCore.appState.hasLoaded("medals"), "medals still cached from the same batch");
			t.done();
		});

		add("a failed component with no error payload still reports something", function(t:ngiotest.TestContext):Void {
			// success:false with no error object at all. Without this branch the
			// caller would be back to a silent failure - which is the whole
			// defect being fixed, arriving by a different route.
			var bareCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(bareCore);
			io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(
				'{"success":true,"result":[{"component":"CloudSave.loadSlots","data":{"success":false}}]}'
			));

			var found = io.newgrounds.AppState.firstResultError(response);
			if (t.assertNotNull(found, "an error is still produced")) {
				t.assertEquals(io.newgrounds.Errors.INVALID_RESPONSE, found.code,
					"falls back to INVALID_RESPONSE rather than staying silent");
			}
			t.done();
		});

		//==================== LOADER FAILURE REPORTING ====================

		add("a failed Loader request reports an error, not a silent null", function(t:ngiotest.TestContext):Void {
			// Regression test. NgioLoaderHelper.loadUrl checked only
			// result.error, and a failed REQUEST carries no result - so the
			// whole branch was skipped and the caller got (null, null). A game
			// whose network was down could not tell that from a successful call
			// that happened to return an empty url.
			//
			// Reproduced by importing a response-level failure, which is exactly
			// what the transport builds from a failed load.
			var failCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var response:io.newgrounds.models.objects.Response = self.newResponse(failCore);
			response.importFromObject({
				success: false,
				error: { code: io.newgrounds.Errors.SERVER_UNAVAILABLE, message: "The gateway request failed with HTTP 503" }
			});

			t.assertFalse(response.success, "the response reports failure");
			t.assertNotNull(response.error, "and carries an error");
			t.assertNull(response.getResult(), "with no result to read a url from");

			// The shape the old code tripped on: no result means the only place
			// an error can come from is the response itself.
			t.assertEquals(io.newgrounds.Errors.SERVER_UNAVAILABLE, response.error.code,
				"which is where the caller's error has to come from");
			t.note("response-level error: " + response.error.message);
			t.done();
		});

		add("a transport failure is not reported as a server error", function(t:ngiotest.TestContext):Void {
			// Regression test for the defect the first complete run surfaced.
			//
			// Core.onHTTPResponse used to call Errors.getError(statusCode), treating
			// the HTTP status AS an Errors code. LoadVars exposes no HTTP status, so
			// CoreTransportHelper synthesises 500 when no body arrives - and 500 is a
			// real Errors constant whose message is "An unexpected error has occurred
			// on the server. If error persists, contact support." Every transport
			// failure the library can have told the game the SERVER had failed and
			// sent the player to support.
			//
			// Drives the real entry point rather than hand-building a Response:
			// forwardHTTPResponse is the seam CoreTransportHelper calls, and its
			// callback fires synchronously, so no async plumbing is needed.
			var failCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var captured = null;
			failCore.forwardHTTPResponse(500, null, function(response):Void {
				captured = response;
			}, null);

			if (!t.assertNotNull(captured, "the callback received a Response")) {
				t.done();
				return;
			}

			t.assertFalse(captured.success, "the response reports failure");

			if (t.assertNotNull(captured.error, "and carries an error")) {
				// Deliberately UNCHANGED by the fix: codeForStatus(500) is
				// SERVER_ERROR, which IS 500. Anything branching on error.code
				// behaves exactly as before - that is what made this change safe to
				// take without touching AS3, the skeletons or the wiki.
				t.assertEquals(io.newgrounds.Errors.SERVER_ERROR, captured.error.code,
					"code stays 500, so callers branching on it are unaffected");

				// The message is the part that had to change.
				t.assertTrue(captured.error.message.indexOf("gateway request") >= 0,
					"message blames the request, got <" + captured.error.message + ">");
				t.assertTrue(captured.error.message.indexOf("contact support") < 0,
					"message no longer sends the player to support");
				t.note("transport failure now reports: " + captured.error.message);
			}

			// The other half of the old defect: an unlisted status produced an
			// unrecognised Errors code with no message at all. codeForStatus() falls
			// back by CLASS, so a 502 still reads as a server problem.
			var oddCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var oddCaptured = null;
			oddCore.forwardHTTPResponse(502, null, function(response):Void {
				oddCaptured = response;
			}, null);

			if (t.assertNotNull(oddCaptured, "502 also produced a Response")) {
				if (t.assertNotNull(oddCaptured.error, "502 carries an error")) {
					t.assertEquals(io.newgrounds.Errors.SERVER_ERROR, oddCaptured.error.code,
						"502 falls back to SERVER_ERROR rather than an unrecognised code");
					t.note("unlisted status reports: " + oddCaptured.error.message);
				}
			}

			t.done();
		});

		add("no HTTP status is reported as unknown, not invented", function(t:ngiotest.TestContext):Void {
			// The case that actually matters in AS2, because it is the usual one:
			// LoadVars only exposes a status when the host supplies one, so
			// CoreTransportHelper reports UNKNOWN_STATUS most of the time.
			//
			// It must NOT be dressed up as a 500. A dropped connection, a blocked
			// domain and a rate limit all arrive here, and none of them are the
			// server failing - the request may never have left the machine.
			var unknownCore:io.newgrounds.Core =
				new io.newgrounds.Core(ngiotest.TestConfig.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);

			var captured = null;
			unknownCore.forwardHTTPResponse(
				io.newgrounds.helpers.HttpStatusHelper.UNKNOWN_STATUS, null,
				function(response):Void {
					captured = response;
				}, null);

			if (!t.assertNotNull(captured, "the callback received a Response")) {
				t.done();
				return;
			}

			t.assertFalse(captured.success, "the response reports failure");

			if (t.assertNotNull(captured.error, "and carries an error")) {
				t.assertEquals(io.newgrounds.Errors.INVALID_RESPONSE, captured.error.code,
					"an unreported status is INVALID_RESPONSE, not SERVER_ERROR");
				t.assertTrue(captured.error.code != io.newgrounds.Errors.SERVER_ERROR,
					"and specifically not 500, which would blame the server");
				t.assertTrue(captured.error.message.indexOf("no HTTP status") >= 0,
					"message says no status was reported, got <" + captured.error.message + ">");
				t.note("unreported status reports: " + captured.error.message);
			}

			t.done();
		});
	}

	//==================== HELPERS ====================
	//
	// Public because the closures above reach them through `self`, and AS2
	// cannot see a private member from inside a nested function.

	/**
	 * Wrap a component the way Core.executeComponent() does.
	 *
	 * @param useCore Pass null to use the suite's own Core. There are no default
	 *                parameter values in AS2, so every call site states it.
	 */
	public function makeExecute(component:String, method:String, params:Object, useCore:io.newgrounds.Core):io.newgrounds.models.objects.Execute {
		var target:io.newgrounds.Core = (useCore != null) ? useCore : core;

		var componentModel:io.newgrounds.BaseComponent =
			io.newgrounds.models.objects.ObjectFactory.CreateComponent(component, method, params, target);

		var execute:io.newgrounds.models.objects.Execute =
			io.newgrounds.models.objects.Execute(
				io.newgrounds.models.objects.ObjectFactory.CreateObject("Execute", null, target));

		execute.core = target;
		execute.setComponent(componentModel);
		return execute;
	}

	/**
	 * Build the gateway envelope for a single Execute, as Core.sendRequest() would.
	 */
	public function buildEnvelope(execute:io.newgrounds.models.objects.Execute, sessionId:String):Object {
		var request:io.newgrounds.models.objects.Request =
			io.newgrounds.models.objects.Request(
				io.newgrounds.models.objects.ObjectFactory.CreateObject("Request", null, core));

		request.core = core;
		request.app_id = core.appId;
		request.debug = core.useDebugMode;
		if (sessionId != null) {
			request.session_id = sessionId;
		}
		request.setExecute(execute);

		return io.newgrounds.helpers.HttpRequestHelper.buildGatewayRequestObject(request);
	}

	/** A blank Response bound to the given Core. */
	public function newResponse(forCore:io.newgrounds.Core):io.newgrounds.models.objects.Response {
		return io.newgrounds.models.objects.Response(
			io.newgrounds.models.objects.ObjectFactory.CreateObject("Response", null, forCore));
	}

	/**
	 * Feed raw server JSON through the same importer Core uses on a 200.
	 */
	public function importResponse(json:String):io.newgrounds.models.objects.Response {
		var response:io.newgrounds.models.objects.Response = newResponse(core);
		io.newgrounds.helpers.HttpResponseHelper.importResponseObject(response, io.newgrounds.encoders.JSON.decode(json));
		return response;
	}

	/** RC4 is symmetric, so this is the same call Core made to encrypt. */
	public function decrypt(base64Text:String):String {
		return io.newgrounds.encoders.RC4.decrypt(base64Text, ngiotest.TestConfig.ENCRYPTION_KEY);
	}
}
