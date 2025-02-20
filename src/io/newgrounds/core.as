/** ActionScript 2.0 */

/**
* This is the core class for the Newgrounds.io API.  It handles sending and receiving data from the Newgrounds.io servers.
*/
class io.newgrounds.core
{
    private static var GATEWAY_URL = "https://www.newgrounds.io/gateway_v3.php";

    private var _appId:String;
    private var __baseAppId:String;
    private var _encryptionKey:String;
    private var _debug:Boolean;
    private var _queue:Array;
    private var _session:io.newgrounds.models.objects.Session;

    /**
    * Constructor
    * @param appId The application id for your game
    * @param encryptionKey The encryption key for your game
    * @param debug A boolean value indicating whether or not to operate in debug mode
    */
    public function core(appId:String, encryptionKey:String, debug:Boolean)
    {
        this._appId = appId;
        this.__baseAppId = String(appId).split(":")[0];
        this._encryptionKey = encryptionKey;
        this._debug = debug ? true : false;
        this._queue = [];
        this._session = new io.newgrounds.models.objects.Session();
        if (_root.ngio_session_id !== undefined) {
            this._session.id = _root.ngio_session_id;
        } else {
            var so = SharedObject.getLocal("ngio_session_app_id_"+this.__baseAppId);
            if (so.data.id !== undefined) {
                this._session.id = so.data.id;
            }
        }
    }

    public function get session():io.newgrounds.models.objects.Session
    {
        return this._session;
    }

    public function setSession(session:io.newgrounds.models.objects.Session):Void
    {
        this._session = session;
    }

    public function saveSession():Void
    {
        if (this.session.id !== undefined) {
            var so = SharedObject.getLocal("ngio_session_app_id_"+this.__baseAppId);
            so.data.id = this.session.id;
            so.flush();
        }
    }

    /**
    * Converts an object to a JSON string and encrypts it
    * @param obj The data to encrypt
    * @return The encrypted data
    */
    public function encrypt(obj):String
    {
        var json = io.newgrounds.encoders.JSON.encode(obj);
        var encrypted = io.newgrounds.encoders.RC4.encrypt(json, this._encryptionKey);
        return encrypted;
    }

    /**
    * Adds a component to the request queue
    * @param component The component to add to the queue
    */
    public function queueComponent(component:io.newgrounds.models.BaseComponent):Void
    {
        // attach reference to core so it can pull our app/session ids and encryption info
        component.attachCore(this);

        try {
            if (!component.hasValidProperties()) {
                throw new Error(component.getValidationErrors().join("\n"));
                return;
            }
            this._queue.push(component);
        }
        catch (err) {
            trace("Error queuing component:\n"+err);
        }
    }

    /**
    * Executes the request queue
    * @param callback The function to call when the request is complete
    * @param thisArg The object to use as 'this' when calling the callback
    * @param callbackParams An object to pass to the callback function
    */
    public function executeQueue(callback:Function, thisArg:Object, callbackParams:Object):Void
    {
        // if the queue is empty, do nothing
        if (this._queue.length === 0) {
            return;
        }

        // process the queue and split up any redirects from pure API calls
        try {

            // API calls will get stored here
            var executes = [];

            // get the queue and reset the array property so it's clean for new items
            var queue = this._queue;
            this._queue = [];

            // loop through the queue
            var execute;
            for(var i=0; i<queue.length; i++) {

                // if we find a redirect, excecute it directly so it opens in a new window
                if (queue[i].isRedirect && queue[i].redirect !== false) {
                    this.executeComponent(queue[i], callback, thisArg, callbackParams);
                    continue;
                }

                // everything else need to be bundled in an execute object
                execute = new io.newgrounds.models.objects.Execute();
                execute.setComponent(queue[i]);
                executes.push(execute);

                // make sure it's valid
                if (!execute.hasValidProperties()) {
                    throw new Error(execute.getValidationErrors().join("\n"));
                    return;
                }
            }

            // if all we had was reditects, we can fire the callback now and return
            if (executes.length === 0) {
                this.doCallback(callback, thisArg, callbackParams);
                return;
            }

            // otherwise, we send off an API request
            this.sendRequest(executes, callback, thisArg, callbackParams);
        }
        catch (err) {
            trace(err);
        }
    }

