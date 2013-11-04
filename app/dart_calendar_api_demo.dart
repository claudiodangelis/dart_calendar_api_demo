import 'dart:html';
import 'dart:convert' show JSON;
import 'package:chrome/app.dart';
import 'package:intl/intl.dart';

// URL da richiedere
String requestUrl =
  
'https://www.googleapis.com/calendar/v3/calendars/MIO_INDIRIZZO_EMAIL/events?timeMin='+getFormattedDate();

// Elementi top-level
ButtonElement logoutBtn = querySelector('#logout');
ButtonElement loginBtn = querySelector('#login');
DivElement events = querySelector('#events');

void main() {
  
  String token;

  loginBtn.onClick.listen((data) {
    // Otteniamo un token per l'autenticazione
    chromeIdentity.getAuthToken(interactive: true).then((_token) {
      token = _token;
      // Prepariamo la richiesta
      var req = new HttpRequest();
      req.onLoadEnd.listen((e) {
        if(req.status==200) {
          // Nascondiamo il bottone di login
          loginBtn.style.visibility = 'hidden';
          loginBtn.style.display = 'none';
          
          // Mostriamo il bottone di logout
          logoutBtn.style.visibility = 'visible';
          logoutBtn.style.display = 'block';
          
          // Passiamo il response alla funzione showData
          showData(req.responseText);
        }
      });
      // Inoltriamo la richiesta
      req
      ..open('GET', requestUrl)
      ..setRequestHeader('Authorization', 'Bearer $token')
      ..send();
    });
  });

  // Registriamo una funzione di callback all'evento onClick su `logoutBtn`
  logoutBtn.onClick.listen((e) {
    if (token != null) {
      var req = new HttpRequest();
      req.onLoadEnd.listen((e) {
        // Rimuoviamo l'auth token dalla cache
        chromeIdentity.removeCachedAuthToken(token).then((_){
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
      ..open('GET', 'https://accounts.google.com/o/oauth2/revoke?token=${token}')
      ..send();
    }
  });
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
  var info = new ParagraphElement();
  
  // Impostiamo lo stile degli elementi, interessante la sintassi a cascata ".."
  elem.style
    ..marginBottom = '10px'
    ..padding = '10px'
    ..borderRadius = '2px'
    ..border = '1px solid #ccc'
    ..backgroundColor = 'white'
    ..fontSize = 'x-large';
  
  htmlLink
    ..text = "Vedi evento su Google Calendar"
    ..href = data["htmlLink"]
    ..style.fontSize = 'x-small'
    ..target = '_blank';
  
  info
  ..innerHtml = "${data["start"]["dateTime"]}<br/><em>Creato da ${data["creator"]["displayName"]}</em>"
  ..style.fontSize = 'x-small';
  
  summary
    ..text = data["summary"]
    ..style.marginBottom = '5px'
    ..style.marginTop = '5px';
   
  elem.children.addAll([info,summary,htmlLink]);
  return elem;
} 
