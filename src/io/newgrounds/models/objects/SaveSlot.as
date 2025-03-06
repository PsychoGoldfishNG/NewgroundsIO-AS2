/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
 * Contains information about a CloudSave slot.
 */
class io.newgrounds.models.objects.SaveSlot extends io.newgrounds.models.BaseObject {
	private var ___id:Number;
	private var ___size:Number;
	private var ___datetime:String;
	private var ___timestamp:Number;
	private var ___url:String;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function SaveSlot(props:Object) {
		super();
		this.__object = 'SaveSlot';
		this.__properties = this.__properties.concat(["id","size","datetime","timestamp","url"]);
		this.__required = [];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	 * The slot number.
	 */
	public function get id():Number {
		return this.___id;
	}

	/**
	 * @private
	 */
	public function set id(___id:Number) {
		this.___id = ___id;
	}
	/**
	 * The size of the save data in bytes.
	 */
	public function get size():Number {
		return this.___size;
	}

	/**
	 * @private
	 */
	public function set size(___size:Number) {
		this.___size = ___size;
	}
	/**
	 * A date and time (in ISO 8601 format) representing when this slot was last saved.
	 */
	public function get datetime():String {
		return this.___datetime;
	}

	/**
	 * @private
	 */
	public function set datetime(___datetime:String) {
		this.___datetime = ___datetime;
	}
	/**
	 * A unix timestamp representing when this slot was last saved.
	 */
	public function get timestamp():Number {
		return this.___timestamp;
	}

	/**
	 * @private
	 */
	public function set timestamp(___timestamp:Number) {
		this.___timestamp = ___timestamp;
	}
	/**
	 * The URL containing the actual save data for this slot, or null if this slot has no data.
	 */
	public function get url():String {
		return this.___url;
	}

	/**
	 * @private
	 */
	public function set url(___url:String) {
		this.___url = ___url;
	}

    public function hasData():Boolean
    {
        return this.url !== null;
    }

    public function clear(callback:Function, thisArg:Object) 
    {
        if (!this.getCore()) {
            throw new Error('Error in '+this.getFullClassName()+': You must attach a core with setCore() before executing clear().');
            return;
        }

        var component = new io.newgrounds.models.components.CloudSave.clearSlot({
            id: this.id
        });

        this.datetime = null;
        this.timestamp = null;
        this.size = null;
        this.url = null;

        this.getCore().executeComponent(component, callback, thisArg);
    }

    public function loadRaw(callback:Function, thisArg:Object)
    {
        if (!this.url) {
            if (thisArg === undefined) thisArg = this.getCore();
            callback.call(thisArg, null);
            return;
        }

        var loader:LoadVars = new LoadVars();

        loader.onData = function(data:String):Void
        {
            if (data === undefined) {
                trace("There was an error loading your save slot data.");
            }
            callback.call(thisArg, data);
        };

        loader.load(this.url);
    }

    public function setDataRaw(data:String, callback:Function, thisArg:Object)
    {
        if (!this.getCore()) {
            throw new Error('Error in '+this.getFullClassName()+': You must attach a core with setCore() before executing setData().');
            return;
        }

        var component = new io.newgrounds.models.components.CloudSave.setData({
            id: this.id,
            data: data
        });

        this.getCore().executeComponent(component, callback, thisArg);
    }

    public function load(callback:Function, thisArg:Object)
    {
        this.loadRaw(function(data:String):Void
        {
            var decoded = null;
            if (data) decoded = io.newgrounds.encoders.JSON.decode(data);
            callback.call(thisArg, decoded);

        }, this);
    }

    public function setData(data:Object, callback:Function, thisArg:Object)
    {
        this.setDataRaw(io.newgrounds.encoders.JSON.encode(data), callback, thisArg);
    }

}