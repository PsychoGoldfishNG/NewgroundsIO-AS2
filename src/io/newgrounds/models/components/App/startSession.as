/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the App.startSession component.
 */
class io.newgrounds.models.components.App.startSession extends io.newgrounds.models.BaseComponent 
{
    private var ___force:Boolean;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function startSession(props:Object) 
    {
		super();

		this.__object = "App.startSession";
		this.___force = null;
		this.__properties = this.__properties.concat(["force"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = false;

		this.__castTypes = {};

        this.fillProperties(props);

	}


    /**
    * If true, will create a new session even if the user already has an existing one.
	 *        Note: Any previous session ids will no longer be valid if this is used.
    */
	public function get force():Boolean {
		return this.___force;
	}

    /**
    * @private
    */
	public function set force(___force:Boolean)
    {
        this.___force = ___force;
    }


}

