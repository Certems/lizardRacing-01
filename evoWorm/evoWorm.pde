ArrayList<body> bodies = new ArrayList<body>();
ArrayList<map> maps = new ArrayList<map>();

int roundNum = 0;
int cMap = 0;

//Important Parameters
//pass

void setup(){
    size(800,800);//fullScreen();

    body newBody = new body(new PVector(width/2.0, height/2.0), pow(10,3), 60.0, 6);
    bodies.add(newBody);

    map newMap = new map(10, 200.0);
    maps.add(newMap);
}
void draw(){
    background(60,60,60);
    updateMap(cMap);
    updateBodies();
    overlay();
}
void keyPressed(){
    if(key == 'a'){
        if(bodies.get(0).tLeft == false){
            bodies.get(0).tLeft = !bodies.get(0).tLeft;
        }
    }
    if(key == 'd'){
        if(bodies.get(0).tRight == false){
            bodies.get(0).tRight = !bodies.get(0).tRight;
        }
    }
    if(key == 'w'){
        if(bodies.get(0).throttle == false){
            bodies.get(0).throttle = !bodies.get(0).throttle;
        }
    }
    if(key == 's'){
        if(bodies.get(0).brake == false){
            bodies.get(0).brake = !bodies.get(0).brake;
        }
    }
    if(key == '1'){
        //bodies.get(0).reverse = !bodies.get(0).reverse; 
    }
}
void keyReleased(){
    if(key == 'a'){
        bodies.get(0).tLeft = !bodies.get(0).tLeft;
    }
    if(key == 'd'){
        bodies.get(0).tRight = !bodies.get(0).tRight;
    }
    if(key == 'w'){
        bodies.get(0).throttle = !bodies.get(0).throttle;
    }
    if(key == 's'){
        bodies.get(0).brake = !bodies.get(0).brake;
    }
}

void overlay(){
    pushStyle();
    fill(255);
    text(frameRate, 30,30);
    text("Round; "+roundNum, 30,60);
    popStyle();
}
void updateMap(int num){
    calcMap(num);
    drawMap(num);
}
void drawMap(int n){
    maps.get(n).display();
}
void calcMap(int n){
    maps.get(n).checkFlagCollision();
}
void updateBodies(){
    calcBodies();
    drawBodies();
}
void calcBodies(){
    for(int i=0; i<bodies.size(); i++){
        //bodies.get(i).calcState();
        bodies.get(i).updateForce();
        bodies.get(i).updateAcc();
        bodies.get(i).updateVel();
        bodies.get(i).updatePos();
        bodies.get(i).updateControls();
    }
}
void drawBodies(){
    for(int i=0; i<bodies.size(); i++){
        bodies.get(i).display();
    }
}

class body{
    ArrayList<bodySegment> segments = new ArrayList<bodySegment>();

    boolean tLeft   = false;
    boolean tRight  = false;
    boolean throttle= false;
    boolean brake   = false;
    boolean reverse = false;

    PVector oPos;
    PVector vel     = new PVector(0,0);
    PVector acc     = new PVector(0,0);
    PVector force   = new PVector(0,0);
    PVector dir     = new PVector(0,-1);

    PVector score = new PVector(0,0,0); //How well the body performed, 1st= distance from flag, 2nd= #flags encounetred, 3rd= time for all flags

    float wMaxAng   = PI/3.0;       //Max wheel angle
    float wCurAng   = 0.0;          //Current wheel angle
    float wTurnRate = PI/160.0;     //Rate at which wheels can turn

    float eMaxForce = 50;           //Max force engine can produce
    float eCurForce = 0.0;          //Current force engine is producing
    float eIncRate  = 1.0;          //Rate at which engine force increases

    float frCoeff       = 1.0;
    float brakeCoeff    = 10.0;

    float m;
    float l;
    float n;
    float r;
    float spd = 0;

    body(PVector originPos, float mass, float length, int segNumber){
        oPos = originPos;
        m = mass;
        l = length;
        n = segNumber;
        r = 1.2*(l/n);
        createSegments();
        updateOpos();
    }

