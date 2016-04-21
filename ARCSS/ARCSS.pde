import fingertracker.*;
import SimpleOpenNI.*;
import processing.net.*;

Client c;
FingerTracker fingers;
SimpleOpenNI kinectNI;

PImage depthImg;
PImage waterTexture;
PImage sandTexture;
PImage grassTexture;
PImage factory, farm, forest, volcano;

boolean dragging = false;

int minDepth = 1260;
int maxDepth = 1540;
int waterLevel = 215;

int imgX = -230;
int imgY = -310;
int imgWidth = 1855;
int imgHeight = 1390;
int cropRightX, cropLeftX;
int cropTopY, cropBottomY;

int maxFingerY;
int fingersTotalX, fingersTotalY;
int fingersCount;
int dragingX, dragingY;
boolean haveSeenFingers = false;
int selection;
int oldDragingX, oldDragingY;
int lastMillis;

int[] defaultObjectsUsed = {
};

int lineX, lineY;
boolean simulating = false;
boolean default1used, default2used, default3used, default4used;
//String[] objsClose = {
//};
ArrayList objsClose;

JSONArray objects;
JSONObject effects;

String simOutput = "";

boolean sketchFullScreen() {
  return true;
}

void setup() {
  size(displayWidth, displayHeight);

  lineX = cropLeftX;
  lineY = cropTopY;

  c = new Client(this, "10.0.0.24", 9943);

  fingers = new FingerTracker(this, 640, 480);
  kinectNI = new SimpleOpenNI(this);
  kinectNI.enableDepth();
  kinectNI.setMirror(false);

  depthImg = new PImage(640, 480);

  waterTexture = loadImage("water.jpg");
  sandTexture = loadImage("sand.jpg");
  grassTexture = loadImage("grass.jpg");

  factory = loadImage("factory.png");
  farm = loadImage("farm.png");
  forest = loadImage("forest.png");
  volcano = loadImage("volcano.png");

  objects = new JSONArray();
  effects = loadJSONObject("effects.json");

  default1used = false;
  default2used = false;
  default3used = false;
  default4used = false;

  objsClose = new ArrayList();
  println(objsClose.size());
}

