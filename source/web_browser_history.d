// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get web browser history with the D programming language
// https://github.com/workhorsy/d-web-browser-history

/++
Get web browser history with the D programming language

Home page:
$(LINK https://github.com/workhorsy/d-web-browser-history)

License:
Boost Software License - Version 1.0

Examples:
----
import WebBrowserHistory;
import std.stdio : stdout;

foreach (browser ; WebBrowserHistory.GetInstalledBrowsers()) {
	WebBrowserHistory.ReadHistory(browser, delegate(string url, int visit_count) {
		stdout.writefln("browser:%s, url:%s, count:%s", browser, url, visit_count);
	});
}
----
+/


module WebBrowserHistory;


pragma(lib, "sqlite3");
import etc.c.sqlite3;

/++
The type of web browser to get history from.
+/
enum WebBrowser {
	Firefox,
	Chrome,
	Chromium,
	Opera,
	Brave,
}

private void delegate(string url, int visit_count) g_each_row_cb;

private static string[] black_list = [
	"bank", "credit union", "bond", "invest", "hospital", "medical", "private",
	"account"
];

private extern (C) int callback(void* NotUsed, int argc, char** argv, char** azColName) {
	import std.conv : to;
	import std.algorithm : any, count;
	import std.string : fromStringz;

	string url = (cast(string) fromStringz(argv[0] ? argv[0] : "NULL")).dup;
	auto visit_count = cast(string) fromStringz(argv[1] ? argv[1] : "0");
	int total = to!int(visit_count);

	bool is_black_listed = black_list.any!(entry => url.count(entry) > 0);

	if (! is_black_listed) {
		g_each_row_cb(url, total);
	}
	return 0;
}

private string[] GetHistoryPaths(WebBrowser browser) {
	version (unittest) {
		final switch (browser) {
			case WebBrowser.Firefox:
				return GetHistoryPaths("firefox_history.sqlite", ["test_browser_data"]);
			case WebBrowser.Chrome:
				return GetHistoryPaths("chrome_history.sqlite", ["test_browser_data"]);
			case WebBrowser.Chromium:
				return GetHistoryPaths("chromium_history.sqlite", ["test_browser_data"]);
			case WebBrowser.Opera:
				return GetHistoryPaths("opera_history.sqlite", ["test_browser_data"]);
			case WebBrowser.Brave:
				return GetHistoryPaths("brave_history.sqlite", ["test_browser_data"]);
		}
	} else {
		final switch (browser) {
			case WebBrowser.Firefox:
				return GetHistoryPaths("places.sqlite", ["~/.mozilla/firefox/", "%APPDATA%/Mozilla/Firefox/"]);
			case WebBrowser.Chrome:
				return GetHistoryPaths("History", ["~/.config/google-chrome/", "%LOCALAPPDATA%/Google/Chrome/"]);
			case WebBrowser.Chromium:
				return GetHistoryPaths("History", ["~/.config/chromium/"]);
			case WebBrowser.Opera:
				return GetHistoryPaths("History", ["~/.config/opera/", "%APPDATA%/Opera Software/Opera Stable/"]);
			case WebBrowser.Brave:
				return GetHistoryPaths("History", ["~/.config/brave/", "%APPDATA%/brave/"]);
		}
	}
}

private string[] GetHistoryPaths(string file_name, string[] settings_paths) {
	import std.file : exists, DirIterator, dirEntries, FileException;
	import std.path : baseName, SpanMode;

	string[] paths;
	foreach (settings_path; settings_paths) {
		string full_path = ExpandPath(settings_path);

		if (! exists(full_path)) {
			continue;
		}

		try {
			DirIterator iter = dirEntries(full_path, SpanMode.breadth, true);
			foreach (string path; iter) {
				if (baseName(path) == file_name) {
					paths ~= path;
				}
			}
		} catch (FileException) {
			// NOTE: Ignore any FS errors from dirEntries throwing
		}
	}

	return paths;
}

private string ExpandPath(string path) {
	import std.process : environment;
	import std.path : expandTilde;
	import std.algorithm : count;
	import std.string : replace;

	path = expandTilde(path);
	foreach (string name, string value ; environment.toAA()) {
		if (path.count(name) > 0) {
			path = path.replace("%" ~ name ~ "%", value);
		}
	}
	return path;
}

/++
Returns an array of installed web browsers.
+/
WebBrowser[] GetInstalledBrowsers() {
	import std.traits : EnumMembers;

	// Get the installed browsers
	WebBrowser[] browsers;
	foreach (browser ; EnumMembers!WebBrowser) {
		if (GetHistoryPaths(browser).length > 0) {
			browsers ~= browser;
		}
	}

	// Use firefox as the default browser, if none are installed
	if (browsers.length == 0) {
		browsers ~= WebBrowser.Firefox;
	}

	return browsers;
}

///
unittest {
	WebBrowser[] browsers = WebBrowserHistory.GetInstalledBrowsers();

	// browsers output
	// [Firefox, Chrome, Chromium, Opera, Brave]
}

/++
Reads all the history for the selected web browser.

Params:
 browser = The web browser to search
 each_row_cb = The callback to fire for each row in the history.
+/
void ReadHistory(WebBrowser browser, void delegate(string url, int visit_count) each_row_cb) {
	import std.stdio : stdout, stderr;
	import std.file : exists, remove, copy;
	import std.string : fromStringz;
	import std.string : toStringz;

	g_each_row_cb = each_row_cb;

	string[] paths = GetHistoryPaths(browser);
	string sql_query;
	final switch (browser) {
		case WebBrowser.Firefox:
			sql_query = "select url, visit_count from moz_places where hidden=0;";
			break;
		case WebBrowser.Chrome:
		case WebBrowser.Chromium:
		case WebBrowser.Opera:
		case WebBrowser.Brave:
			sql_query = "select url, visit_count from urls where hidden=0;";
			break;
	}

	immutable string uri = "History.sqlite";

	foreach (path; paths) {
		stdout.writefln("path: %s", path);

		// Copy the browser's history file to the local directory
		if (exists(uri)) {
			remove(uri);
		}
		copy(path, uri);

		sqlite3* db;
		char* zErrMsg;

		// Open the database
		int rc = sqlite3_open(uri.toStringz, &db);
		if (rc != SQLITE_OK) {
			stderr.writefln("Can't open database: %s\n", cast(string) fromStringz(sqlite3_errmsg(db)));
			sqlite3_close(db);
			return;
		}

		// Read the database
		rc = sqlite3_exec(db, sql_query.toStringz, &callback, cast(void*) 0, &zErrMsg);
		if (rc != SQLITE_OK) {
			stderr.writefln("SQL error: %s\n", cast(string) fromStringz(zErrMsg));
			sqlite3_free(zErrMsg);
			return;
		}

		sqlite3_close(db);
	}

	if (exists(uri)) {
		remove(uri);
	}
}

///
unittest {
	int[string] data;
	WebBrowserHistory.ReadHistory(WebBrowser.Chrome, delegate(string url, int visit_count) {
		data[url] = visit_count;
	});

	// data output
	// ["https://dlang.org/":3, "https://www.google.com/":7, "https://www.reddit.com/":1]
}

/++
Reads all the history for all the web browsers.

Params:
 each_row_cb = The callback to fire for each row in the history.
+/
void ReadHistoryAll(void delegate(string url, int visit_count) each_row_cb) {
	import std.traits : EnumMembers;

	foreach (browser ; EnumMembers!WebBrowser) {
		ReadHistory(browser, each_row_cb);
	}
}

///
unittest {
	int[string] data;
	WebBrowserHistory.ReadHistoryAll(delegate(string url, int visit_count) {
		data[url] = visit_count;
	});

	// data output
	// ["https://dlang.org/":3, "https://www.google.com/":7, "https://www.reddit.com/":1, "https://slashdot.org/":7]
}

unittest {
	import BDD;
	describe("WebBrowserHistory",
		it("Should get installed browsers", delegate() {
			WebBrowser[] browsers = WebBrowserHistory.GetInstalledBrowsers();
			browsers.shouldEqual([
				WebBrowser.Firefox,
				WebBrowser.Chrome,
				WebBrowser.Chromium,
				WebBrowser.Opera,
				WebBrowser.Brave
			]);
		}),
		it("Should get Chrome history", delegate() {
			auto expected_urls = ["https://www.reddit.com/", "https://dlang.org/", "https://www.google.com/"];
			auto expected_visits = [1, 3, 7];
			string[] urls;
			int[] visits;
			WebBrowserHistory.ReadHistory(WebBrowser.Chrome, delegate(string url, int visit_count) {
				urls ~= url;
				visits ~= visit_count;
			});
			urls.shouldEqual(expected_urls);
			visits.shouldEqual(expected_visits);
		}),
		it("Should get Firefox history", delegate() {
			auto expected_urls = ["https://slashdot.org/", "https://dlang.org/"];
			auto expected_visits = [8, 5];
			string[] urls;
			int[] visits;
			WebBrowserHistory.ReadHistory(WebBrowser.Firefox, delegate(string url, int visit_count) {
				urls ~= url;
				visits ~= visit_count;
			});
			urls.shouldEqual(expected_urls);
			visits.shouldEqual(expected_visits);
		}),
		it("Should get Chromium history", delegate() {
			auto expected_urls = ["https://twitter.com/", "https://www.debian.org/", "http://www.microsoft.com/"];
			auto expected_visits = [5, 8, 2];
			string[] urls;
			int[] visits;
			WebBrowserHistory.ReadHistory(WebBrowser.Chromium, delegate(string url, int visit_count) {
				urls ~= url;
				visits ~= visit_count;
			});
			urls.shouldEqual(expected_urls);
			visits.shouldEqual(expected_visits);
		}),
		it("Should get Opera history", delegate() {
			auto expected_urls = ["https://slashdot.org/", "https://microsoft.com/", "https://reddit.com/"];
			auto expected_visits = [2, 4, 1];
			string[] urls;
			int[] visits;
			WebBrowserHistory.ReadHistory(WebBrowser.Opera, delegate(string url, int visit_count) {
				urls ~= url;
				visits ~= visit_count;
			});
			urls.shouldEqual(expected_urls);
			visits.shouldEqual(expected_visits);
		}),
		it("Should get Brave history", delegate() {
			auto expected_urls = ["http://microsoft.com/", "https://twitter.com/", "https://github.com/"];
			auto expected_visits = [1, 3, 8];
			string[] urls;
			int[] visits;
			WebBrowserHistory.ReadHistory(WebBrowser.Brave, delegate(string url, int visit_count) {
				urls ~= url;
				visits ~= visit_count;
			});
			urls.shouldEqual(expected_urls);
			visits.shouldEqual(expected_visits);
		}),
	);
}

