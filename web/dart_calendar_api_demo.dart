import 'dart:html';
import 'dart:convert' show JSON;
import 'package:intl/intl.dart';
import 'package:chrome_gen/chrome_app.dart' as chrome;

// URL da richiedere
String requestUrl = getRequestUrl();

// Elementi top-level
ButtonElement logoutBtn = querySelector('#logout');
ButtonElement loginBtn = querySelector('#login');
DivElement events = querySelector('#events');
List<String> colors = ['rgb(247, 237, 190)','rgb(223, 243, 215)',
                       'rgb(251, 253, 186)', 'rgb(253, 229, 229)',
                       'rgba(226, 241, 243, 0.42)'];
int cnt = 0;
void main() {
  String token;

  loginBtn.onClick.listen((data) {
    // Otteniamo un token per l'autenticazione
    var tokenDetails = new chrome.TokenDetails(interactive: true);
    chrome.identity.getAuthToken(tokenDetails).then((_token) {
      token = _token;
      // Prepariamo la richiesta
      var req = new HttpRequest();
      req.onLoadEnd.listen((e) {
        if(req.status==200) {
          loginBtn.style.visibility = 'hidden';
          loginBtn.style.display = 'none';
          logoutBtn.style.visibility = 'visible';
          logoutBtn.style.display = 'block';
          showData(req.responseText);
        }
      });

      req
      ..open('GET', requestUrl)
      ..setRequestHeader('Authorization', 'Bearer $token')
      ..send();
    });
  });

  // Registriamo una funzione di callback all'evento onClick su `logoutBtn`
  logoutBtn.onClick.listen((e) {
    if (token != null) {
      var invalidTokenDetails = new chrome.InvalidTokenDetails(token: token);
      var req = new HttpRequest();
      req.onLoadEnd.listen((e) {
        // Rimuoviamo l'auth token dalla cache
        chrome.identity.removeCachedAuthToken(invalidTokenDetails).then((_){
          loginBtn.style.visibility = 'visible';
          loginBtn.style.display = 'block';
          logoutBtn.style.visibility = 'hidden';
          logoutBtn.style.display = 'none';
          // Rimuoviamo gli eventi del calendario dal DOM
          events.children.clear();
          });
        });
      // Inoltriamo la richiesta di revoca del token
      req
      ..open("GET", "https://accounts.google.com/o/oauth2/revoke?token=$token")
      ..send();
    }
  });
}

String getRequestUrl() {
  String endpoint = "https://www.googleapis.com/calendar/v3/calendars";
  String email = "INSERT_YOUR_EMAIL_HERE";
  String req = "events?timeMin=${getFormattedDate()}&singleEvents=true&orderBy=startTime";
  return endpoint + '/' + email + '/' + req;
}

void showData(String _data) {
  // Convertiamo il response in una mappa di elementi
  var data = JSON.decode(_data)["items"];
  // Appendiamo ogni elemento al DOM
  for(var i=0;i<data.length;i++) {
    events.children.add(createDiv(data[i]));
  }
}

// Funzione per convertire la data corrente nel formato accettato dall'API
String getFormattedDate() {
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-ddTHH:mm:ss');
  return formatter.format(now)+'Z';
}

// Funzione per creare un Node-tree per ogni elemento in `data`
DivElement createDiv(data) {
  var elem = new DivElement();
  var summary = new ParagraphElement();
  var htmlLink = new AnchorElement();
  var imgLink = new ImageElement();
  var info = new ParagraphElement();

  // Impostiamo lo stile degli elementi, interessante la sintassi a cascata ".."
  elem.style
    ..marginBottom = '10px'
    ..padding = '10px'
    ..color = '#525252'
    ..borderRadius = '1px'
    ..position = 'relative'
    ..backgroundColor = colors[cnt%colors.length];

  htmlLink
    ..href = data["htmlLink"]
    ..style.position = "absolute"
    ..style.right = "0"
    ..style.top = "0"
    ..style.marginTop = "5px"
    ..style.marginRight = "5px"
    ..target = '_blank';

  imgLink.src = 'globe.png';

  htmlLink.children.add(imgLink);

  var creator = data["creator"]["displayName"] != null ?
      data["creator"]["displayName"] : data["creator"]["email"];

  info
  ..innerHtml = "${data["start"]["dateTime"]}<br/><em>Creato da $creator</em>";

  summary
    ..text = data["summary"]
    ..style.fontSize = '18px'
    ..style.marginBottom = '5px'
    ..style.marginTop = '5px';

  elem.children.addAll([summary,info,htmlLink]);
  cnt++;
  return elem;
}
