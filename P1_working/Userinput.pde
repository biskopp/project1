class Userinput {

  boolean _checkPassword;
  boolean _isBedtime;
  boolean _playback;

  int[] _bedtime = new int[2];

  String voceInput;
  String _password;
  String _inMelody;
  String _wrongMelody;
  String _notBed;

  Userinput() {

    voce.SpeechInterface.init(sketchPath()+"/code/", true, true, sketchPath()+"/data/", "test");
    println("password ready");

    _password = "cheese";
    _inMelody = "password accepted";
    _wrongMelody = "wrong password";
    _notBed = "it is not bedtime yet";
  }

  void setBedtime(int hour, int minute) {

    _bedtime[0] = hour;
    _bedtime[1] = minute;
  }

  void checkBedtime() {

    if ( hour() >= _bedtime[0] && minute() >= _bedtime[1] ) {
      _isBedtime = true;
    } else {
      _isBedtime = false;
      _checkPassword = false;
    }
  }

  boolean getIsBedtime() {

    return _isBedtime;
  }

  void setPassword(String pass) {

    _password = pass;
  }

  void checkPassword() {

    while (voce.SpeechInterface.getRecognizerQueueSize () > 0) {

      voceInput = voce.SpeechInterface.popRecognizedString();
      if (voceInput.equals(_password)) { 

        _checkPassword = true;
        voce.SpeechInterface.synthesize(_inMelody);
      } else {

        voce.SpeechInterface.synthesize(_wrongMelody);
      }
    }
  }

  boolean getEntry() {

    return _checkPassword;
  }

  boolean isPlayingBack() {

    return _playback;
  }


  void playSound (boolean sound) {

    if ( sound ) {

      if ( key == 'p' && _checkPassword ) { 

        _playback = true;
        println("is playing");
      }
    }
  }

  void stopSound(boolean sound, ddf.minim.AudioPlayer track) {

    if ( sound ) {

      if ( key == 'p' && _checkPassword ) {

        track.pause();
        _playback = false;
      }
    }
  }

  void replay(int pos, int end, ddf.minim.AudioPlayer track) {

    if ( pos == end ) {

      playback = false;
      if ( key == 'p' && _checkPassword ) {

        track.rewind();
        _playback = true;
      }
    }
  }

  void notBedtime() {

    if ( key == 'p' && !_isBedtime ) {
      voce.SpeechInterface.synthesize(_notBed);
    }
  }

  void isOn(boolean theLamp) {

    if ( key == 'o' && !theLamp ) {

      theLamp = true;
      hue = 1;
      println("light on");
    } else if ( key == 'o' && theLamp ) {

      theLamp = false;
      println("light off");
    }
  }

  void changeColor() {

    if ( key == 'h' && _playback ) {

      hue = (hue + 4369) % 65535;
    } else if ( key == 'H' && _playback ) {

      hue = (hue - 4369) % 65535;
    }
  }
}