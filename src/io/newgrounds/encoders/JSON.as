/*
Copyright (c) 2005 JSON.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
ported to Actionscript May 2005 by Trannie Carter <tranniec@designvox.com>, wwww.designvox.com
USAGE:
	try {
		var o:Object = JSON.decode(jsonStr);
		var s:String = JSON.encode(obj);
	} catch(ex) {
		trace(ex.name + ":" + ex.message + ":" + ex.at + ":" + ex.text);
	}

*/

class io.newgrounds.encoders.JSON {
	
	// This method will encode an object and return it instantly.
	static function encode(arg,noquotes):String {

        var c, i, l, s = '', v;
		var typemodel = typeof arg;
		
        switch (typemodel) {
		case 'object':

            if (arg) {
                if (arg instanceof Array) {
                    for (i = 0; i < arg.length; ++i) {
                        v = encode(arg[i]);
                        if (s) {
                            s += ',';
                        }
                        s += v;
                    }
                    return '[' + s + ']';
                } else if (typeof arg.toString != 'undefined') {
                    for (i in arg) {
                        v = arg[i];
                        if (typeof v != 'undefined' && typeof v != 'function') {
                            v = encode(v);
                            if (s) {
                                s += ',';
                            }
                            s += encode(i) + ':' + v;
                        }
                    }
                    return '{' + s + '}';
                }
            }
            return 'null';
        case 'number':
            return isFinite(arg) ? String(arg) : 'null';
        case 'string':

            l = arg.length;
			if (noquotes) {
				var quotes = '';
			} else {
	            var quotes = '"';
			}
			s = quotes;
            for (i = 0; i < l; i += 1) {
                c = arg.charAt(i);
                if (c >= ' ') {
                    if (c == '\\' || c == '"') {
                        s += '\\';
                    }
                    s += c;
                } else {
                    switch (c) {
                        case '\b':
                            s += '\\b';
                            break;
                        case '\f':
                            s += '\\f';
                            break;
                        case '\n':
                            s += '\\n';
                            break;
                        case '\r':
                            s += '\\r';
                            break;
                        case '\t':
                            s += '\\t';
                            break;
                        default:
                            c = c.charCodeAt();
                            s += '\\u00' + Math.floor(c / 16).toString(16) +
                                (c % 16).toString(16);
                    }
                }
            }
            return s + quotes;
        case 'boolean':
            return String(arg);
        default:
            return 'null';
        }
    }
	
	private static var encode_chunks = 20000; // we will crunch 20000 values per interval
	private static var decode_chunks = 20000; // we will parse 20000 characters per interval
	private static var start:Number; // used to report how long a string took to render
	private static var cache:Object;
	private static var interval:Number;
	private static var busy:Boolean = false;
	
	// this method will take an object aprt and encode it in chunks.
	// This method is preferable when dealing with extremely large objects that would crash the encode() method.
	public static function background_encode(arg,callback:Function) {
		if (busy) {
			trace("[Newgrounds Encoder] :: Cannot encode a new file until the previous file is completed");
			return false;
		} else if (!callback) {
			trace("[Newgrounds Encoder] :: Missing a callback function, skipping encode");
			return false;
		}
		busy = true;
		var d = new Date();
		start = d.getTime();
		cache = {
			busy:false,
			complete:false,
			arg:arg,
			target:arg,
			parents:[],
			encoded:"",
			callback:callback,
			encode_chunk:function(){JSON.encode_chunk();}
		}
		if (getType(arg) == "object") {
			cache.encoded = "{";
		} else if (getType(arg) == "array") {
			cache.encoded = "[";
		}

		interval = setInterval(cache, "encode_chunk", 25);
		return true;
	}
	
	public static function background_decode(arg:String, callback:Function) {
		if (busy) {
			trace("[Newgrounds Encoder] :: Cannot decode a new file until the previous file is completed");
			return false;
		} else if (!callback) {
			trace("[Newgrounds Encoder] :: Missing a callback function, skipping decode");
			return false;
		}
		
		busy = true;
		var d = new Date();
		start = d.getTime();
		cache = {
			busy:false,
			callback:callback,
			complete:false,
			arg:arg,
			pos:0,
			parents:["root"],
			target:null,
			scratch:"",
			decode_chunk:function(){JSON.decode_chunk();}
		}
		
		interval = setInterval(cache, "decode_chunk", 25);
		return true;
	}

