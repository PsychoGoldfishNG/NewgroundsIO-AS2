/** ActionScript 2.0 */

/**
* This is the core class for the Newgrounds.io API.  It handles sending and receiving data from the Newgrounds.io servers.
*/
class io.newgrounds.core
{
    private static var GATEWAY_URL = "https://www.newgrounds.io/gateway_v3.php";

    /**
    * Returns the name of the host server, ocalhost if it's running locally, or N/A if the host is unknown
    * @return The name of the host server
    */
    public static function getHost():String
    {
        // if it starts with "file" or a slash it's running locally
        if (String(_root._url).toLowerCase().indexOf("file") === 0 || String(_root._url).toLowerCase().indexOf("/") === 0 || String(_root._url).toLowerCase().indexOf("\\") === 0) {
            return "localhost";
        } else if (String(_root._url).indexOf("http") !== 0) {
            return "N/A";
        }

        return _root._url.split("://").pop().split("/")[0];
    }

    private var _appId:String;
    private var _baseAppId:String;
    private var _encryptionKey:String;
    private var _debug:Boolean;
    private var _queue:Array;
    private var _session:io.newgrounds.models.objects.Session;
    
    private var _currentVersion:String = null;
    private var _clientDeprecated:Boolean  = null;
    private var _hostApproved:Boolean = null;
    private var _saveSlots:Array = null;
    private var _medals:Array = null;
    private var _scoreBoards:Array = null;
    private var _medalScore:Number = null;

    /**
    * Constructor
    * @param appId The application id for your game
    * @param encryptionKey The encryption key for your game
    * @param debug A boolean value indicating whether or not to operate in debug mode
    */
    public function core(appId:String, encryptionKey:String, debug:Boolean)
    {
        this._appId = appId;
        this._baseAppId = String(appId).split(":")[0];
        this._encryptionKey = encryptionKey;
        this._debug = debug ? true : false;
        this._queue = [];
        this._session = new io.newgrounds.models.objects.Session();
        if (_root.ngio_session_id !== undefined) {
            this._session.id = _root.ngio_session_id;
        } else {
            var so = SharedObject.getLocal("ngio_session_app_id_"+this._baseAppId);
            if (so.data.id !== undefined) {
                this._session.id = so.data.id;
            }
        }
    }

    public function get appId():String
    {
        return this._appId;
    }
    
    public function get encryptionKey():String
    {
        return this._encryptionKey;
    }

    public function get debug():Boolean
    {
        return this._debug;
    }

    public function get currentVersion():String {
        return this._currentVersion
    }

    public function get clientDeprecated()  {
        return this._clientDeprecated
    }

    public function get hostApproved():Boolean {
        return this._hostApproved
    }

    public function get saveSlots():Array {
        return this._saveSlots
    }

    public function get medals():Array {
        return this._medals
    }

    public function get medalScore():Number {
        return this._medalScore
    }

    public function get scoreBoards():Array {
        return this._scoreBoards
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
            var so = SharedObject.getLocal("ngio_session_app_id_"+this._baseAppId);
            so.data.id = this.session.id;
            so.flush();
        }
    }

    public function clearSession():Void
    {
        this._session = new io.newgrounds.models.objects.Session();
        var so = SharedObject.getLocal("ngio_session_app_id_"+this._baseAppId);
        so.clear();
    }

    /**
    * Converts an object to a JSON string and encrypts it
    * @param obj The data to encrypt
    * @return The encrypted data
    */
    public function encrypt(obj):String
    {
        var json = io.newgrounds.encoders.JSON.encode(obj);
        if (this._debug) {
            trace("Newgrounds.io - Encrypting JSON:");
            trace(json+"\n");
        }
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
    * Returns a boolean value indicating whether or not there are components in the request queue
    * @return A boolean value indicating whether or not there are components in the request queue
    */
    public function hasQueuedComponents():Boolean
    {
        return this._queue.length > 0;
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

                // if the overall response has a false success, we won't have a result object, so return the response as is
                if (response.success === false) {
                    result = response;
                
                // oherwise, we have a result object to process
                } else {
                    result = response.result;

                    // let's process the result(s) just in case they have any models we need to cahe (medal lists and things like that)
                    if (result instanceof Array) {
                        for (var i=0; i<result.length; i++) {
                            core.processResult(result[i]);
                        }
                    } else {
                        core.processResult(result);
                    }
                }

                core.doCallback(callback, thisArg, response, callbackParams);
            }

            // send the request to the server
            loader.sendAndLoad(GATEWAY_URL, results, "POST");
        }
    }

    /**
    * Inspects a rsult object for any models we want to cache in this core instance
    * @param result The result object to inspect
    */
    public function processResult(result)
    {
        // if it's a failed result we don't need to cache anything
        if (!result || !result.success) return;

        // some items will be arrays of objects that need to be attached to the core
        var attach = [];

        // this is the stuff we DO want to cache
        switch(result.getObjectName()) {

            case "App.getCurrentVersion":
                this._currentVersion = result.current_version;
                this._clientDeprecated = result.client_deprecated;
                break;

            case "App.getHostLicense":
                this._hostApproved = result.host_approved;
                break;

            case "CloudSave.loadSlot":
            case "CloudSave.setData":
                // update the cache with the new slot data
                if (this._saveSlots) {
                    for(var i=0; i<this._saveSlots.length; i++) {
                        if (this._saveSlots[i].id == result.slot.id) {
                            this._saveSlots[i] = result.slot;
                            break;
                        }
                    }
                }
                result.slot.attachCore(this);
                break;
            
            case "CloudSave.loadSlots":
                this._saveSlots = attach = result.slots;
                break;
            
            case "Medal.getList":
                this._medals = attach = result.medals;
                break;
            
            case "ScoreBoard.getBoards":
                this._scoreBoards = attach = result.scoreboards;
                break;

            case "Medal.unlock":
                // update the cache with the new medal data
                if (this._medals) {
                    for(var i=0; i<this._medals.length; i++) {
                        if (this._medals[i].id == result.medal.id) {
                            this._medals[i] = result.medal;
                            break;
                        }
                    }
                }
                result.medal.attachCore(this);
                this._medalScore = result.medal_score;
                break;

            case "Medal.getMedalScore":
                this._medalScore = result.medal_score;
                break;
        }

        for(var i=0; i<attach.length; i++) {
            attach[i].attachCore(this);
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