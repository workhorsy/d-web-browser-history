


import std.traits;

S stripChars(S)(S s, bool function(dchar) pure nothrow mustStrip)
        pure nothrow if (isSomeString!S) {
    S result;
    foreach (c; s) {
        if (!mustStrip(c))
            result ~= c;
    }
    return result;
}

int main() {
	import std.stdio;
	import web_browser_history;
	import derelict.sqlite3.sqlite : DerelictSQLite3;
	import std.string : chomp;
	import std.conv : to;
	import core.thread;
	import std.stdio, std.uni;

	DerelictSQLite3.load();

	web_browser_history.readHistory(WebBrowser.Chrome, delegate(string url, int visit_count) {
		string ass = "";
		foreach (i ; 0 .. url.length) {
			ass ~= url[i].to!string.chomp;
		}


	    //auto s = "\u0000\u000A abc\u00E9def\u007F";
	    //writeln(s.stripChars( &isControl ));
	    //writeln(s.stripChars( c => isControl(c) || c == '\u007F' ));
	    //writeln(s.stripChars( c => isControl(c) || c >= '\u007F' ));
		stdout.writefln("url: %s", ass.stripChars( c => isControl(c) || c >= '\u007F' )); stdout.flush();
	});

	//Thread.sleep(10.seconds);
	stdout.writefln("Done!"); stdout.flush();
	return 0;
}