    void display(){
        displaySegments();
        displayParameters();
    }
    /*
    void calcState(){
        tLeft   = false;
        tRight  = false;
        throttle= false;
        brake   = false;
        reverse = false;    //Disabled in current version, bugs out weirdly
        int action = -1;    //##### NETWORK CONTROLS FROM HERE ######
        if(action == 0){
            tLeft = true;}
        if(action == 1){
            tRight = true;}
        if(action == 2){
            throttle = true;}
        if(action == 3){
            brake = true;}
        //if(4){
        //    reverse = true;}
    }
    */
    void displaySegments(){
        for(int i=0; i<segments.size(); i++){
            segments.get(i).display();
        }
    }
    void displayParameters(){
        pushStyle();
        strokeWeight(3);
        //Acceleration direction
        stroke(255,0,0);
        line(oPos.x, oPos.y, oPos.x+200.0*acc.x, oPos.y+200.0*acc.y);
        //Velocity direction
        stroke(0,255,0);
        line(oPos.x, oPos.y, oPos.x+20.0*vel.x, oPos.y+20.0*vel.y);
        //Wheel direction
        stroke(0,0,255);
        if(spd != 0){
        line(oPos.x, oPos.y, oPos.x +20.0*((vel.x)*cos(wCurAng)-(vel.y)*sin(wCurAng))/spd, oPos.y +20.0*((vel.x)*sin(wCurAng)+(vel.y)*cos(wCurAng))/spd);}
        popStyle();
    }
    void updateForce(){
        //Reset
        force.x = 0;
        force.y = 0;
        //Engine torque
        force.x += eCurForce* ((dir.x)*cos(wCurAng) - (dir.y)*sin(wCurAng));
        force.y += eCurForce* ((dir.x)*sin(wCurAng) + (dir.y)*cos(wCurAng));
        //Wheel friction
        force.x -= frCoeff*vel.x;
        force.y -= frCoeff*vel.y;
        //Brakes
        force.x -= brakeCoeff*vel.x;
        force.y -= brakeCoeff*vel.y;
    }
    void updateAcc(){
        acc.x = force.x / m;
        acc.y = force.y / m;
    }
    void updateVel(){
        vel.x += acc.x;
        vel.y += acc.y;

        spd = sqrt( pow(vel.x,2) + pow(vel.y,2) );
        if(spd != 0){
            dir = new PVector(vel.x/spd, vel.y/spd);
        }
    }
    void updatePos(){
        //Move main piece
        segments.get(0).pos.x += vel.x;
        segments.get(0).pos.y += vel.y;
        //Make others folllow
        for(int i=1; i<segments.size(); i++){
            PVector step = new PVector(segments.get(i-1).pos.x -segments.get(i).pos.x, segments.get(i-1).pos.y -segments.get(i).pos.y);
            float d = sqrt( pow(segments.get(i-1).pos.x -segments.get(i).pos.x,2) + pow(segments.get(i-1).pos.y -segments.get(i).pos.y,2) );
            if(d > r){
                segments.get(i).pos.x += step.x*(d-r) / d;
                segments.get(i).pos.y += step.y*(d-r) / d;
            }
        }
    }
    void updateOpos(){
        oPos = segments.get(0).pos;
    }
    void updateControls(){
        if(tLeft){
            wCurAng -= wTurnRate;
            if(wCurAng < -wMaxAng){
                wCurAng = -wMaxAng;
            }
        }
        if(tRight){
            wCurAng += wTurnRate;
            if(wCurAng > wMaxAng){
                wCurAng = wMaxAng;
            }
        }
        if(throttle){
            if(reverse){
                eCurForce -= eIncRate;
                if(eCurForce < -eMaxForce){
                    eCurForce = -eMaxForce;
                }
            }
            else{
                eCurForce += eIncRate;
                if(eCurForce > eMaxForce){
                    eCurForce = eMaxForce;
                }
            }
        }
        if(!throttle){
            if(eCurForce > 0){
                eCurForce -= eIncRate;
                if(eCurForce<0){
                    eCurForce = 0;
                }
            }
            if(eCurForce < 0){
                eCurForce += eIncRate;
                if(eCurForce>0){
                    eCurForce = 0;
                }
            }
        }
    }
    void createSegments(){
        for(int i=0; i<n; i++){
            bodySegment newSegment = new bodySegment( new PVector(oPos.x, oPos.y +i*(l/n)) );
            segments.add(newSegment);
        }
    }
}
class bodySegment{
    PVector pos;

    bodySegment(PVector initPos){
        pos = initPos;
    }

    void display(){
        pushStyle();
        fill(100,100,255);
        ellipse(pos.x, pos.y, 10,10);
        popStyle();
    }
}

class map{
    ArrayList<flag> flags = new ArrayList<flag>();

    float r = 100.0;
    int cFlag = 0;

    map(int flagNumber, float border){
        generateMap(flagNumber, border);
    }

    void display(){
        displayFlag();
        displayCollisionRad();
    }
    void displayFlag(){
        pushStyle();
        flags.get(cFlag).display();
        popStyle();
    }
    void displayCollisionRad(){
        pushStyle();
        noFill();
        ellipse( flags.get(cFlag).pos.x, flags.get(cFlag).pos.y, r,r );
        popStyle();
    }
    void checkFlagCollision(){
        for(int i=0; i<bodies.size(); i++){
            float d = sqrt( pow(flags.get(cFlag).pos.x - bodies.get(i).segments.get(0).pos.x,2) + pow(flags.get(cFlag).pos.y - bodies.get(i).segments.get(0).pos.y,2) );
            if(d < r/2.0){
                cFlag++;
            }
        }
    }
    void generateMap(int n, float d){
        for(int i=0; i<n; i++){
            flag newFlag = new flag( new PVector(random(d,width-d), random(d,height-d)), i );
            flags.add(newFlag);
        }
    }
}
class flag{
    PVector pos;

    float r = 30.0;
    float n;

    flag(PVector position, int flagNum){
        pos = position;
        n = flagNum;
    }

    void display(){
        pushStyle();
        fill(200,200,200);
        textAlign(CENTER);
        textSize(15);
        ellipse(pos.x, pos.y, r, r);
        fill(0,0,0);
        text(floor(n), pos.x, pos.y);
        popStyle();
    }
}