void draw() {

  //MAIN CODE:
  kinectNI.update();
  background(0);

  int[] rawDepth = kinectNI.depthMap();
  for (int i = 0; i < rawDepth.length; i++) {
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      //depthImg.pixels[i] = color(0, map(rawDepth[i], minDepth, maxDepth, 255, 0), map(rawDepth[i], minDepth, maxDepth, 0, 255));
    } else {
      if (i > 1) {
        depthImg.pixels[i] = depthImg.pixels[i - 1]; //error correction
        //depthImg.pixels[i] = color(0); //no error correction
      }
    }

    //Draw the terrain:
    if (rawDepth[i] >= minDepth+waterLevel && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = waterTexture.pixels[i];
    } else if (rawDepth[i] >= minDepth+waterLevel-10 && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = sandTexture.pixels[i];
    } else if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = grassTexture.pixels[i];
    } else {
      depthImg.pixels[i] = color(0, 0, 0);
    }

    if (rawDepth[i] <= minDepth) {
      //depthImg.pixels[i] = color(0);
    }
  }

  depthImg.updatePixels();
  image(depthImg, imgX, imgY, imgWidth, imgHeight);

  fingers.setThreshold(1100);
  fingers.update(rawDepth);

  if (dragging) {
    fingersTotalX = 0;
    fingersTotalY = 0;
    fingersCount = 0;
    for (int i = 0; i < fingers.getNumFingers (); i++) {
      PVector position = fingers.getFinger(i);
      if (position.x > 100 && position.x < 540 && position.y > 50 && position.y < 380) {
        fingersTotalX = fingersTotalX + int(position.x);
        fingersTotalY += position.y;
        fingersCount++;
      }
    }

    fill(255, 0, 0);
    if (fingersCount > 1) {
      oldDragingX = dragingX;
      oldDragingY = dragingY;
      dragingX = int(map(fingersTotalX/fingersCount, 0, 600, 0, width));
      dragingY = int(map(fingersTotalY/fingersCount, 0, 420, 0, height));

      if (oldDragingX < dragingX) {
        dragingX = oldDragingX + 20;
      } else if (oldDragingX > dragingX) {
        dragingX = oldDragingX - 20;
      }

      if (oldDragingY < dragingY) {
        dragingY = oldDragingY + 10;
      } else if (oldDragingY > dragingY) {
        dragingY = oldDragingY - 10;
      }

      rectMode(CENTER);
      ellipse(dragingX, dragingY, 100, 100);
      //dragingX = 0;

      haveSeenFingers = true;
    } else {
      if (haveSeenFingers && lastMillis < millis()-3000) {
        JSONObject object = new JSONObject();
        object.setInt("object", selection);
        object.setInt("x", dragingX);
        object.setInt("y", dragingY);
        objects.append(object);
        println("adding object: " + objects.size());
        haveSeenFingers = false;
        lastMillis = millis();
      }
    }
  }

  //Draw the objects
  for (int i = 0; i < objects.size (); i++) {
    int objx = objects.getJSONObject(i).getInt("x");
    int objy = objects.getJSONObject(i).getInt("y");
    int object = objects.getJSONObject(i).getInt("object");

    if (object == 1) {
      image(factory, objx - 75, objy - 75, 150, 150);
    } else if (object == 2) {
      image(farm, objx - 75, objy - 75, 150, 150);
    } else if (object == 3) {
      image(forest, objx - 75, objy - 75, 150, 150);
    } else if (object == 4) {
      image(volcano, objx - 75, objy - 75, 150, 150);
    }
  }

  noStroke();
  fill(255, 0, 0);
  for (int i = 0; i < fingers.getNumFingers (); i++) {
    PVector position = fingers.getFinger(i);
    //ellipse(position.x - 5, position.y -5, 10, 10);
  }

  //Calibration:
  fill(0);
  stroke(0);
  rect(0, 0, cropLeftX, height);
  rect(width-cropRightX, 0, cropRightX, height);
  rect(0, 0, width, cropTopY);
  rect(0, height-cropBottomY, width, cropBottomY);

  //NETWORK:
  if (c.available() > 0) {
    try {
      String input = c.readString();

      JSONObject json = new JSONObject();
      json = JSONObject.parse(input);
      String sender = json.getString("sender");
      String message = json.getString("message");

      if (sender.equals("remote")) { //Run code specific to what the remote says
        if (message.equals("waterLevel")) {
          int water = json.getInt("waterHeight");
          waterLevel = (water/-1) + 215;
        } else if (message.equals("selected")) {
          print(json.getInt("selection"));
          selection = json.getInt("selection");

          if (selection == 0) {
            dragging = false;
          } else {
            dragging = true;
          }
        } else if (message.equals("getMapData")) {
          String jsonPacket = "{\"sender\":\"core\",\"message\":\"mapData\",\"data\":\"";
          for (int i = 0; i < rawDepth.length; i++) {
            jsonPacket = jsonPacket+ rawDepth + ",";
          }
          jsonPacket = jsonPacket + "\"}";
          //c.write("{\"sender\":\"core\",\"message\":\"mapData\",\"data\":\"" + rawDepth + "\"}");
          c.write(jsonPacket);
        } else if (message.equals("runSim")) {
          simulate();
          simulating = true;
        } else if (message.equals("quitSim")) {
          simulating = false;
        }
      }
    }
    catch(Exception e) {
    }
  }

  //MISC:
  fill(255);
  //text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, 36);

  //println("imgX:" + imgX);
  //println("imgY:" + imgY);
  //println("imgWidth:" + imgWidth);
  //println("imgHeight:" + imgHeight);
  //println(waterLevel);

  if (simulating) {
    background(0);
    lineX += 30;
    lineY += 25;
    fill(255, 0, 0);
    stroke(255, 0, 0);
    line(lineX, 0, lineX, height);
    line(0, lineY, width, lineY);

    fill(0);
    for (int i = 0; i < objects.size (); i++) {
      int objx = objects.getJSONObject(i).getInt("x");
      int objy = objects.getJSONObject(i).getInt("y");
      ellipse(objx, objy, 100, 100);
    }
  } else {
    lineX = 0;
    lineY = 0;
  }
}

