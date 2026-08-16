/**
 * OfflineBaseObjectSuite
 *
 * Exercises BaseObject's import/export machinery, which every model in the
 * library inherits. If this suite is wrong, everything downstream is wrong.
 */
import io.newgrounds.BaseComponent;
import io.newgrounds.BaseObject;
import io.newgrounds.encoders.JSON;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.NgioError;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.User;

import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineBaseObjectSuite extends ngiotest.TestSuite {

	public function OfflineBaseObjectSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Offline / BaseObject";
	}

	public function build():Void {

		var self:ngiotest.suites.OfflineBaseObjectSuite = this;

		add("imports scalar properties onto a model", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.importFromObject({
				id: 12345,
				name: "Test Medal",
				description: "A test medal",
				icon: "https://example.com/icon.webp",
				value: 50,
				difficulty: 3,
				secret: false,
				unlocked: true
			});

			t.assertEquals(12345, medal.id, "id");
			t.assertEquals("Test Medal", medal.name, "name");
			t.assertEquals("A test medal", medal.description, "description");
			t.assertEquals("https://example.com/icon.webp", medal.icon, "icon");
			t.assertEquals(50, medal.value, "value");
			t.assertEquals(3, medal.difficulty, "difficulty");
			t.assertFalse(medal.secret, "secret");
			t.assertTrue(medal.unlocked, "unlocked");
			t.done();
		});

		add("does NOT coerce JSON values to the declared property type", function(t:ngiotest.TestContext):Void {
			// THIS IS THE ONE PLACE THE TWO LIBRARIES GENUINELY DISAGREE, and
			// it is asserted rather than glossed over so nobody has to
			// rediscover it.
			//
			// The AS3 suite has this test the other way round: it asserts that
			// importing {id: "42"} leaves medal.id as the NUMBER 42. That works
			// in AS3 because AVM2 slots are typed at runtime, so writing a
			// String into a Number property coerces on assignment.
			//
			// AS2 type annotations are checked by the compiler and then thrown
			// away - AVM1 has no typed slots at all - and importFromObject
			// assigns through this[propertyName], which the compiler never sees
			// in the first place. Nothing coerces. Medal.castTypes is empty, so
			// castToExpectedType passes the value straight through, and the
			// string is stored as a string.
			//
			// It matters because the value still compares equal with ==, so the
			// difference hides until something does arithmetic on it: a Number
			// medal value of "5" plus 1 is the string "51", not 6.
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.importFromObject({ id: "42", value: "5", unlocked: 1 });

			t.assertEquals(42, medal.id, "the value is right by loose comparison");
			t.assertEquals("string", typeof(medal.id), "but it is still a String - AS2 does not coerce on assignment");
			t.assertEquals("string", typeof(medal.value), "same for value");
			t.assertEquals("number", typeof(medal.unlocked), "and a numeric 1 stays a Number, it does not become Boolean true");
			t.assertTrue(medal.unlocked == true, "1 is still truthy by loose comparison");

			t.note("AS2 stores imported values verbatim; AS3 coerces them to the declared type. " +
			       "Only matters when a value arrives from the gateway in the wrong JSON type.");
			t.done();
		});

		add("resets omitted properties to their defaults", function(t:ngiotest.TestContext):Void {
			// Importing is a replace, not a merge: leftovers from a previous
			// import must not survive, or a re-fetched medal would keep an
			// unlocked flag the server no longer reports.
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.unlocked = true;
			medal.name = "stale name";
			medal.value = 999;

			medal.importFromObject({ id: 5 });

			t.assertEquals(5, medal.id, "provided property is set");
			t.assertNull(medal.name, "omitted String resets to null");
			t.assertStrictEquals(false, medal.unlocked, "omitted Boolean resets to false");
			t.assertStrictEquals(0, medal.value, "omitted Number resets to 0");
			t.done();
		});

		add("casts a nested object using castTypes", function(t:ngiotest.TestContext):Void {
			var session:io.newgrounds.models.objects.Session = new io.newgrounds.models.objects.Session();
			session.importFromObject({
				id: "session-abc",
				expired: false,
				user: { id: 54321, name: "TestUser", supporter: true }
			});

			t.assertEquals("session-abc", session.id, "session id");
			if (t.assertNotNull(session.user, "user was created")) {
				t.assertIsType(session.user, io.newgrounds.models.objects.User, "user is a User instance");
				t.assertEquals(54321, session.user.id, "user id");
				t.assertEquals("TestUser", session.user.name, "user name");
				t.assertTrue(session.user.supporter, "user supporter");
			}
			t.done();
		});

		add("casts array-of-X into typed instances", function(t:ngiotest.TestContext):Void {
			var result = io.newgrounds.models.objects.ObjectFactory.CreateResult("Medal", "getList", {
				success: true,
				medals: [
					{ id: 1, name: "First", value: 5 },
					{ id: 2, name: "Second", value: 10 }
				]
			}, null);

			if (!t.assertNotNull(result, "getListResult created")) {
				t.done();
				return;
			}

			var medals:Array = result["medals"];
			if (!t.assertNotNull(medals, "medals array populated")) {
				t.done();
				return;
			}

			t.assertEquals(2, medals.length, "medal count");
			t.assertIsType(medals[0], io.newgrounds.models.objects.Medal, "element 0 is a Medal");
			t.assertIsType(medals[1], io.newgrounds.models.objects.Medal, "element 1 is a Medal");
			t.assertEquals("First", medals[0].name, "element 0 name");
			t.assertEquals(10, medals[1].value, "element 1 value");
			t.done();
		});

		add("wraps a lone object in an array for array-of-X", function(t:ngiotest.TestContext):Void {
			// The gateway collapses single-element lists to a bare object.
			// Callers still expect an Array, so the cast has to re-wrap it.
			var result = io.newgrounds.models.objects.ObjectFactory.CreateResult("Medal", "getList", {
				success: true,
				medals: { id: 7, name: "Only", value: 25 }
			}, null);

			if (!t.assertNotNull(result, "getListResult created")) {
				t.done();
				return;
			}

			var medals:Array = result["medals"];
			if (!t.assertNotNull(medals, "lone object became an array")) {
				t.done();
				return;
			}

			t.assertEquals(1, medals.length, "array holds one entry");
			t.assertIsType(medals[0], io.newgrounds.models.objects.Medal, "entry is a Medal");
			t.assertEquals("Only", medals[0].name, "entry name");
			t.done();
		});

		add("builds an NgioError from an error payload", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.importFromObject({
				id: 1,
				error: { code: 104, message: "Your session has expired." }
			});

			if (t.assertNotNull(medal.error, "error object created")) {
				t.assertIsType(medal.error, io.newgrounds.models.objects.NgioError, "error is an NgioError");
				t.assertEquals(104, medal.error.code, "error code");
				t.assertEquals("Your session has expired.", medal.error.message, "error message");
			}
			t.done();
		});

		add("toObject() drops nulls when asked", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 3;

			var lean:Object = medal.toObject(true, true);
			t.assertEquals(3, lean.id, "id survives");
			t.assertFalse(lean.hasOwnProperty("name"), "null name omitted");
			t.assertFalse(lean.hasOwnProperty("description"), "null description omitted");
			t.assertTrue(lean.hasOwnProperty("value"), "zero Number kept - 0 is a real value");
			t.assertTrue(lean.hasOwnProperty("secret"), "false Boolean kept - false is a real value");
			t.done();
		});

		add("toObject() keeps nulls when asked", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 3;

			var full:Object = medal.toObject(false, false);
			t.assertTrue(full.hasOwnProperty("name"), "null name present");
			t.assertNull(full.name, "null name is null");
			t.assertEquals(8, self.countKeys(full), "every declared property present");
			t.done();
		});

		add("toObject() flattens nested models recursively", function(t:ngiotest.TestContext):Void {
			var session:io.newgrounds.models.objects.Session = new io.newgrounds.models.objects.Session();
			session.id = "abc";
			session.user = new io.newgrounds.models.objects.User();
			session.user.id = 9;
			session.user.name = "Nested";

			var flat:Object = session.toObject(true, true);
			t.assertNotNull(flat.user, "user present");
			t.assertFalse(flat.user instanceof io.newgrounds.models.objects.User, "nested model became a plain Object");
			t.assertEquals("Nested", flat.user.name, "nested value survived");
			t.done();
		});

		add("toJsonString() produces parseable JSON", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 11;
			medal.name = 'Quote " and \\ backslash';
			medal.value = 5;

			var json:String = medal.toJsonString();
			t.assertNotNull(json, "json produced");

			var reparsed:Object = io.newgrounds.encoders.JSON.decode(json);
			t.assertEquals(11, reparsed.id, "id round-tripped");
			t.assertEquals('Quote " and \\ backslash', reparsed.name, "escapes round-tripped");
			t.done();
		});

		add("imports from another BaseObject of the same type", function(t:ngiotest.TestContext):Void {
			var source:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			source.id = 77;
			source.name = "Source";
			source.unlocked = true;

			var target:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			target.importFromObject(source);

			t.assertEquals(77, target.id, "id copied");
			t.assertEquals("Source", target.name, "name copied");
			t.assertTrue(target.unlocked, "unlocked copied");
			t.done();
		});

		add("refuses to import a mismatched model type", function(t:ngiotest.TestContext):Void {
			var user:io.newgrounds.models.objects.User = new io.newgrounds.models.objects.User();
			user.id = 1;

			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			t.assertThrows(function():Void {
				medal.importFromObject(user);
			}, "importing a User into a Medal should throw");
			t.done();
		});

		add("refuses to import an Array", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			t.assertThrows(function():Void {
				medal.importFromObject([1, 2, 3]);
			}, "importing an Array should throw");
			t.done();
		});

		add("ignores null and undefined imports", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			medal.id = 4;

			medal.importFromObject(null);
			t.assertEquals(4, medal.id, "null import left the model untouched");

			medal.importFromObject(undefined);
			t.assertEquals(4, medal.id, "undefined import left the model untouched");
			t.done();
		});

		add("getFullObjectName() qualifies by type", function(t:ngiotest.TestContext):Void {
			var medal:io.newgrounds.models.objects.Medal = new io.newgrounds.models.objects.Medal();
			var ngioError:io.newgrounds.models.objects.NgioError = new io.newgrounds.models.objects.NgioError();

			t.assertEquals("object.Medal", medal.getFullObjectName(), "object model");
			t.assertEquals("object.Error", ngioError.getFullObjectName(), "NgioError reports as Error");

			var component:io.newgrounds.BaseComponent =
				io.newgrounds.models.objects.ObjectFactory.CreateComponent("Medal", "unlock", null, null);
			t.assertEquals("component.Medal.unlock", component.getFullObjectName(), "component model");
			t.done();
		});

		add("getFullObjectName() never actually nests, because parent is never set", function(t:ngiotest.TestContext):Void {
			// BaseObject declares `parent` and `parentPropertyName`, and
			// getFullObjectName() builds a hierarchical name from them. The wiki
			// says they are "set when a model is nested during import".
			//
			// NOTHING IN EITHER LIBRARY EVER ASSIGNS THEM - verified by grepping
			// the whole build tree. So the hierarchical branch is unreachable and
			// a nested model reports the same flat name as a standalone one.
			//
			// This asserts the behaviour that actually exists rather than the
			// behaviour that is documented, because a test for the documented
			// version would fail for a reason that has nothing to do with AS2.
			// The properties should be either wired up or removed; that decision
			// has not been made, and this test is here so it does not get made by
			// accident.
			var session:io.newgrounds.models.objects.Session = new io.newgrounds.models.objects.Session();
			session.importFromObject({
				id: "abc",
				user: { id: 1, name: "Nested" }
			});

			if (!t.assertNotNull(session.user, "nested user imported")) {
				t.done();
				return;
			}

			t.assertNull(session.user.parent, "parent is not set by import");
			t.assertNull(session.user.parentPropertyName, "parentPropertyName is not set by import");
			t.assertEquals("object.User", session.user.getFullObjectName(),
				"so the nested user reports a flat name, not object.Session.user");

			t.note("BaseObject.parent / parentPropertyName are dead in both AS libraries - " +
			       "declared and documented, never assigned. getFullObjectName() can only ever return a flat name.");
			t.done();
		});

		add("validates required properties", function(t:ngiotest.TestContext):Void {
			// Event.logEvent requires host + event_name, both Strings that
			// default to null, so a fresh instance must be invalid.
			var component:io.newgrounds.BaseComponent =
				io.newgrounds.models.objects.ObjectFactory.CreateComponent("Event", "logEvent", null, null);
			if (!t.assertNotNull(component, "logEvent component created")) {
				t.done();
				return;
			}

			t.assertFalse(component.hasValidProperties(), "fresh component is invalid");
			t.assertEquals(2, component.getValidationErrors().length, "two missing properties reported");

			component["host"] = "localhost";
			t.assertFalse(component.hasValidProperties(), "still invalid with one property set");
			t.assertEquals(1, component.getValidationErrors().length, "one missing property reported");

			component["event_name"] = "test";
			t.assertTrue(component.hasValidProperties(), "valid once both are set");
			t.assertEquals(0, component.getValidationErrors().length, "no errors reported");
			t.done();
		});

		add("treats an empty string as a missing required property", function(t:ngiotest.TestContext):Void {
			var component:io.newgrounds.BaseComponent =
				io.newgrounds.models.objects.ObjectFactory.CreateComponent("Event", "logEvent", null, null);
			component["host"] = "";
			component["event_name"] = "test";

			t.assertFalse(component.hasValidProperties(), "empty string does not satisfy a requirement");

			var errors:Array = component.getValidationErrors();
			t.assertEquals(1, errors.length, "one error reported");
			t.assertTrue(String(errors[0]).indexOf("empty string") >= 0, "error explains it is empty, not missing");
			t.done();
		});

		add("treats zero as a valid required value", function(t:ngiotest.TestContext):Void {
			// ScoreBoard.getScores requires id, a Number defaulting to 0, and
			// unlike Medal.unlock it does not also require a session - so this
			// isolates the "is 0 missing?" question. Rejecting 0 would make
			// board id 0 permanently unusable.
			var component:io.newgrounds.BaseComponent =
				io.newgrounds.models.objects.ObjectFactory.CreateComponent("ScoreBoard", "getScores", null, null);
			component["id"] = 0;
			t.assertTrue(component.hasValidProperties(), "0 satisfies a required Number");
			t.done();
		});

		add("a session-gated component is invalid without a session", function(t:ngiotest.TestContext):Void {
			// Medal.unlock sets requiresSession, so BaseComponent adds a session
			// check on top of the required-property check. With no core attached
			// there is no session to find.
			var component:io.newgrounds.BaseComponent =
				io.newgrounds.models.objects.ObjectFactory.CreateComponent("Medal", "unlock", null, null);
			component["id"] = 1;

			t.assertFalse(component.hasValidProperties(), "no core means no session means invalid");
			t.assertEquals(0, component.getValidationErrors().length,
				"the session rule is not reported by getValidationErrors()");
			t.done();
		});
	}

	//==================== HELPERS ====================

	/**
	 * Public because the closures above reach it through `self`, and AS2 cannot
	 * see a private member from inside a nested function.
	 */
	public function countKeys(source:Object):Number {
		var count:Number = 0;
		for (var key:String in source) {
			count++;
		}
		return count;
	}
}
