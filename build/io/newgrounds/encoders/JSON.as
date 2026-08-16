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
	// this method is preferred when working form sserver and other high speed applications.
	static function encode(arg,noquotes):String {

        var c, i, l, s = '', v;
		if (arg.isSServerVar()) {
			var typemodel = 'sservervariable';
		} else {
			var typemodel = typeof arg;
		}
		
        switch (typemodel) {
        case 'sservervariable':
			return ("?"+arg.getEncodedValue());
			break;
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
                // Left untyped on purpose. AS2's intrinsic Number declares
                // toString() with no parameters, so calling .toString(16) on a
                // strictly-typed Number can fail to compile. The original code in
                // this branch called it on an untyped value for the same reason -
                // keep it that way.
                var cc = arg.charCodeAt(i);
                // Emit printable ASCII as-is. EVERYTHING else - control characters
                // and all non-ASCII alike - becomes a \uXXXX escape.
                //
                // Escaping non-ASCII is what keeps RC4 correct. Core.encryptObject()
                // runs this encoder's output straight into RC4.encrypt(), whose
                // strToChars() reads the plaintext with charCodeAt - i.e. UTF-16 code
                // units, not UTF-8 bytes. Left raw, 'e-acute' (U+00E9) would be XORed
                // as the single value 233 where UTF-8 needs two bytes, and anything
                // above U+00FF would produce a value over 255 fed into a byte-oriented
                // Base64 encoder, corrupting the stream outright.
                //
                // Escaping here means RC4 only ever sees printable ASCII, where
                // charCodeAt and UTF-8 bytes are identical by definition - so the
                // cipher is correct without being modified. \uXXXX is plain JSON and
                // the gateway's json_decode resolves it identically; PHP's own
                // json_encode escapes non-ASCII this way by default.
                //
                // Characters above U+FFFF arrive as two UTF-16 surrogates and each is
                // escaped separately, which is exactly how JSON represents them.
                if (cc >= 0x20 && cc <= 0x7E) {
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
                            // Four hex digits, zero padded. The previous form
                            // hardcoded '\u00' plus two digits, which is only correct
                            // below U+0100 and silently truncated everything above it.
                            var hex = cc.toString(16);
                            while (hex.length < 4) {
                                hex = '0' + hex;
                            }
                            s += '\\u' + hex;
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

            // Exponent: 1e3, 1E3, 1e+3, 1e-3. This was missing entirely, and it
            // is not a theoretical gap - encode() renders numbers with
            // String(arg), and AVM1 switches to exponent form below 1e-6 and at
            // or above 1e21. So this decoder could not read back what the
            // encoder in this same file produced: a cloud save holding 0.0000001
            // was written as 1e-7 and then failed to load.
            //
            // Where it surfaced depended on position, which made it look like
            // three different bugs: inside an object the leftover 'e' was
            // reported as "Bad object", inside an array as "Bad array", and at
            // the top level it was silently discarded, so `1e3` decoded as 1.
            if (ch == 'e' || ch == 'E') {
                n += ch;
                _next();
                if (ch == '+' || ch == '-') {
                    n += ch;
                    _next();
                }
                while (ch >= '0' && ch <= '9') {
                    n += ch;
                    _next();
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

        var result = _value();

        // Anything left over means this was not a JSON document, however well
        // the leading part parsed.
        //
        // Crockford's original does exactly this and the 2005 port dropped it,
        // so `{"a":1}<html>...` returned {a:1} and threw the rest away. That is
        // the shape of a proxy interstitial or a PHP notice appended after a
        // real response - precisely the case where silently trusting the first
        // half is worst.
        //
        // _white() first, so trailing newlines and spaces are still fine, and
        // `if (ch)` rather than a comparison because _next() yields "" at the
        // end of the input.
        _white();
        if (ch) {
            _error("Unexpected trailing content after a complete JSON value");
        }

        return result;
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

			// cache.arg IS CLEARED BEFORE THE CALLBACK, NOT AFTER. Do not move it
			// back down.
			//
			// `busy` is already false by this point, so a callback is free to
			// start another background_decode() - and that replaces the static
			// `cache` wholesale. Clearing arg afterwards therefore wiped the INPUT
			// OF THE NEW JOB, not the finished one. The new decode then saw
			// pos (0) >= arg.length (0), declared itself complete before reading a
			// character, traced "NaN% decoded" from the 0/0, and handed its
			// callback an undefined root.
			//
			// Two consecutive background_decode() calls is all it takes, and the
			// second one has to be started from the first one's callback - which
			// is exactly what a test suite, or any queue of saves, does.
			//
			// Reading cache.callback and cache.root below is safe: both are
			// resolved before the call is made, so they still belong to this job.
			cache.arg = "";

			cache.callback(cache.root, d.getTime()-start);
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

			// Same hazard as decode_chunk, same fix: a callback that starts
			// another background_encode() replaces the static `cache`, so
			// releasing this job's buffer afterwards would empty the NEW job's.
			//
			// The result has to be captured first, because unlike arg it is the
			// value being handed to the callback rather than spent input.
			var finishedEncoded:String = cache.encoded;

			// clear the encoded cache to free up memory
			cache.encoded = "";

			cache.callback(finishedEncoded, e-start);
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

			// background_decode() has its own scanner, entirely separate from
			// decode()'s _number(), and it had the same exponent gap. Fixing only
			// decode() would have left the chunked path unable to read numbers
			// the chunked ENCODER wrote - the two are used as a pair on large
			// cloud saves, which is exactly where a tiny float is most likely.
			//
			// Character-set based rather than a grammar, matching how the rest of
			// this scanner works: it accumulates while the character is valid and
			// stops at the first one that is not. That accepts some malformed
			// input (1e2e3 becomes NaN), but this path has no error reporting at
			// all and already behaved that way for "1.2.3".
			//
			// HISTORY, because it cost a run to learn: this change was made once,
			// reverted, and then made again unaltered. The revert was wrong. The
			// symptom blamed on it - "NaN% decoded" and a null result - was a
			// pre-existing lifecycle bug in decode_chunk that only shows up when
			// one background_decode starts another from its callback, which is
			// what adding a second chunked test did. See the comment there.
			var valid = "01234567890.-eE+";
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