void simulate() {
  println(objects.size());
  for (int i = 0; i < objects.size (); i++) {

    println(objects);
    int object = objects.getJSONObject(i).getInt("object");
    //println("OBJECT: " + object);

    JSONObject objectJSON = effects.getJSONObject(str(object));

    if (objectJSON.hasKey("default")) {

      if (object == 1 && default1used == false) {
        simOutput += objectJSON.getString("default");
        default1used = true;
      } else if (object == 2 && default2used == false) {
        simOutput += objectJSON.getString("default");
        default2used = true;
      } else if (object == 3 && default3used == false) {
        simOutput += objectJSON.getString("default");
        default3used = true;
      } else if (object == 4 && default4used == false) {
        simOutput += objectJSON.getString("default");
        default4used = true;
      }
    }

    for (int j = 0; j < objects.size (); j++) {
      int objectJ = objects.getJSONObject(j).getInt("object");
      if (object != objectJ) {

        int firstX, firstY, secondX, secondY;
        firstX = objects.getJSONObject(i).getInt("x");
        firstY = objects.getJSONObject(i).getInt("y");
        secondX = objects.getJSONObject(j).getInt("x");
        secondY = objects.getJSONObject(j).getInt("y");
        float distance = sqrt(((secondX-firstX)*(secondX-firstX))+((secondY-firstY)*(secondY-firstY)));

        if (distance < 400) {
          println("OBJECT TYPE " + object + " IS CLOSE TO OBJECT TYPE " + objectJ);

          if (objectJSON.hasKey(str(objectJ))) {
            println(objectJSON.getString(str(objectJ)));
            if (simOutput.indexOf(objectJSON.getString(str(objectJ))) == -1) {
              simOutput += objectJSON.getString(str(objectJ));
            }
          }

          JSONObject effectObject = effects.getJSONObject("4");
          println("STRING 1: " + effectObject);
        }
      }
    }
  }

  c.write("{\"sender\":\"core\",\"message\":\"simOutputData\",\"data\":\"" + simOutput +"\"}");
  println("send sim message: " + simOutput);
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      //
      println(simOutput);
    } else if (keyCode == DOWN) {
      //
    }
  } else if (key == 'a') {
    minDepth = constrain(minDepth+10, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth-10, 0, maxDepth);
  } else if (key == 'z') {
    maxDepth = constrain(maxDepth+10, minDepth, 2047);
  } else if (key =='x') {
    maxDepth = constrain(maxDepth-10, minDepth, 2047);
  } else if (key =='q') {
    waterLevel = waterLevel + 5;
  } else if (key =='w') {
    waterLevel = waterLevel - 5;
  } else if (key == 'e') {
    imgX = imgX + 5;
  } else if (key == 'r') {
    imgX = imgX - 5;
  } else if (key == 'd') {
    imgY = imgY + 5;
  } else if (key == 'f') {
    imgY = imgY - 5;
  } else if (key == 'c') {
    imgWidth = imgWidth + 5;
  } else if (key == 'v') {
    imgWidth = imgWidth - 5;
  } else if (key == 't') {
    imgHeight = imgHeight + 5;
  } else if (key == 'y') {
    imgHeight = imgHeight - 5;
  } else if (key == 'g') {
    cropLeftX += 5;
  } else if (key == 'h') {
    cropLeftX -= 5;
  } else if (key == 'b') {
    cropTopY += 5;
  } else if (key == 'n') {
    cropTopY -= 5;
  } else if (key == 'u') {
    cropRightX += 5;
  } else if (key == 'i') {
    cropRightX -= 5;
  } else if (key == 'j') {
    cropBottomY += 5;
  } else if (key == 'k') {
    cropBottomY -= 5;
  } else if (key == 'm') {
    objects.remove(objects.size() - 1);
  }
}

void loadTestObjects() {
  for (int i = 1; i < 4; i++) { //don't even...
    JSONObject object = new JSONObject(); 
    object.setString("object", "factory"); 
    object.setInt("x", 200 * i); 
    object.setInt("y", 100 * i); 
    objects.append(object);
  }
}