	static function decode(text:String):Object {
        var at = 0;
        var ch = ' ';
		var _value:Function;

        var _error:Function = function (m) {
            throw {
                name: 'JSONError',
                message: m,
                at: at - 1,
                text: text
            };
        }

        var _next:Function = function() {
            ch = text.charAt(at);
            at += 1;
            return ch;
        }

        var _white:Function = function() {
            while (ch) {
                if (ch <= ' ') {
                    _next();
                } else if (ch == '/') {
                    switch (_next()) {
                        case '/':
                            while (_next() && ch != '\n' && ch != '\r') {}
                            break;
                        case '*':
                            _next();
                            for (;;) {
                                if (ch) {
                                    if (ch == '*') {
                                        if (_next() == '/') {
                                            _next();
                                            break;
                                        }
                                    } else {
                                        _next();
                                    }
                                } else {
                                    _error("Unterminated comment");
                                }
                            }
                            break;
                        default:
                            _error("Syntax error");
                    }
                } else {
                    break;
                }
            }
        }

        var _string:Function = function() {
            var i, s = '', t, u;
			var outer:Boolean = false;

            if (ch == '"') {
				while (_next()) {
                    if (ch == '"') {
                        _next();
                        return s;
                    } else if (ch == '\\') {
                        switch (_next()) {
						case '"':
							s += '"';
							break;
                        case 'b':
                            s += '\b';
                            break;
                        case 'f':
                            s += '\f';
                            break;
                        case 'n':
                            s += '\n';
                            break;
                        case 'r':
                            s += '\r';
                            break;
                        case 't':
                            s += '\t';
                            break;
                        case 'u':
                            u = 0;
                            for (i = 0; i < 4; i += 1) {
                                t = parseInt(_next(), 16);
                                if (!isFinite(t)) {
                                    outer = true;
									break;
                                }
                                u = u * 16 + t;
                            }
							if(outer) {
								outer = false;
								break;
							}
                            s += String.fromCharCode(u);
                            break;
                        default:
                            s += ch;
                        }
                    } else {
                        s += ch;
                    }
                }
            }
            _error("Bad string");
        }

        var _array:Function = function() {
            var a = [];

            if (ch == '[') {
                _next();
                _white();
                if (ch == ']') {
                    _next();
                    return a;
                }
                while (ch) {
                    a.push(_value());
                    _white();
                    if (ch == ']') {
                        _next();
                        return a;
                    } else if (ch != ',') {
                        break;
                    }
                    _next();
                    _white();
                }
            }
            _error("Bad array");
        }

        var _object:Function = function() {
            var k, o = {};

            if (ch == '{') {
                _next();
                _white();
                if (ch == '}') {
                    _next();
                    return o;
                }
                while (ch) {
                    k = _string();
                    _white();
                    if (ch != ':') {
                        break;
                    }
                    _next();
                    o[k] = _value();
                    _white();
                    if (ch == '}') {
                        _next();
                        return o;
                    } else if (ch != ',') {
                        break;
                    }
                    _next();
                    _white();
                }
            }
            _error("Bad object");
        }

        var _number:Function = function() {
            var n = '', v;

            if (ch == '-') {
                n = '-';
                _next();
            }
            while (ch >= '0' && ch <= '9') {
                n += ch;
                _next();
            }
            if (ch == '.') {
                n += '.';
                while (_next() && ch >= '0' && ch <= '9') {
                    n += ch;
                }
            }
            //v = +n;
			v = 1 * n;
            if (!isFinite(v)) {
                _error("Bad number");
            } else {
                return v;
            }
        }

        var _word:Function = function() {
            switch (ch) {
                case 't':
                    if (_next() == 'r' && _next() == 'u' && _next() == 'e') {
                        _next();
                        return true;
                    }
                    break;
                case 'f':
                    if (_next() == 'a' && _next() == 'l' && _next() == 's' &&
                            _next() == 'e') {
                        _next();
                        return false;
                    }
                    break;
                case 'n':
                    if (_next() == 'u' && _next() == 'l' && _next() == 'l') {
                        _next();
                        return null;
                    }
                    break;
            }
            _error("Syntax error");
        }

        _value = function() {
            _white();
            switch (ch) {
                case '{':
                    return _object();
                case '[':
                    return _array();
                case '"':
                    return _string();
                case '-':
                    return _number();
                default:
                    return ch >= '0' && ch <= '9' ? _number() : _word();
            }
        }

        return _value();
    }

