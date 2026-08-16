/**
 * OfflineObjectFactorySuite
 *
 * ObjectFactory is a hand-maintained switch over every model name in the
 * library. A model that gets added to the codebase but not to the switch fails
 * silently at runtime - CreateObject just returns null and the caller stores
 * nothing. These tests walk the full expected inventory so that gap shows up
 * here instead of as a mysteriously empty medal list.
 *
 * The inventory below was re-derived from the AS2 ObjectFactory rather than
 * copied from the AS3 suite, and it matches: 11 objects, 25 components, 25
 * results.
 */
import io.newgrounds.BaseComponent;
import io.newgrounds.BaseObject;
import io.newgrounds.BaseResult;
import io.newgrounds.Core;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.NgioError;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.objects.User;

import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineObjectFactorySuite extends ngiotest.TestSuite {

	/**
	 * Every object model the factory is expected to know about.
	 *
	 * Always read through the full class path. AS2 does not inherit statics and
	 * a bare reference from inside a nested function literal is unreliable, so
	 * the qualified form is the only one that is certain to resolve.
	 */
	private static var OBJECT_NAMES:Array = [
		"Request", "Execute", "Debug", "Response", "Error",
		"Session", "User", "Medal", "ScoreBoard", "Score", "SaveSlot"
	];

	/**
	 * Every component the gateway exposes, as "Component.method".
	 * Results are expected to exist for exactly the same list.
	 */
	private static var COMPONENT_PATHS:Array = [
		"App.logView", "App.checkSession", "App.getHostLicense",
		"App.getCurrentVersion", "App.startSession", "App.endSession",
		"CloudSave.clearSlot", "CloudSave.loadSlot", "CloudSave.loadSlots", "CloudSave.setData",
		"Event.logEvent",
		"Gateway.getVersion", "Gateway.getDatetime", "Gateway.ping",
		"Loader.loadOfficialUrl", "Loader.loadAuthorUrl", "Loader.loadReferral",
		"Loader.loadMoreGames", "Loader.loadNewgrounds",
		"Medal.getList", "Medal.getMedalScore", "Medal.unlock",
		"ScoreBoard.getBoards", "ScoreBoard.postScore", "ScoreBoard.getScores"
	];

	/**
	 * A syntactically valid Base64 key for constructing throwaway Core
	 * instances. Never sent anywhere - these tests make no network calls.
	 */
	private static var THROWAWAY_KEY:String = "AAECAwQFBgcICQoLDA0ODw==";

	public function OfflineObjectFactorySuite() {
		super();
	}

	public function getSuiteName():String {
		return "Offline / ObjectFactory";
	}

	public function build():Void {

		add("creates every registered object model", function(t:ngiotest.TestContext):Void {
			var names:Array = ngiotest.suites.OfflineObjectFactorySuite.OBJECT_NAMES;

			for (var i:Number = 0; i < names.length; i++) {
				var name:String = names[i];
				var model:io.newgrounds.BaseObject =
					io.newgrounds.models.objects.ObjectFactory.CreateObject(name, null, null);

				if (t.assertNotNull(model, "CreateObject('" + name + "')")) {
					t.assertEquals("object", model.objectType, name + " reports objectType 'object'");
				}
			}
			t.done();
		});

		add("creates every registered component", function(t:ngiotest.TestContext):Void {
			var paths:Array = ngiotest.suites.OfflineObjectFactorySuite.COMPONENT_PATHS;

			for (var i:Number = 0; i < paths.length; i++) {
				var path:String = paths[i];
				var parts:Array = path.split(".");
				var component:io.newgrounds.BaseComponent =
					io.newgrounds.models.objects.ObjectFactory.CreateComponent(parts[0], parts[1], null, null);

				if (t.assertNotNull(component, "CreateComponent('" + path + "')")) {
					t.assertEquals(path, component.objectName, path + " reports its own name");
					t.assertEquals("component", component.objectType, path + " reports objectType 'component'");
				}
			}
			t.done();
		});

		add("creates every registered result", function(t:ngiotest.TestContext):Void {
			var paths:Array = ngiotest.suites.OfflineObjectFactorySuite.COMPONENT_PATHS;

			for (var i:Number = 0; i < paths.length; i++) {
				var path:String = paths[i];
				var parts:Array = path.split(".");
				var result:io.newgrounds.BaseResult =
					io.newgrounds.models.objects.ObjectFactory.CreateResult(parts[0], parts[1], null, null);

				if (t.assertNotNull(result, "CreateResult('" + path + "')")) {
					t.assertEquals(path, result.objectName, path + " result reports its own name");
					t.assertEquals("result", result.objectType, path + " reports objectType 'result'");
				}
			}
			t.done();
		});

		add("matches names case-insensitively", function(t:ngiotest.TestContext):Void {
			var factory = io.newgrounds.models.objects.ObjectFactory;

			t.assertIsType(factory.CreateObject("medal", null, null), io.newgrounds.models.objects.Medal, "lowercase");
			t.assertIsType(factory.CreateObject("MEDAL", null, null), io.newgrounds.models.objects.Medal, "uppercase");
			t.assertIsType(factory.CreateObject("Medal", null, null), io.newgrounds.models.objects.Medal, "PascalCase");
			t.assertIsType(factory.CreateObject("mEdAl", null, null), io.newgrounds.models.objects.Medal, "mixed case");

			t.assertNotNull(factory.CreateComponent("MEDAL", "UNLOCK", null, null), "component, uppercase");
			t.assertNotNull(factory.CreateResult("medal", "unlock", null, null), "result, lowercase");
			t.done();
		});

		add("maps the name 'Error' to NgioError", function(t:ngiotest.TestContext):Void {
			// The schema calls it Error; the class is renamed because Error is a
			// reserved top-level type. That rename is only safe if the factory
			// still answers to the schema name.
			var ngioError:io.newgrounds.BaseObject =
				io.newgrounds.models.objects.ObjectFactory.CreateObject("Error", null, null);

			t.assertIsType(ngioError, io.newgrounds.models.objects.NgioError, "CreateObject('Error') builds an NgioError");
			t.assertEquals("Error", ngioError.objectName, "and still calls itself Error");
			t.done();
		});

		add("returns null for unknown names", function(t:ngiotest.TestContext):Void {
			var factory = io.newgrounds.models.objects.ObjectFactory;

			t.assertNull(factory.CreateObject("NoSuchObject", null, null), "unknown object");
			t.assertNull(factory.CreateComponent("NoSuch", "method", null, null), "unknown component");
			t.assertNull(factory.CreateResult("NoSuch", "method", null, null), "unknown result");

			// BaseObject.importFromObject() asks the factory for its own
			// objectName, which for a component is dotted ("Medal.unlock") and
			// deliberately absent from CreateObject's switch. Returning null
			// rather than throwing is what keeps that path working.
			t.assertNull(factory.CreateObject("Medal.unlock", null, null), "dotted component name");
			t.done();
		});

		add("returns null for empty names", function(t:ngiotest.TestContext):Void {
			var factory = io.newgrounds.models.objects.ObjectFactory;

			t.assertNull(factory.CreateObject(null, null, null), "null object name");
			t.assertNull(factory.CreateObject("", null, null), "empty object name");
			t.assertNull(factory.CreateComponent(null, "unlock", null, null), "null component");
			t.assertNull(factory.CreateComponent("Medal", null, null, null), "null method");
			t.assertNull(factory.CreateComponent("Medal", "", null, null), "empty method");
			t.done();
		});

		add("attaches the supplied Core reference", function(t:ngiotest.TestContext):Void {
			var core:io.newgrounds.Core = new io.newgrounds.Core(
				"unit-test:offline",
				ngiotest.suites.OfflineObjectFactorySuite.THROWAWAY_KEY,
				null,
				false
			);

			var factory = io.newgrounds.models.objects.ObjectFactory;

			var model:io.newgrounds.BaseObject = factory.CreateObject("Medal", null, core);
			t.assertStrictEquals(core, model.core, "object got the core");

			var component:io.newgrounds.BaseComponent = factory.CreateComponent("Medal", "unlock", null, core);
			t.assertStrictEquals(core, component.core, "component got the core");

			var result:io.newgrounds.BaseResult = factory.CreateResult("Medal", "unlock", null, core);
			t.assertStrictEquals(core, result.core, "result got the core");
			t.done();
		});

		add("imports supplied data on creation", function(t:ngiotest.TestContext):Void {
			var factory = io.newgrounds.models.objects.ObjectFactory;

			var medal:io.newgrounds.models.objects.Medal =
				io.newgrounds.models.objects.Medal(factory.CreateObject("Medal", { id: 8, name: "Factory" }, null));
			if (t.assertNotNull(medal, "medal created")) {
				t.assertEquals(8, medal.id, "id imported");
				t.assertEquals("Factory", medal.name, "name imported");
			}

			var component:io.newgrounds.BaseComponent = factory.CreateComponent("Medal", "unlock", { id: 99 }, null);
			if (t.assertNotNull(component, "component created")) {
				t.assertEquals(99, component["id"], "component parameter imported");
			}

			var user:io.newgrounds.models.objects.User =
				io.newgrounds.models.objects.User(factory.CreateObject("User", { id: 3, name: "Imported" }, null));
			if (t.assertNotNull(user, "user created")) {
				t.assertEquals("Imported", user.name, "user name imported");
			}
			t.done();
		});

		add("returns a distinct instance every call", function(t:ngiotest.TestContext):Void {
			var factory = io.newgrounds.models.objects.ObjectFactory;

			var first:io.newgrounds.models.objects.Medal =
				io.newgrounds.models.objects.Medal(factory.CreateObject("Medal", null, null));
			var second:io.newgrounds.models.objects.Medal =
				io.newgrounds.models.objects.Medal(factory.CreateObject("Medal", null, null));

			first.id = 1;
			second.id = 2;

			t.assertNotEquals(first, second, "instances are not the same object");
			t.assertEquals(1, first.id, "first kept its own state");
			t.assertEquals(2, second.id, "second kept its own state");
			t.done();
		});
	}
}
