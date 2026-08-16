/**
 * LiveCloudSaveSuite
 *
 * Writes to a cloud save slot, reads it back over HTTP, and clears it.
 *
 * NOTE ON DEBUG MODE: unlike medals and scores, it is not certain that cloud
 * saves honour debug mode server-side. This suite therefore treats slot
 * TestConfig.TEST_SAVE_SLOT_ID as genuinely writable and restores it to empty at
 * the end. Point TEST_SAVE_SLOT_ID at a scratch slot, never one holding data you
 * care about.
 *
 * The read-back is a plain HTTP GET against the returned url, so it is also the
 * only live test that exercises a non-gateway request. In AS2 that goes through
 * LoadVars.onData rather than AS3's URLLoader, which is why an empty or failed
 * read reports differently here - see SaveSlot.loadDataRaw.
 */
import io.newgrounds.models.objects.SaveSlot;

import ngiotest.LiveSuite;
import ngiotest.TestConfig;
import ngiotest.TestContext;

class ngiotest.suites.LiveCloudSaveSuite extends ngiotest.LiveSuite {

	/** Payload written by the save test and checked by the load test */
	private var writtenPayload:String;

	public function LiveCloudSaveSuite() {
		super();
		this.writtenPayload = null;
	}

	public function getSuiteName():String {
		return "Live / Cloud saves";
	}

	public function build():Void {

		var self:ngiotest.suites.LiveCloudSaveSuite = this;

		add("writes raw data to a slot", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var slot:io.newgrounds.models.objects.SaveSlot = self.testSlot();
			if (slot == null) {
				t.skip("save slot " + ngiotest.TestConfig.TEST_SAVE_SLOT_ID + " not available");
				return;
			}

			// Unique per run, so a stale read cannot pass by accident.
			self.writtenPayload = "ngio-as2-unit-test:" + new Date().getTime();
			t.status("Writing to cloud save slot " + slot.id + "...");

			slot.saveDataRaw(self.writtenPayload, function(error):Void {
				self.assertNoError(t, error, "saveDataRaw accepted");
				t.done();
			}, null);
		});