	private static function getType(v) {
		if (v instanceof Array) {
			return "array";
		} else {
			return typeof(v);
		}
	}
	
	public static function decode_chunk() {
		if (!cache.busy && !cache.complete) {
			cache.busy = true;
			for(var i=0; i<decode_chunks; i++) {
				chunk_decoder();
				if (cache.complete) {
					break;
				}
			}
			trace(Math.round((cache.pos/cache.arg.length)*100)+"% decoded");
			cache.busy = false;
		}
		if (cache.complete) {
			var d = new Date();
			busy = false;
			clearInterval(interval);
			cache.callback(cache.root, d.getTime()-start);
			cache.arg = "";
		}
	}
	
	public static function encode_chunk() {
		
		if (!cache.busy && !cache.complete) {
			cache.busy = true;
			for(var i=0; i<encode_chunks; i++) {
				chunk_encoder();
				if (cache.complete) {
					break;
				}
			}
			cache.busy = false;
		}
		
		if (cache.complete) {
			var d = new Date();
			var e = d.getTime();
			busy = false;
			clearInterval(interval);
			cache.callback(cache.encoded, e-start);
			// clear the encoded cache to free up memory
			cache.encoded = "";
		}
	}
	
	private static function chunk_decoder()
	{
		// function for parsing objects
		function _object() {
			var char = cache.arg.charAt(cache.pos);
			
			if (!cache.mode) {
				cache.mode = "object";
				cache.pos++;
				char = cache.arg.charAt(cache.pos);
				
				if (char != '"') {
					throw("Malformed object key in encoded string. Keys must be wrapped in quotes (\"\")");
				}
				cache.scratch = "";
				_setTargetValue({});
			} else if (char == ",") {
				cache.pos++;
				char = cache.arg.charAt(cache.pos);
				
				if (char != '"') {
					throw("Malformed object key in encoded string. Keys must be wrapped in quotes (\"\")");
				}
				cache.scratch = "";
			} else if (char == "}") {
				_useParent();
			// this works about the same as the string parser
			} else {
				if (char == '"') {
					cache.pos++;
					char = cache.arg.charAt(cache.pos);
					
					if (char != ":") {
						throw("Malformed object notation. Object keys and values must be separated by colons(:)");
					}
					
					_addParent(cache.scratch);
					
					cache.mode = null;
				} else {
					if (char == "\\") {
						cache.pos++;
						char = cache.arg.charAt(cache.pos);
						
					}
					cache.scratch+=char;
				}
			}
			cache.pos++;
		}
		
		function _array() {
			var char = cache.arg.charAt(cache.pos);
			
			if (!cache.mode) {
				cache.mode = "array";
				cache.pos++;
				char = cache.arg.charAt(cache.pos);
				_setTargetValue([]);
				if (char != "]") {
					_addArrayKey();
				} else {
					_useParent();
				}
				return;
			} else if (char == ",") {
				_addArrayKey();
			} else if (char == "]") {
				_useParent();
			}
			cache.pos++;
		}
		
		function _boolean() {
			var char = cache.arg.charAt(cache.pos);
			if (char == "t") {
				_setTargetValue(true);
				cache.pos += 3;
			} else if (char == "f") {
				_setTargetValue(false);
				cache.pos += 4;
			} else {
				throw("Bool values must be true or false");
			}
			
			_useParent();
		}
		
		function _null() {
			var char = cache.arg.charAt(cache.pos);
			if (char == "n") {
				_setTargetValue(null);
				cache.pos += 2;
			} else {
				throw("Null values must be null");
			}
			
			_useParent();
		}
		
		function _string() {
			
			var char = cache.arg.charAt(cache.pos);
			
			if (!cache.mode) {
				if (char != '"') {
					throw ("Strings must be wrapped in quotes (\"\")");
				}
				cache.scratch = "";
				cache.mode = "string";
			} else if (char == '"') {
				_setTargetValue(cache.scratch);
				_useParent();
			} else {
				if (char == "\\") {
					cache.pos++;
					char = cache.arg.charAt(cache.pos);
					switch (char) {
						case "n" :
							char = newline;
							break;
						case "r" :
							char = newline;
							break;
						case "t" :
							char = "	";
							break;
						case "u" :
							char = "\\"+char;
							break;
					}
				}
				cache.scratch += char;
			}
			
			cache.pos++;
		}
		
		function _number() {
			var char = cache.arg.charAt(cache.pos);
			var valid = "01234567890.-";
			if (!cache.mode) {
				cache.mode = "number";
				cache.scratch = "";
			}
			if (valid.indexOf(char) < 0) {
				_setTargetValue(Number(cache.scratch));
				_useParent();
			} else {
				cache.scratch += char;
				cache.pos++;
			}
		}

		function _setTargetValue(newval) {
			var parent = _getParent().obj;
			var key = cache.parents[cache.parents.length-1];
			parent[key] = newval;
		}
		
		function _useParent() {
			cache.mode = getType(_getParent().obj);
			cache.parents.pop();
		}
		
		function _getParent() {
			var parent = cache;
			for(var i=0; i<cache.parents.length-1; i++) {
				parent = parent[cache.parents[i]];
			}
			return {obj:parent, name:cache.parents[i]};
		}
		
		function _getCurrent() {
			var current = cache;
			for(var i=0; i<cache.parents.length; i++) {
				current = current[cache.parents[i]];
			}
			return {obj:current, name:cache.parents[i]};
		}
		
		function _addParent(child) {
			cache.parents.push(child);
		}
		
		function _addArrayKey() {
			var a_len = _getCurrent().obj.length;
			cache.parents.push(a_len);
			cache.mode = null;
		}
		// main routine
		if (cache.pos >= cache.arg.length) {
			cache.complete = true;
			return;
		} else if (cache.mode) {
			eval("_"+cache.mode)();
		} else {
			var char = cache.arg.charAt(cache.pos);
			switch(char) {
				case "{":
					_object();
					break;
				case "[":
					_array();
					break;
				case "\"":
					_string();
					break;
				case "n":
					_null();
					break;
				case "t":
					_boolean();
					break;
				case "f":
					_boolean();
					break;
				default:
					_number();
					break;
			}
		}
	}
	
