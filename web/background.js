
chrome.app.runtime.onLaunched.addListener(function(launchData) {
  chrome.app.window.create('dart_calendar_api_demo.html', {
    'id': '_mainWindow', 'bounds': {'width': 300, 'height': 600 }
  });
});
