/**
 * LocalSaveSlotStore
 *
 * The local mirror of this app's save slots.
 *
 * A save slot is meant to be stored on the cloud, with a local copy protecting
 * it from network loss and server outages. This class owns that local copy and
 * nothing else: keys, App ID and owner scoping, the registry and payload split,
 * serialization, corrupt data handling, and datetime stamping. It knows nothing
 * about the cloud, about merging, or about which copy is newer. AppState decides
 * all of that, and is this class's only caller.
 *
 * Every method takes an `owner`: the id of the user the copy belongs to, or null
 * for a guest (nobody signed in). Each owner has its own keys, so on a shared
 * computer one player's save never overwrites or shows up as another's.
 *
 * Entries are plain objects, {size, datetime, hasData}, not SaveSlot models:
 * building models needs the object factory and a core, which is AppState's job.
 */
import io.newgrounds.encoders.JSON;
import io.newgrounds.helpers.DateTimeHelper;
import io.newgrounds.helpers.LocalStorageHelper;

class io.newgrounds.LocalSaveSlotStore {

	private var appId:String;

	/**
	 * Keys embed the App ID for the same reason the saved session id does: apps
	 * on the same host share their local storage, so an unqualified key would
	 * collide across every game using this library there.
	 */
	public function LocalSaveSlotStore(appId:String) {
		this.appId = appId;
	}

	private function keyPrefix(owner):String {
		var base:String = "ngio-local-save-slots-for-" + this.appId;
		return (owner === null || owner === undefined) ? base : base + ":user:" + owner;
	}

	private function registryKey(owner):String {
		return this.keyPrefix(owner) + ":registry";
	}

	private function payloadKey(id:Number, owner):String {
		return this.keyPrefix(owner) + ":slot:" + id;
	}

	/**
	 * Every local copy's metadata for one owner, as an object keyed by slot id.
	 * The registry and the payloads live under separate keys, matching the
	 * gateway's own split between CloudSave.loadSlots (metadata for every slot)
	 * and CloudSave.loadSlot (one slot's data), so writing one slot's data never
	 * rewrites every other slot's metadata.
	 *
	 * Unreadable stored data reads as an empty registry rather than failing, and
	 * the app carries on against the cloud.
	 */
	public function getRegistry(owner):Object {
		try {
			var raw:String = io.newgrounds.helpers.LocalStorageHelper.getValue(this.registryKey(owner));
			if (raw == null || raw == "") return {};
			var parsed = io.newgrounds.encoders.JSON.decode(raw);
			if (parsed == null || parsed == undefined || parsed instanceof Array || typeof(parsed) != "object") return {};
			return parsed;
		} catch (e) {
		}
		return {};
	}

	/** One slot's local metadata, or null if it has no local copy. */
	public function getEntry(id:Number, owner):Object {
		var entry = this.getRegistry(owner)[String(id)];
		return (entry == undefined || entry == null) ? null : entry;
	}

	/** One slot's local save data, or null if it has no local copy. */
	public function getPayload(id:Number, owner):String {
		try {
			return io.newgrounds.helpers.LocalStorageHelper.getValue(this.payloadKey(id, owner));
		} catch (e) {
		}
		return null;
	}

	/**
	 * Stores one slot's local copy, stamped with `datetime` so the merge can
	 * compare it with the cloud's. Defaults to now, which is what a fresh save
	 * wants. Caching a cloud load passes the cloud's own datetime instead, so
	 * caching a slot never makes it look newer than it is.
	 *
	 * Returns false rather than throwing when the write fails: a failed local
	 * write is one leg of a save for the caller to weigh against the cloud leg.
	 *
	 * The payload is written before the registry, so a failed payload write
	 * doesn't leave the registry claiming data that was never stored.
	 */
	public function writeEntry(id:Number, data:String, owner, datetime:String):Boolean {
		if (datetime == undefined || datetime == null) datetime = io.newgrounds.helpers.DateTimeHelper.nowIso();
		try {
			if (!io.newgrounds.helpers.LocalStorageHelper.setValue(this.payloadKey(id, owner), data)) return false;
			var registry:Object = this.getRegistry(owner);
			registry[String(id)] = {size: data.length, datetime: datetime, hasData: true};
			return io.newgrounds.helpers.LocalStorageHelper.setValue(this.registryKey(owner), io.newgrounds.encoders.JSON.encode(registry));
		} catch (e) {
		}
		return false;
	}

	/**
	 * Drops one slot's local copy. Registry first: the payload is the bigger
	 * write, and a payload with no registry entry reads as absent anyway.
	 */
	public function deleteEntry(id:Number, owner):Boolean {
		try {
			var registry:Object = this.getRegistry(owner);
			delete registry[String(id)];
			if (!io.newgrounds.helpers.LocalStorageHelper.setValue(this.registryKey(owner), io.newgrounds.encoders.JSON.encode(registry))) return false;
			io.newgrounds.helpers.LocalStorageHelper.removeValue(this.payloadKey(id, owner));
			return true;
		} catch (e) {
		}
		return false;
	}
}
