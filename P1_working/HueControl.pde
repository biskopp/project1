class HueControl  {

  String _ip;
  String _apiKey;
  boolean isOnline;

  HueControl(String apiKey) {

    if ( apiKey.equals("help") ) {
      println("go to: http://www.developers.meethue.com/documentation/getting-started");
    }

    _apiKey = apiKey;

    JSONArray conCheck = loadJSONArray("https://www.meethue.com/api/nupnp");
    int s = conCheck.size();
    if ( s < 1 ) {
      isOnline = false;
      println("The server is not established ");
      println(" - make sure the Bridge is on the same network");
    } else if ( s >= 1 ) {
      isOnline = true;
    }
  }

  HueControl() {

    isOnline = false;
    println("you need an API key. Put \"help\" in the constructor");
  }

  String ipSearch() {

    if ( isOnline ) {  

      JSONArray _ipSearch = loadJSONArray("https://www.meethue.com/api/nupnp");

      for ( int i = 0; i < _ipSearch.size(); i++ ) {
        JSONObject ip = _ipSearch.getJSONObject(i);
        String temp = ip.getString("internalipaddress");

        if ( _ip == null ) {
          _ip = temp;
          println("the IP is: " + _ip);
        }

        if ( _ip.equals(temp) != true ) {
          _ip = temp;
          println("new IP: " + _ip );
        }
      }
      return _ip;
    } else {
      return null;
    }
  } 


  int lightsInSystem() {

    if ( isOnline ) {  
      String[] lines = loadStrings("http://" + _ip +"/api/" + _apiKey + "/lights/");
      String wholePage = join(lines, " ");

      String findStr = "state";
      int lastIndex = 0;
      int count = 0;

      while ((lastIndex = wholePage.indexOf(findStr, lastIndex)) != -1) {
        count ++;
        lastIndex += findStr.length() - 1;
      }

      return count;
    } else {
      return 0;
    }
  }

  boolean isReachable(int lightNum) {

    if ( isOnline ) { 
      if ( lightNum <= lightsInSystem() && lightNum != 0 ) {  

        JSONObject _lights = loadJSONObject("http://" + _ip + "/api/" + _apiKey + "/lights/");
        JSONObject lightNumbers = _lights.getJSONObject(str(lightNum));
        JSONObject states = lightNumbers.getJSONObject("state");

        return states.getBoolean("reachable");

      } else {
        println("the lamp does not exist");
        return false;
      }
    } else {
      return false;
    }
  }

  boolean isOnline() {

    return isOnline;
  }


  void lightInfo(int lightNum) {

    if ( isOnline ) {
      if ( lightNum <= lightsInSystem() && lightNum != 0 ) {  
        JSONObject _lights = loadJSONObject("http://" + _ip + "/api/" + _apiKey + "/lights/");
        JSONObject lightNumbers = _lights.getJSONObject(str(lightNum));
        JSONObject states = lightNumbers.getJSONObject("state");

        boolean on = states.getBoolean("on");
        boolean reachable = states.getBoolean("reachable");
        int bri = states.getInt("bri");
        int hue = states.getInt("hue");
        int sat = states.getInt("sat");

        String name = lightNumbers.getString("name");
        String type = lightNumbers.getString("type");

        println( "Lamp " + lightNum + ":" );
        println("name: " + name + ". type: " + type + "." );
        println( "States: " + "on: " + on + " , " + "bri: " + bri + " , " + "sat: " + sat + " , " + "hue: " + hue + "." );
        println( "is the lamp reachable: " + reachable + "." );
      } else { 
        println("the lamp does not exist");
      }
    } else {
      println("no info available");
    }
  }

  void sendData(Client input, String HSBL, String lightInSys, int leng, int value ) {

    if ( isOnline ) { 
      input.write("PUT /api/" + _apiKey + "/lights/" + lightInSys + "/state HTTP/1.1\r\n"); 
      input.write("Content-Length: " + 18 + leng + "\r\n\r\n");
      input.write("{\"" + HSBL + "\":" + value + "}\r\n");
      input.write("\r\n");
      input.stop();
      sendHTTPData();

      println("sent "+ HSBL + ":" + value);  // command executed
    }
  }

  void sendData(Client input, boolean on, String lightInSys ) {

    if ( isOnline ) {
      input.write("PUT /api/" + _apiKey + "/lights/" + lightInSys + "/state HTTP/1.1\r\n"); 
      input.write("Content-Length: " + 20 + "\r\n\r\n");
      input.write("{\"on\":" + on + "}\r\n");
      input.write("\r\n");
      input.stop();
      sendHTTPData();
      
      println("sent on:" + isLight ); // command executed
    }
  }

  void sendHTTPData() {
    if (c.available() > 0) { // If there's incoming data from the client...
      data = c.readString(); // ...then grab it and print it
      println(data);
    }
  }
}