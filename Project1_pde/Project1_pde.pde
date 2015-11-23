import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;

Minim minim;

AudioInput in;
AudioOutput out;
AudioRecorder recorder;

FilePlayer player;
AudioPlayer myRecord;

boolean recorded;
boolean playback;

void setup() {

  size(400, 400);
  smooth();

  minim = new Minim(this);

  in = minim.getLineIn(Minim.STEREO, 2048);
  out = minim.getLineOut(Minim.STEREO);
  recorder = minim.createRecorder(in, "recording.wav");
}

void draw() {
  background(0);

  if ( playback ) {

    int count = 0;
    int lowFreq = 0;
        
    //noFill();

    for ( int i = 0; i < myRecord.left.size()/3.0; i+=5 ) {
     lowFreq += ( abs ( myRecord.left.get(i)) * 50 );
     count ++; 
    }
    
    float x = map(lowFreq, 0, count*50, 0, 255);
    
    stroke(255);
    fill(x*10,0,0);
    ellipse(width/2,height/2,60,60);

  }

  if ( recorder.isRecording() ) {
    text("Now recording, press the r key to stop recording.", 5, 15);
  } else if ( !recorded ) {
    text("Press the r key to start recording.", 5, 15);
  } else {
    text("Press the s key to save", 5, 15);
  }
}

void keyReleased() {

  if ( !recorded && key == 'r' ) {

    if ( recorder.isRecording() ) {

      recorder.endRecord();
      recorded = true;
    } else {

      recorder.beginRecord();
    }
  }
  if ( recorded && key == 's' ) {

    if ( player != null ) {
      player.unpatch( out );
      player.close();
    }

    player = new FilePlayer( recorder.save() );
    player.patch( out );
    println("is saved");
  }

  if (player != null && key == 'l') {
    myRecord = minim.loadFile("recording.wav", 2048);
    println("file loaded");
  }

  if (key == 'b') {
    myRecord.loop();
    playback = true;
    println("is playing");
  }
  
  if (key == 'a'){
    println(player);
    println(myRecord);
  }
  
}


void stop() {

  myRecord.close();
  minim.stop();
  super.stop();
}