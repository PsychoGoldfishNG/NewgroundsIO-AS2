/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the Event.logEvent component.
 */
class io.newgrounds.models.components.Event.logEvent extends io.newgrounds.models.BaseComponent 
{
    private var ___host:String;
		private var ___event_name:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function logEvent(props:Object) 
    {
		super();

		this.__object = "Event.logEvent";
		this.___host = null;
		this.___event_name = null;
		this.__properties = this.__properties.concat(["host","event_name"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = false;

		this.__castTypes = {};

        this.fillProperties(props);

	}


    /**
    * The domain hosting your app. Example: "newgrounds.com", "localHost"
    */
	public function get host():String {
		return this.___host;
	}

    /**
    * @private
    */
	public function set host(___host:String)
    {
        this.___host = ___host;
    }


    /**
    * The name of your custom event as defined in your Referrals & Events settings.
    */
	public function get event_name():String {
		return this.___event_name;
	}

    /**
    * @private
    */
	public function set event_name(___event_name:String)
    {
        this.___event_name = ___event_name;
    }


}