	private static function chunk_encoder() {
		if (cache.complete) {
			return;
		}
		var usetype = getType(cache.target);
		switch(usetype) {
			
			case "number":
				cache.encoded += cache.target;
				getParent();
				break;
			case "string":
				cache.encoded += "\""+cache.target.split('"').join('\\"')+"\"";
				getParent();
				break;
			case "boolean":
				cache.encoded += cache.target == true ? "true":"false";
				getParent();
				break;
			case "null":
				cache.encoded += "null";
				getParent();
				break;
			case "array":
				if (cache.target.length < 1) {
					cache.encoded += "]";
					getParent();
				} else {
					cache.parents.push(cache.target);
					cache.target = cache.target[0];
					if (getType(cache.target) == "array") {
						cache.encoded += "[";
					} else if (getType(cache.target) == "object") {
						cache.encoded += "{";
					}
				}
				break;
			case "object":
				for(var i in cache.target) {
					break;
				}
				
				if (i === undefined) {
					cache.encoded += "}";
					getParent();
				} else {
					cache.parents.push(cache.target);
					cache.target = cache.target[i];
					cache.encoded += "\""+i.split('"').join('\\"')+"\":";
					if (getType(cache.target) == "array") {
						cache.encoded += "[";
					} else if (getType(cache.target) == "object") {
						cache.encoded += "{";
					}
				}
				break;
			default:
				cache.encoded += "null";
				getParent(); // this is typically just for empty array keys
				break;
		}
	}
	
	private static function getParent() {
		
		if (cache.parents.length > 0) {
			var parent = cache.parents.pop();
			
			if (getType(parent) == "array") {
				parent.shift();
			} else {
				for(var i in parent) {
					delete(parent[i]);
					break;
				}
			}
			if (getType(parent) == 'object' or getType(parent) == 'array') {
				for(var j in parent) {
					break;
				}
				
				if (j !== undefined) {
					cache.encoded += ",";
				}
			}
			cache.target = parent;
		} else {
			cache.complete = true;
		}
	}
}
