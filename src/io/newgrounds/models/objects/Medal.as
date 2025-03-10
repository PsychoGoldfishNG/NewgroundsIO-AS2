/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
 * Contains information about a medal.
 */
class io.newgrounds.models.objects.Medal extends io.newgrounds.models.BaseObject {
	private var ___id:Number;
	private var ___name:String;
	private var ___description:String;
	private var ___icon:String;
	private var ___value:Number;
	private var ___difficulty:Number;
	private var ___secret:Boolean;
	private var ___unlocked:Boolean;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function Medal(props:Object) {
		super();
		this.__object = 'Medal';
		this.__properties = this.__properties.concat(["id","name","description","icon","value","difficulty","secret","unlocked"]);
		this.__required = [];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	 * The numeric ID of the medal.
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
	 * The name of the medal.
	 */
	public function get name():String {
		return this.___name;
	}

	/**
	 * @private
	 */
	public function set name(___name:String) {
		this.___name = ___name;
	}
	/**
	 * A short description of the medal.
	 */
	public function get description():String {
		return this.___description;
	}

	/**
	 * @private
	 */
	public function set description(___description:String) {
		this.___description = ___description;
	}
	/**
	 * The URL for the medal's icon.
	 */
	public function get icon():String {
		return this.___icon;
	}

	/**
	 * @private
	 */
	public function set icon(___icon:String) {
		this.___icon = ___icon;
	}
	/**
	 * The medal's point value.
	 */
	public function get value():Number {
		return this.___value;
	}

	/**
	 * @private
	 */
	public function set value(___value:Number) {
		this.___value = ___value;
	}
	/**
	 * The difficulty id of the medal.
	 */
	public function get difficulty():Number {
		return this.___difficulty;
	}

	/**
	 * @private
	 */
	public function set difficulty(___difficulty:Number) {
		this.___difficulty = ___difficulty;
	}
	public function get secret():Boolean {
		return this.___secret;
	}

	/**
	 * @private
	 */
	public function set secret(___secret:Boolean) {
		this.___secret = ___secret;
	}
	/**
	 * This will only be set if a valid user session exists.
	 */
	public function get unlocked():Boolean {
		return this.___unlocked;
	}

	/**
	 * @private
	 */
	public function set unlocked(___unlocked:Boolean) {
		this.___unlocked = ___unlocked;
	}

    public function unlock(callback:Function, thisArg:Object)
    {
        if (!this.getCore()) {
            throw new Error('Error in '+this.getFullClassName()+': You must attach a core with setCore() before executing unlock().');
            return;
        }

        var component = new io.newgrounds.models.components.Medal.unlock({
            id: this.id
        });

        var callbackParams = {callback: callback, thisArg: thisArg};
        this.getCore().executeComponent(component, onUnlock, this, callbackParams);
    }

    public function onUnlock(result:Object, callbackParams:Object):Void
    {
        if (result.success) {
            this.unlocked = true;
        }

        if (callbackParams.callback !== undefined) {
            callbackParams.callback.call(callbackParams.thisArg, result.medal, result.medal_score);
        }
    }

}