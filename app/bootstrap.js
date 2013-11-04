
if (navigator.webkitStartDart) {
  navigator.webkitStartDart();
} else {
  var script = document.createElement('script');
  script.src = 'dart_calendar_api_demo.dart.precompiled.js';
  document.body.appendChild(script);
}
