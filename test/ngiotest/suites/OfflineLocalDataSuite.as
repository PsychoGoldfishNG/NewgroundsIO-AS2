/**
 * OfflineLocalDataSuite
 *
 * What the library keeps on this computer: medal unlocks still waiting on the
 * gateway (MedalUnlockQueue), and the local copies of save slots (AppState's
 * save slot local fallback and the SaveSlot methods built on it).
 *
 * Nothing here touches the network or the real SharedObject. Storage goes to an
 * in-memory store through LocalStorageHelper.store, and the gateway is replaced
 * by Core.requestHandler, which answers each request with whatever the test
 * says.
 *
 * Helpers are public, and everything inside the test closures is fully
 * qualified, because AS2 can't resolve private members or unqualified statics
 * from inside a nested function.
 */
import io.newgrounds.Core;
import io.newgrounds.Errors;
import io.newgrounds.encoders.JSON;
import io.newgrounds.helpers.DateTimeHelper;
import io.newgrounds.helpers.LocalStorageHelper;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.models.objects.User;

import ngiotest.TestConfig;
import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineLocalDataSuite extends ngiotest.TestSuite {

	/** Not the real test app, so nothing here can collide with live data */
	public static var APP_ID:String = "11111:OfflineTest";

	public static var CLOUD_TIME:String = "2026-08-20T14:32:00-04:00";
	public static var NEWER_TIME:String = "2026-08-21T00:00:00.000Z";
	public static var OLDER_TIME:String = "2020-01-01T00:00:00.000Z";

	/** The in-memory store, as key -> value */
	public var memory:Object;

	public function OfflineLocalDataSuite() {
		super();
		this.memory = {};
	}

	public function getSuiteName():String {
		return "Offline / Local data";
	}

	public function setUp(done:Function):Void {
		this.resetStore();
		done.call(null);
	}

	public function tearDown(done:Function):Void {
		io.newgrounds.helpers.LocalStorageHelper.store = null;
		done.call(null);
	}

	public function build():Void {

		var self = this;
		var appId:String = ngiotest.suites.OfflineLocalDataSuite.APP_ID;
		var cloudTime:String = ngiotest.suites.OfflineLocalDataSuite.CLOUD_TIME;
		var newerTime:String = ngiotest.suites.OfflineLocalDataSuite.NEWER_TIME;
		var olderTime:String = ngiotest.suites.OfflineLocalDataSuite.OLDER_TIME;

		//==================== DATES ====================

		add("parses an ISO 8601 datetime with any offset", function(t:ngiotest.TestContext):Void {
			var utc:Number = io.newgrounds.helpers.DateTimeHelper.parseIso("2026-08-25T21:42:42Z");
			t.assertEquals(Date.UTC(2026, 7, 25, 21, 42, 42, 0), utc, "Z");
			t.assertEquals(utc, io.newgrounds.helpers.DateTimeHelper.parseIso("2026-08-25T17:42:42-04:00"), "a negative offset is the same moment");
			t.assertEquals(utc, io.newgrounds.helpers.DateTimeHelper.parseIso("2026-08-25T23:42:42+02:00"), "a positive offset is the same moment");
			t.assertEquals(utc + 500, io.newgrounds.helpers.DateTimeHelper.parseIso("2026-08-25T21:42:42.5Z"), "fractions of a second");
			t.assertTrue(isNaN(io.newgrounds.helpers.DateTimeHelper.parseIso("not a date")), "junk is NaN");
			t.assertTrue(isNaN(io.newgrounds.helpers.DateTimeHelper.parseIso(null)), "null is NaN");
			// Leading zeros must not be read as octal
			t.assertEquals(Date.UTC(2026, 8, 9, 8, 9, 0, 0), io.newgrounds.helpers.DateTimeHelper.parseIso("2026-09-09T08:09:00Z"), "08 and 09 read as decimal");
			t.done();
		});

		add("writes UTC datetimes that read back", function(t:ngiotest.TestContext):Void {
			var time:Number = Date.UTC(2026, 0, 2, 3, 4, 5, 6);
			t.assertEquals("2026-01-02T03:04:05.006Z", io.newgrounds.helpers.DateTimeHelper.toIso(time), "formatted");
			t.assertEquals(time, io.newgrounds.helpers.DateTimeHelper.parseIso(io.newgrounds.helpers.DateTimeHelper.toIso(time)), "round trip");
			t.done();
		});

		//==================== MEDAL UNLOCK QUEUE ====================

		add("records an unlock before sending it", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.requestHandler = function(request:String, respond:Function):Void {
				// Never answered: the connection dropped
			};
			core.medalUnlockQueue.unlock([5], null, null);
			t.assertEquals("5", core.medalUnlockQueue.getPendingIds().join(","), "buffered");
			t.done();
		});

		add("drops an unlock the gateway accepted", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			self.answerAll(core, self.unlockReply(true, 0));
			core.medalUnlockQueue.unlock([5], function(outcomes:Array):Void {
				t.assertNull(outcomes[0].error, "no error");
				t.assertNotNull(outcomes[0].medal, "the medal");
				t.assertEquals(0, core.medalUnlockQueue.getPendingIds().length, "no longer buffered");
				t.done();
			}, null);
		});

		add("drops an unlock the gateway rejected for that medal", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			self.answerAll(core, self.unlockReply(false, io.newgrounds.Errors.INVALID_MEDAL_ID));
			core.medalUnlockQueue.unlock([5], function(outcomes:Array):Void {
				t.assertEquals(io.newgrounds.Errors.INVALID_MEDAL_ID, outcomes[0].error.code, "the gateway's error");
				t.assertEquals(0, core.medalUnlockQueue.getPendingIds().length, "never retried");
				t.done();
			}, null);
		});

		add("keeps an unlock blocked on the session", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			self.answerAll(core, self.unlockReply(false, io.newgrounds.Errors.EXPIRED_SESSION));
			core.medalUnlockQueue.unlock([5], function(outcomes:Array):Void {
				t.assertNotNull(outcomes[0].error, "an error");
				t.assertEquals("5", core.medalUnlockQueue.getPendingIds().join(","), "kept for a retry");
				t.done();
			}, null);
		});

		add("keeps an unlock that got no answer", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			core.medalUnlockQueue.unlock([5], function(outcomes:Array):Void {
				t.assertNotNull(outcomes[0].error, "an error");
				t.assertEquals("5", core.medalUnlockQueue.getPendingIds().join(","), "kept for a retry");
				t.done();
			}, null);
		});

		add("never sends one player's unlock for another", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = io.newgrounds.encoders.JSON.encode([{id: 5, user: 2}]);
			var core:io.newgrounds.Core = self.signedInCore(1);
			var sent:Number = 0;
			core.requestHandler = function(request:String, respond:Function):Void {
				sent++;
			};
			core.medalUnlockQueue.retryPending();
			t.assertEquals(0, sent, "nothing sent");
			t.assertEquals("5", core.medalUnlockQueue.getPendingIds().join(","), "still waiting for player 2");
			t.done();
		});

		add("sends a guest unlock for whoever signs in, and settles it", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			// An entry from before unlocks recorded their player reads as a guest's
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = "[5]";
			var core:io.newgrounds.Core = self.signedInCore(1);
			self.answerAll(core, self.unlockReply(true, 0));
			core.medalUnlockQueue.retryPending();
			t.assertEquals(0, core.medalUnlockQueue.getPendingIds().length, "settled for player 1");
			t.done();
		});

		add("doesn't keep a guest unlock when keepGuestUnlocks is off", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = new io.newgrounds.Core(appId, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			core.appState.session.id = "guest-session";
			core.medalUnlockQueue.keepGuestUnlocks = false;
			core.medalUnlockQueue.unlock([5], function(outcomes:Array):Void {
				t.assertEquals(io.newgrounds.Errors.LOGIN_REQUIRED, outcomes[0].error.code, "refused: nobody signed in");
				t.assertEquals(0, core.medalUnlockQueue.getPendingIds().length, "not kept");
				t.done();
			}, null);
		});

		add("holds guest unlocks on a retry pass when holdGuestUnlocks is on", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = io.newgrounds.encoders.JSON.encode([{id: 5, user: null}, {id: 6, user: 1}]);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.medalUnlockQueue.holdGuestUnlocks = true;
			var sent:Number = 0;
			var reply:String = self.unlockReply(true, 0);
			core.requestHandler = function(request:String, respond:Function):Void {
				sent++;
				respond(200, reply);
			};
			core.medalUnlockQueue.retryPending();
			t.assertEquals(1, sent, "only the player's own entry was sent");
			t.assertEquals("5", core.medalUnlockQueue.getGuestIds().join(","), "the guest entry still waits");
			t.done();
		});

		add("claims guest unlocks for the signed-in player", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = io.newgrounds.encoders.JSON.encode([{id: 5, user: null}, {id: 9, user: null}]);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.medalUnlockQueue.holdGuestUnlocks = true;
			self.answerAll(core, self.unlockReply(true, 0));
			core.medalUnlockQueue.claimGuestUnlocks([5, 77], function(outcomes:Array):Void {
				t.assertEquals(1, outcomes.length, "77 had no guest entry");
				t.assertEquals(5, outcomes[0].id, "5 was claimed");
				t.assertEquals("9", core.medalUnlockQueue.getPendingIds().join(","), "only 9 is left");
				t.done();
			}, null);
		});

		add("keeps a claimed unlock as the player's own when it can't be sent yet", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = io.newgrounds.encoders.JSON.encode([{id: 5, user: null}]);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.medalUnlockQueue.holdGuestUnlocks = true;
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			core.medalUnlockQueue.claimGuestUnlocks([5], function(outcomes:Array):Void {
				t.assertEquals(0, core.medalUnlockQueue.getGuestIds().length, "no longer a guest entry");
				t.assertEquals("5", core.medalUnlockQueue.getPendingIds().join(","), "still pending, as player 1's");
				t.done();
			}, null);
		});

		add("claims nothing with nobody signed in", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = io.newgrounds.encoders.JSON.encode([{id: 5, user: null}]);
			var core:io.newgrounds.Core = new io.newgrounds.Core(appId, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			core.medalUnlockQueue.claimGuestUnlocks([5], function(outcomes:Array):Void {
				t.assertEquals(0, outcomes.length, "nothing claimed");
				t.assertEquals("5", core.medalUnlockQueue.getGuestIds().join(","), "still a guest entry");
				t.done();
			}, null);
		});

		add("discards guest unlocks and leaves players' own", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.memory["ngio-pending-medal-unlocks-for-" + appId] = io.newgrounds.encoders.JSON.encode([{id: 5, user: null}, {id: 5, user: 2}, {id: 6, user: null}]);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.medalUnlockQueue.discardGuestUnlocks([5]);
			t.assertEquals("6", core.medalUnlockQueue.getGuestIds().join(","), "only 6 is left as a guest entry");
			t.assertEquals("5,6", core.medalUnlockQueue.getPendingIds().join(","), "player 2's 5 is untouched");
			t.done();
		});

		add("Medal.unlock() marks the medal unlocked only when the gateway accepts it", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			var medal = io.newgrounds.models.objects.ObjectFactory.CreateObject("Medal", {id: 5, name: "Test"}, core);
			self.answerAll(core, self.unlockReply(false, io.newgrounds.Errors.EXPIRED_SESSION));
			medal.unlock(function(sameMedal, error):Void {
				t.assert(sameMedal === medal, "called back with the same medal");
				t.assertNotNull(error, "refused");
				t.assertFalse(medal.unlocked, "not marked unlocked");

				self.answerAll(core, self.unlockReply(true, 0));
				medal.unlock(function(sameMedal2, error2):Void {
					t.assertNull(error2, "accepted");
					t.assertTrue(medal.unlocked, "marked unlocked");
					t.done();
				}, null);
			}, null);
		});

		//==================== SAVE SLOTS: WHOSE COPY ====================

		add("lists guest copies when signed out", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(2, "guest-save", newerTime, null);
			var core:io.newgrounds.Core = new io.newgrounds.Core(appId, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			var sent:Number = 0;
			core.requestHandler = function(request:String, respond:Function):Void {
				sent++;
			};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				t.assertNotNull(error, "still reports that the cloud list didn't load");
				t.assertEquals(0, sent, "refused without being sent");
				var slot = self.slotById(core, 2);
				if (t.assertNotNull(slot, "the guest copy is listed")) {
					t.assertEquals("local", slot.source, "local");
					t.assertTrue(slot.hasData(), "holds data");
				}
				t.done();
			}, null);
		});

		add("lists the player's own copies when the request can't reach the gateway", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "offline-save", newerTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				t.assertNotNull(error, "an error");
				var slot = self.slotById(core, 3);
				if (t.assertNotNull(slot, "listed")) {
					t.assertEquals("local", slot.source, "local");
				}
				t.done();
			}, null);
		});

		add("gives a fresh guest saveSlotCount empty slots to save into", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = new io.newgrounds.Core(appId, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			core.requestHandler = function(request:String, respond:Function):Void {};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				t.assertEquals(3, core.appState.saveSlots.length, "three slots by default");
				for (var i:Number = 0; i < core.appState.saveSlots.length; i++) {
					var slot = core.appState.saveSlots[i];
					t.assertEquals("local", slot.source, "slot " + slot.id + " describes the local copy");
					t.assertFalse(slot.hasData(), "slot " + slot.id + " is empty");
				}
				t.assertTrue(core.appState.hasLoaded("saveSlots"), "marked loaded");
				t.done();
			}, null);
		});

		add("lists as many empty slots as saveSlotCount says, around a guest copy", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(4, "guest-save", newerTime, null);
			var core:io.newgrounds.Core = new io.newgrounds.Core(appId, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
			core.appState.saveSlotCount = 10;
			core.requestHandler = function(request:String, respond:Function):Void {};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				t.assertEquals(10, core.appState.saveSlots.length, "ten slots");
				t.assertEquals(4, core.appState.saveSlots[3].id, "kept in id order");
				t.assertTrue(self.slotById(core, 4).hasData(), "the guest copy is still there");
				t.assertFalse(self.slotById(core, 5).hasData(), "the rest are empty");
				t.done();
			}, null);
		});

		add("fills the empty slots in place once the cloud list arrives", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				var placeholder = self.slotById(core, 2);
				core.appState.applySlotListResult([self.cloudSlot(core, 1, null), self.cloudSlot(core, 2, cloudTime), self.cloudSlot(core, 3, null)]);
				t.assertTrue(self.slotById(core, 2) === placeholder, "the same slot");
				t.assertEquals("cloud", placeholder.source, "now the cloud copy");
				t.assertTrue(placeholder.hasData(), "holds the cloud save");
				t.done();
			}, null);
		});

		add("never shows one player's local copy to another", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(1, "player-two-save", newerTime, 2);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 1, null)]);
			t.assertEquals("cloud", self.slotById(core, 1).source, "only the cloud copy");
			t.assertFalse(self.slotById(core, 1).hasData(), "empty");
			t.assertEquals("player-two-save", self.memory[self.localKey(2) + ":slot:1"], "still there for player 2");
			t.done();
		});

		add("gives a guest copy to the next player who signs in, and only to them", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(2, "guest-save", newerTime, null);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 2, null)]);
			t.assertEquals("local", self.slotById(core, 2).source, "player 1 gets it");
			t.assertEquals("guest-save", self.memory[self.localKey(1) + ":slot:2"], "moved to player 1");
			t.assertNull(self.memory[self.localKey(null) + ":slot:2"], "gone from the guest copies");
			t.done();
		});

		add("keeps guest copies to guests when offerGuestSaves is off", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(2, "guest-save", newerTime, null);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.offerGuestSaves = false;
			core.appState.applySlotListResult([self.cloudSlot(core, 2, null)]);
			t.assertFalse(self.slotById(core, 2).hasData(), "player 1 doesn't get it");
			t.assertEquals("guest-save", self.memory[self.localKey(null) + ":slot:2"], "still a guest copy");
			t.done();
		});

		add("signing out resets a slot's source", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "local", newerTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 3, null)]);
			t.assertEquals("local", self.slotById(core, 3).source, "local while signed in");
			core.appState.clearSession();
			t.assertEquals("cloud", self.slotById(core, 3).source, "reset");
			t.assertEquals("local", self.memory[self.localKey(1) + ":slot:3"], "the copy is kept for player 1");
			t.done();
		});

		//==================== SAVE SLOTS: CONFLICTS ====================

		add("a newer local copy over a cloud save is a conflict", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "offline-save", newerTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 3, cloudTime)]);
			var slot = self.slotById(core, 3);
			t.assertEquals("conflict", slot.source, "conflict");
			t.assertEquals(cloudTime, slot.datetime, "the slot describes the cloud copy");
			var local = slot.getLocalCopy();
			if (t.assertNotNull(local, "the local copy is described")) {
				t.assertEquals(newerTime, local.datetime, "local datetime");
			}
			t.done();
		});

		add("an older local copy loses to the cloud, across time zones", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			// 14:32 at -04:00 is 18:32Z, so 18:00Z is older
			self.seedLocal(3, "older", "2026-08-20T18:00:00.000Z", 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 3, cloudTime)]);
			t.assertEquals("cloud", self.slotById(core, 3).source, "cloud");
			t.done();
		});

		add("keepCloud() drops the local copy without sending anything", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "offline-save", newerTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			var sent:Number = 0;
			core.requestHandler = function(request:String, respond:Function):Void {
				sent++;
			};
			core.appState.applySlotListResult([self.cloudSlot(core, 3, cloudTime)]);
			t.assertTrue(self.slotById(core, 3).keepCloud(), "dropped");
			t.assertEquals("cloud", self.slotById(core, 3).source, "cloud");
			t.assertNull(self.memory[self.localKey(1) + ":slot:3"], "the local copy is gone");
			t.assertEquals(0, sent, "nothing sent");
			t.done();
		});

		add("keepLocal() and keepCloud() change nothing without a conflict", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "local-only", newerTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 3, null)]);
			var slot = self.slotById(core, 3);
			t.assertFalse(slot.keepCloud(), "keepCloud refused");
			slot.keepLocal(function(error):Void {
				t.assertNotNull(error, "keepLocal refused");
				t.assertEquals("local-only", self.memory[self.localKey(1) + ":slot:3"], "untouched");
				t.done();
			}, null);
		});

		add("still finds a conflict on an offline reload", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 3, cloudTime)]);
			self.seedLocal(3, "offline-save", newerTime, 1);
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				t.assertEquals("conflict", self.slotById(core, 3).source, "conflict");
				t.done();
			}, null);
		});

		add("an offline reload doesn't let an older local copy replace a known cloud copy", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "older", olderTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 3, cloudTime)]);
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			core.appState.loadData(["saveSlots"], function(appState, error):Void {
				t.assertEquals("cloud", self.slotById(core, 3).source, "still cloud");
				t.assertEquals(cloudTime, self.slotById(core, 3).datetime, "still the cloud copy");
				t.done();
			}, null);
		});

		//==================== SAVE SLOTS: WRITING ====================

		add("a save that only reaches the local copy still succeeds", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 1, null)]);
			core.requestHandler = function(request:String, respond:Function):Void {
				respond(0, null);
			};
			self.slotById(core, 1).saveDataRaw("offline-payload", function(error):Void {
				t.assertNull(error, "reported as saved");
				t.assertEquals("local", self.slotById(core, 1).source, "flagged as local");
				t.assertEquals("offline-payload", self.memory[self.localKey(1) + ":slot:1"], "in the player's own copies");
				t.done();
			}, null);
		});

		add("a save the cloud accepted is stamped with the cloud's datetime", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			var core:io.newgrounds.Core = self.signedInCore(1);
			core.appState.applySlotListResult([self.cloudSlot(core, 1, null)]);
			self.answerAll(core, io.newgrounds.encoders.JSON.encode({
				success: true,
				app_id: appId,
				result: {component: "CloudSave.setData", data: {success: true, slot: self.cloudSlotData(1, cloudTime)}}
			}));
			self.slotById(core, 1).saveDataRaw("synced", function(error):Void {
				t.assertNull(error, "saved");
				t.assertEquals("cloud", self.slotById(core, 1).source, "cloud");
				var registry = io.newgrounds.encoders.JSON.decode(self.memory[self.localKey(1) + ":registry"]);
				t.assertEquals(cloudTime, registry["1"].datetime, "the cloud's datetime, not this computer's");
				t.done();
			}, null);
		});

		add("a slot from another app never reads this app's local copy", function(t:ngiotest.TestContext):Void {
			self.resetStore();
			self.seedLocal(3, "this app's save", newerTime, 1);
			var core:io.newgrounds.Core = self.signedInCore(1);
			var foreign = io.newgrounds.models.objects.ObjectFactory.CreateObject("SaveSlot", self.cloudSlotData(3, cloudTime), core);
			foreign.foreignAppId = ngiotest.TestConfig.READABLE_FOREIGN_APP_ID;
			foreign.source = "conflict";
			t.assertNull(foreign.getLocalCopy(), "no local copy");
			t.assertFalse(foreign.keepCloud(), "nothing to drop");
			t.done();
		});
	}

	//==================== HELPERS ====================

	public function resetStore():Void {
		this.memory = {};
		var self = this;
		io.newgrounds.helpers.LocalStorageHelper.store = {
			getValue: function(key:String):String {
				return (self.memory[key] != undefined) ? self.memory[key] : null;
			},
			setValue: function(key:String, value:String):Boolean {
				self.memory[key] = value;
				return true;
			},
			removeValue: function(key:String):Boolean {
				delete self.memory[key];
				return true;
			}
		};
	}

	public function signedInCore(userId:Number):io.newgrounds.Core {
		var core:io.newgrounds.Core = new io.newgrounds.Core(ngiotest.suites.OfflineLocalDataSuite.APP_ID, ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
		core.appState.session.id = "session-" + userId;
		var user:io.newgrounds.models.objects.User = new io.newgrounds.models.objects.User();
		user.id = userId;
		user.name = "Player " + userId;
		core.appState.session.user = user;
		return core;
	}

	/** Answers every request with the same JSON */
	public function answerAll(core:io.newgrounds.Core, json:String):Void {
		core.requestHandler = function(request:String, respond:Function):Void {
			respond(200, json);
		};
	}

	public function unlockReply(success:Boolean, errorCode:Number):String {
		var data:Object = success
			? {success: true, medal: {id: 5, name: "Test", unlocked: true}, medal_score: 10}
			: {success: false, error: {code: errorCode, message: "Refused"}};
		return io.newgrounds.encoders.JSON.encode({
			success: true,
			app_id: ngiotest.suites.OfflineLocalDataSuite.APP_ID,
			result: {component: "Medal.unlock", data: data}
		});
	}

	public function localKey(owner):String {
		var base:String = "ngio-local-save-slots-for-" + ngiotest.suites.OfflineLocalDataSuite.APP_ID;
		return (owner === null) ? base : base + ":user:" + owner;
	}

	/** Writes a local copy the way LocalSaveSlotStore would */
	public function seedLocal(id:Number, data:String, datetime:String, owner):Void {
		var key:String = this.localKey(owner);
		var registry = (this.memory[key + ":registry"] != undefined)
			? io.newgrounds.encoders.JSON.decode(this.memory[key + ":registry"])
			: {};
		registry[String(id)] = {size: data.length, datetime: datetime, hasData: true};
		this.memory[key + ":slot:" + id] = data;
		this.memory[key + ":registry"] = io.newgrounds.encoders.JSON.encode(registry);
	}

	public function cloudSlotData(id:Number, datetime:String):Object {
		return {
			id: id,
			size: (datetime == null) ? 0 : 100,
			datetime: datetime,
			timestamp: (datetime == null) ? 0 : Math.floor(io.newgrounds.helpers.DateTimeHelper.parseIso(datetime) / 1000),
			url: (datetime == null) ? null : "https://example.com/slot" + id + ".dat"
		};
	}

	public function cloudSlot(core:io.newgrounds.Core, id:Number, datetime:String) {
		return io.newgrounds.models.objects.ObjectFactory.CreateObject("SaveSlot", this.cloudSlotData(id, datetime), core);
	}

	public function slotById(core:io.newgrounds.Core, id:Number) {
		var slots:Array = core.appState.saveSlots;
		if (slots == null) return null;
		for (var i:Number = 0; i < slots.length; i++) {
			if (slots[i].id == id) return slots[i];
		}
		return null;
	}
}
