


unittest {
	import BDD;
	import web_browser_history;
	import derelict.sqlite3.sqlite : DerelictSQLite3;

	DerelictSQLite3.load();

	describe("web_browser_history",
		it("Should get installed browsers", delegate() {
			WebBrowser[] browsers = web_browser_history.getInstalledBrowsers();
			browsers.shouldEqual([
				WebBrowser.Brave,
				WebBrowser.Chrome,
				WebBrowser.Chromium,
				WebBrowser.Firefox,
				WebBrowser.Opera,
			]);
		}),
		it("Should get Chrome history", delegate() {
			auto expected_urls = ["https://www.reddit.com/", "https://dlang.org/", "https://www.google.com/"];
			auto expected_visits = [1, 3, 7];
			string[] urls;
			int[] visits;
			web_browser_history.readHistory(WebBrowser.Chrome, delegate(string url, int visit_count) {
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
			web_browser_history.readHistory(WebBrowser.Firefox, delegate(string url, int visit_count) {
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
			web_browser_history.readHistory(WebBrowser.Chromium, delegate(string url, int visit_count) {
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
			web_browser_history.readHistory(WebBrowser.Opera, delegate(string url, int visit_count) {
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
			web_browser_history.readHistory(WebBrowser.Brave, delegate(string url, int visit_count) {
				urls ~= url;
				visits ~= visit_count;
			});
			urls.shouldEqual(expected_urls);
			visits.shouldEqual(expected_visits);
		}),
	);
}