    /**
    * Executes a single component
    * @param component The component to execute
    * @param callback The function to call when the request is complete
    * @param thisArg The object to use as 'this' when calling the callback
    * @param callbackParams An object to pass to the callback function
    */
    public function executeComponent(component:io.newgrounds.models.BaseComponent, callback:Function, thisArg:Object, callbackParams:Object):Void
    {
        // attach reference to core so it can pull our app/session ids and encryption info
        component.attachCore(this);

        try {

            // make sure the component is set up properly
            if (!component.hasValidProperties()) {
                trace('component failed');
                throw new Error(component.getValidationErrors().join("\n"));
                return;
            }

            // wrap it in an execute object and vlidate that as well
            var execute = new io.newgrounds.models.objects.Execute();
            execute.setComponent(component);
            
            if (!execute.hasValidProperties()) {
                trace('execute failed');
                throw new Error(execute.getValidationErrors().join("\n"));
                return;
            }

            // send the API request
            this.sendRequest(execute, callback, thisArg, callbackParams, component.isRedirect && component['redirect'] !== false);
        }
        catch (err) {
            trace("Error execute component:\n"+err);
        }
    }

    /**
    * Sends a request to the Newgrounds.io servers
    * @param execute The execute object to send
    * @param callback The function to call when the request is complete
    * @param thisArg The object to use as 'this' when calling the callback
    * @param callbackParams An object to pass to the callback function
    * @param isRedirect A boolean value indicating whether or not this is a redirect request
    */
    private function sendRequest(execute, callback:Function, thisArg:Object, callbackParams:Object, isRedirect:Boolean):Void
    {
        // wrap everything in a request object
        var request = new io.newgrounds.models.objects.Request({
            app_id: this._appId,
            session_id: this._session.id,
            execute: execute
        });

        // if we're in debug mode, set the request to debug
        if (this._debug) {
            request.debug = true;
        }

        // make sure the request is valid
        if (!request.hasValidProperties()) {
            throw new Error(request.getValidationErrors().join("\n"));
            return;
        }

        // convert everything to a json string the server can use (will auto-encrypt components as needed)
        var request = request.toJsonString();

        // if it's a redirect, just open a new window and return
        if (isRedirect) {
            request = escape(request);

            var url = GATEWAY_URL + '?request=' + request;

            if (this._debug) {
                trace("Newgrounds.io - Loading URL: "+url);
            }

            getURL(url, "_blank");
            this.doCallback(callback, thisArg, request, callbackParams);

        // otherwise, send this to the API and wait for a response
        } else {

            // this object will send the request to the server
            var loader:LoadVars = new LoadVars();

            // attach the json request to the loader
            loader.request = request;

            if (this._debug) {
                trace("Newgrounds.io - Client request:");
                trace(request+"\n");
            }

            // this object will handle the server's response
            var results:LoadVars = new LoadVars();

            // add a reference to the core so we can process the results
            var core = this;

            // set up what to do when we get a response from the server
            results.onData = function(data:String):Void
            {
                // if we're in debug mode, trace the server's raw response
                if (core._debug) {
                    trace("Newgrounds.io - Server response:");
                    trace(data+"\n");
                }

                // decode the results and put them in a response object (this will create the appropriate result model)
                var obj = io.newgrounds.encoders.JSON.decode(data);
                var response = new io.newgrounds.models.objects.Response(obj);

                var result = null;
                if (response.success === false) {
                    result = response;
                } else {
                    result = response.result;
                }

                core.doCallback(callback, thisArg, response, callbackParams);
            }

            // send the request to the server
            loader.sendAndLoad(GATEWAY_URL, results, "POST");
        }
    }

    /**
    * check callback params, and if valid, execute the callback
    * @param callback The function to call when the request is complete
    * @param thisArg The object to use as 'this' when calling the callback
    * @param response The response object to pass to the callback
    * @param callbackParams An object to pass to the callback function
    */
    public function doCallback(callback:Function, thisArg:Object, response, callbackParams):Void
    {
        if (typeof(callback) === "function") {
            if (thisArg === undefined) {
                thisArg = this;
            }

            var result = null;
            if (response) {
                if (response.success === false) {
                    result = response;
                } else {
                    result = response.result;
                }
            }

            callback.call(thisArg, result, callbackParams);
        }
    }
}