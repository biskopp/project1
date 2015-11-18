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
  
  if ( myRecord != null ) {
    myRecord.loop();
    println("not null");

    noFill();
    stroke(255);

    float r = 0;
    for (int i = 0; i < out.bufferSize(); i++) {
      r +=  abs (myRecord.mix.get(i) * 20);
    }

    ellipse(width/2, height/2, r, r);
  }

  if ( recorder.isRecording() ) {
    text("Now recording, press the r key to stop recording.", 5, 15);
  } else if ( !recorded ) {
    text("Press the r key to start recording.", 5, 15);
  } else {
    text("Press the s key to save the recording to disk and play it back in the sketch.", 5, 15);
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
  if ( recorded && key == 's' ){

    if ( player != null ){
      player.unpatch( out );
      player.close();
    }

    player = new FilePlayer( recorder.save() );
    player.patch( out );
    myRecord = minim.loadFile("recording.wav");
  }
}


void stop() {

  in.close();
  minim.stop();
  super.stop();
}