		add("reports the slot as holding data", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			// Re-fetch the slot list so this reflects server state rather than
			// whatever the write left in memory.
			NGIO.loadSaveSlots(function(slots:Array, error):Void {
				if (!self.assertNoError(t, error, "slot list reloaded")) {
					t.done();
					return;
				}

				var slot:io.newgrounds.models.objects.SaveSlot = self.testSlot();
				if (!t.assertNotNull(slot, "test slot present in the list")) {
					t.done();
					return;
				}

				t.assertTrue(slot.hasData(), "slot reports data after the write");
				t.assertTrue(slot.size > 0, "slot reports a non-zero size");
				t.assertNotNull(slot.datetime, "slot reports a save datetime");
				t.assertTrue(slot.timestamp > 0, "slot reports a save timestamp");
				t.note("slot " + slot.id + ": " + slot.size + " bytes, saved " + slot.datetime);
				t.done();
			}, null);
		});

		add("reads the data back over HTTP", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var slot:io.newgrounds.models.objects.SaveSlot = self.testSlot();
			if (slot == null || !slot.hasData()) {
				t.skip("test slot holds no data to read");
				return;
			}

			if (self.writtenPayload == null) {
				t.skip("nothing was written this run to compare against");
				return;
			}

			slot.loadDataRaw(function(data:String, error):Void {
				if (!self.assertNoError(t, error, "loadDataRaw completed")) {
					t.done();
					return;
				}

				if (t.assertNotNull(data, "data returned")) {
					t.assertEquals(self.writtenPayload, data, "round-tripped exactly what was written");
				}
				t.done();
			}, null);
		});

		add("round-trips a structured object", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			// Deliberately a different slot from the raw-text tests above - see
			// TEST_SAVE_SLOT_ID_ALT for why sharing one slot made this read back
			// the previous test's payload from cache.
			var slot:io.newgrounds.models.objects.SaveSlot = self.altSlot();
			if (slot == null) {
				t.skip("save slot " + ngiotest.TestConfig.TEST_SAVE_SLOT_ID_ALT + " not available");
				return;
			}

			var payload:Object = {
				level: 7,
				name: "Tester",
				unlocked: true,
				inventory: ["sword", "shield"],
				ratio: 0.75
			};

			slot.saveData(payload, function(saveError):Void {
				if (!self.assertNoError(t, saveError, "saveData accepted")) {
					t.done();
					return;
				}

				slot.loadData(function(loaded:Object, loadError):Void {
					if (!self.assertNoError(t, loadError, "loadData completed")) {
						t.done();
						return;
					}

					if (!t.assertNotNull(loaded, "object returned")) {
						t.done();
						return;
					}

					// assertNotNull is not enough: 0 is not null. If the url
					// served something other than our JSON - a proxy page, a CDN
					// error - the decoder can hand back a primitive, and reading
					// .level off a Number then behaves as undefined rather than
					// failing here with a reason.
					//
					// This matters MORE in AS2 than AS3: the bundled decoder
					// ignores trailing content, so a JSON prefix followed by an
					// error page parses cleanly. See OfflineJsonSuite.
					var loadedType:String = typeof(loaded);
					if (loadedType == "number" || loadedType == "string" || loadedType == "boolean") {
						t.fail("loadData returned the primitive <" + loaded + "> rather than an object" +
						       " - the slot url probably did not serve our JSON");
						t.done();
						return;
					}

					t.assertEquals(7, loaded.level, "number survived");
					t.assertEquals("Tester", loaded.name, "string survived");
					t.assertStrictEquals(true, loaded.unlocked, "boolean survived");
					t.assertEquals(0.75, loaded.ratio, "float survived");
					if (t.assertNotNull(loaded.inventory, "array survived")) {
						t.assertEquals(2, loaded.inventory.length, "array length survived");
						t.assertEquals("sword", loaded.inventory[0], "array contents survived");
					}
					t.done();
				}, null);
			}, null);
		});

		add("clears the slot", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var slot:io.newgrounds.models.objects.SaveSlot = self.testSlot();
			if (slot == null) {
				t.skip("save slot " + ngiotest.TestConfig.TEST_SAVE_SLOT_ID + " not available");
				return;
			}

			slot.clearData(function(error):Void {
				if (!self.assertNoError(t, error, "clearData accepted")) {
					t.done();
					return;
				}

				NGIO.loadSaveSlots(function(slots:Array, reloadError):Void {
					if (self.assertNoError(t, reloadError, "slot list reloaded after clear")) {
						var cleared:io.newgrounds.models.objects.SaveSlot = self.testSlot();
						if (t.assertNotNull(cleared, "slot still listed")) {
							t.assertFalse(cleared.hasData(), "slot reports empty after clearing");
						}
					}
					t.done();
				}, null);
			}, null);
		});

		add("reading an empty slot returns null, not an error", function(t:ngiotest.TestContext):Void {
			if (self.skipUnlessSignedIn(t)) {
				return;
			}

			var slot:io.newgrounds.models.objects.SaveSlot = self.testSlot();
			if (slot == null) {
				t.skip("save slot " + ngiotest.TestConfig.TEST_SAVE_SLOT_ID + " not available");
				return;
			}

			if (slot.hasData()) {
				t.skip("slot was not left empty by the clear test");
				return;
			}

			slot.loadDataRaw(function(data:String, error):Void {
				t.assertNull(data, "no data returned");
				t.assertNull(error, "an empty slot is not an error condition");
				t.done();
			}, null);
		});

		// REMOVED: "refuses cloud saves when signed out".
		//
		// It could never run. This suite is registered after sign-in, so its own
		// guard - skip if isSignedIn() - fired on every run a developer actually
		// does, and the test reported [SKIP] "this path cannot be reached"
		// forever. It was coverage on paper only.
		//
		// Both halves of what it meant to test now live where they are reachable:
		// LiveNoSessionSuite covers the refusal with no session at all, and
		// LiveGuestSuite covers it with a guest session and no user. Those two
		// states behave differently and neither was previously exercised live.
	}

	public function tearDown(done:Function):Void {
		// Leave both scratch slots empty regardless of how the suite ended, so a
		// failed run does not leave test data on the account.
		if (!isSignedIn()) {
			done.call(null);
			return;
		}

		var self:ngiotest.suites.LiveCloudSaveSuite = this;

		clearIfUsed(testSlot(), function():Void {
			self.clearIfUsed(self.altSlot(), function():Void {
				done.call(null);
			});
		});
	}

	//==================== HELPERS ====================
	//
	// Public because the closures above reach them through `self`.

	public function clearIfUsed(slot:io.newgrounds.models.objects.SaveSlot, next:Function):Void {
		if (slot == null || !slot.hasData()) {
			next.call(null);
			return;
		}

		slot.clearData(function(error):Void {
			next.call(null);
		}, null);
	}

	public function testSlot():io.newgrounds.models.objects.SaveSlot {
		return io.newgrounds.models.objects.SaveSlot(NGIO.getSaveSlot(ngiotest.TestConfig.TEST_SAVE_SLOT_ID));
	}

	public function altSlot():io.newgrounds.models.objects.SaveSlot {
		return io.newgrounds.models.objects.SaveSlot(NGIO.getSaveSlot(ngiotest.TestConfig.TEST_SAVE_SLOT_ID_ALT));
	}
}
