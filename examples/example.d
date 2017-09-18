


int main() {
	import std.stdio;
	import web_browser_history;
	import derelict.sqlite3.sqlite : DerelictSQLite3;

	DerelictSQLite3.load();

	web_browser_history.readHistory(WebBrowser.Chrome, delegate(string url, int visit_count) {
		stdout.writefln("url: %s", url);
	});

	return 0;
}