/*
.Change number of networks who multiply
.Change randomness added to networks (maytbe based off of score)
.Change threshold for networks doing cetain actions (probably fine at 0 tho -> just teach the network to make unnecessary actions -ve)
.Change number of networks present
*/

ArrayList<ArrayList<node>> standardNetwork = new ArrayList<ArrayList<node>>();
ArrayList<Integer> stdNetDim = new ArrayList<Integer>();
int nEntity = 30;

ArrayList<body> bodies = new ArrayList<body>();
int roundNum = 0;
map cMap;

float maxTime = 30.0*60.0;  //Number of frames each round runs for
float curTime = 0;         //Current time in the round

boolean showNet = false;
boolean reduceVis = false;

//Important Parameters
//pass

void setup(){
    size(800,800);//fullScreen();

    frameRate(600);

    setStandardNetwork();
    createNewMap(10, 100.0);
    createNewBody(standardNetwork, nEntity, 1.0, true);
}
void draw(){
    background(60,60,60);
    updateTime();
    updateMap();
    updateBodies();
    showNetworks(1.0);

    checkRoundEnd();

    bodies.get(0).cNetwork.bugFixVals();
    overlay();
    //println(standardNetwork.get(0).get(0).weights);
    //println("---");
}
void keyPressed(){
    if(key == '1'){
        showNet = !showNet;
    }
    if(key == '2'){
        reduceVis = !reduceVis;
    }
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
    textAlign(LEFT);
    textSize(15);
    fill(255);
    //FrameRate
    text(frameRate, 30,30);
    //Round number
    textSize(20);
    text("Round; "+roundNum, 30,50);
    textAlign(CENTER);
    //Current time
    text("Time; "+curTime, width/2.0,50);
    //Max time
    text("TimeEnd; "+maxTime, width/2.0 +width/4.0,50);
    popStyle();
}
void updateMap(){
    calcMap();
    drawMap();
}
void drawMap(){
    cMap.display();
}
void calcMap(){
    cMap.checkFlagCollision();
}
void updateBodies(){
    calcBodies();
    drawBodies();
}
void calcBodies(){
    for(int i=0; i<bodies.size(); i++){
        bodies.get(i).calcState();
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

    network cNetwork;
    float score = 0;
    ArrayList<Float> inputs = new ArrayList<Float>();

    int cFlag   = 0;        //Current flag it is personally on
    float nTime = maxTime;  //Time course is finished in (defaulted to max time, changed if finish in less)
    boolean finished = false;

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
        setInputs();
    }

    void display(){
        if(reduceVis){
            segments.get(0).display();
        }
        else{
            displaySegments();
            displayParameters();
        }
    }
    void calcState(){
        tLeft   = false;
        tRight  = false;
        throttle= false;
        brake   = false;
        reverse = false;    //Disabled in current version, bugs out weirdly
        //##### NETWORK CONTROLS FROM HERE ######
        /*
        //LIST METHOD
        //-----------
        ArrayList<Integer> action = cNetwork.runNetwork(inputs);
        for(int i=0; i<action.size(); i++){
            if(action.get(i) == 0){
                tLeft = true;}
            if(action.get(i) == 1){
                tRight = true;}
            if(action.get(i) == 2){
                throttle = true;}
            if(action.get(i) == 3){
                brake = true;}
            //if(4){
            //    reverse = true;}
        }
        */
        //PROBABILITY METHOD
        //------------------
        int action = cNetwork.runNetwork(inputs);
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
        //println("Action -> ", action);
    }
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
    void setInputs(){
        /*
        Input values for the network.
        If parsed by reference, then will only need to set this once for each creature

        ## HOPEFULLY ONLY NEED TO RUN ONCE, BUT MAY NEED TO RUN EACH TIME NETWORK IS CALCULATED ##
        */
        inputs.clear();
        inputs.add( cMap.flags.get(cFlag).pos.x ); //FlagPos
        inputs.add( cMap.flags.get(cFlag).pos.y );
        inputs.add( oPos.x );                                               //Pos
        inputs.add( oPos.y );
        inputs.add( vel.x );                                                //Vel
        inputs.add( vel.y );
        inputs.add( force.x );                                              //Force
        inputs.add( force.y );
        inputs.add( wCurAng );                                              //wTheta
        inputs.add( cMap.flags.get(cFlag).r );     //FlagR

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

    map(int flagNumber, float border){
        generateMap(flagNumber, border);
    }

    void display(){
        displayFlags();
        displayCollisionRad();
    }
    void displayFlags(){
        pushStyle();
        for(int i=0; i<flags.size()-1; i++){
            flags.get(i).display();
        }
        popStyle();
    }
    void displayCollisionRad(){
        pushStyle();
        noFill();
        for(int i=0; i<flags.size()-1; i++){
            ellipse( flags.get(i).pos.x, flags.get(i).pos.y, r,r );
        }
        popStyle();
    }
    void checkFlagCollision(){
        for(int i=0; i<bodies.size(); i++){
            if(bodies.get(i).cFlag != flags.size()-1){
                float d = sqrt( pow(flags.get(bodies.get(i).cFlag).pos.x - bodies.get(i).segments.get(0).pos.x,2) + pow(flags.get(bodies.get(i).cFlag).pos.y - bodies.get(i).segments.get(0).pos.y,2) );
                if(d < r/2.0){
                    bodies.get(i).cFlag++;
                }
            }
        }
    }
    void generateMap(int n, float d){
        /*
        for(int i=0; i<n; i++){
            flag newFlag = new flag( new PVector(random(d,width-d), random(d,height-d)), i );
            flags.add(newFlag);
        }
        flag newFlag = new flag( new PVector(width/2.0, height/2.0), n );   //Place holder flag for end of game
        flags.add(newFlag);
        */
        generateSit1();
    }
    void generateSit1(){
        flag newFlag0 = new flag( new PVector(100, 100), 0 );
        flags.add(newFlag0);
        flag newFlag1 = new flag( new PVector(width -100, height/2.0), 1 );
        flags.add(newFlag1);
        flag newFlag2 = new flag( new PVector(width -100, height -100), 2 );
        flags.add(newFlag2);
        flag newFlag3 = new flag( new PVector(width/2.0, 100), 3 );
        flags.add(newFlag3);
        flag newFlag4 = new flag( new PVector(width/2.0, height -100), 4 );
        flags.add(newFlag4);
        flag newFlag5 = new flag( new PVector(100, height/2.0), 5 );
        flags.add(newFlag5);
        flag newFlag6 = new flag( new PVector(width -100, 100), 6 );
        flags.add(newFlag6);
        flag newFlag7 = new flag( new PVector(100, height -100), 7 );
        flags.add(newFlag7);
        //PlaceHolder
        flag newFlagP = new flag( new PVector(width/2.0, height/2.0), 8 );   //Place holder flag for end of game
        flags.add(newFlagP);
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
        if(reduceVis){
            //pass
        }
        else{
            ellipse(pos.x, pos.y, r, r);
            fill(0,0,0);
            text(floor(n), pos.x, pos.y);
        }
        popStyle();
    }
}

/*
To adapt to an entity, lots of mentions of "networks" should be replaced with "bodies.cNetwork" if bodies stores
the list of entities and cNetwork is that entity's network. Also, when "networks.get(...)" are removed, a body
should be removed instead, and equally when a network is created, a body should be create and assigned that network
instead.
*/

void updateTime(){
    curTime++;
}
void createNewMap(int n, float border){
    map newMap = new map(n, border);
    cMap = newMap;
}
void checkRoundEnd(){
    /*
    Checks if a round should end
    */
    winnerCheck();
    if(curTime >= maxTime){
        //Mate entities
        buildNextGeneration(10,2);
        //Make new flags
        createNewMap(10, 100.0);
        //Reset time
        curTime = 0;
        roundNum++;
    }
}
void winnerCheck(){
    /*
    Checks for bodies who have finished
    */
    for(int i=0; i<bodies.size(); i++){
        if(!bodies.get(i).finished){
            if(bodies.get(i).cFlag == cMap.flags.size()-1){
                bodies.get(i).nTime += curTime - maxTime;    //## MAKE SURE DOES NOT PARSE BY REFERENCE -> WANT A COPY OF JUST THIS MOMENT ##
                bodies.get(i).finished = true;
            }
        }
    }
}
void calcScores(){
    /*
    Finds scores for all entities
    */
    float distWeighting = -1.0;      //How much of an impact each factor has on an entity's overall score
    float flagWeighting =  1000.0;     //sign to show if it improve or worsens score
    float timeWeighting = -100.0;    //
    for(int i=0; i<bodies.size(); i++){
        float distance = sqrt( pow(bodies.get(i).oPos.x - cMap.flags.get(bodies.get(i).cFlag).pos.x, 2) + pow(bodies.get(i).oPos.y - cMap.flags.get(bodies.get(i).cFlag).pos.y, 2) );
        float wFlag    = bodies.get(i).cFlag;
        float wTime    = bodies.get(i).nTime;
        bodies.get(i).score = distWeighting*(distance) + flagWeighting*(wFlag) + timeWeighting*(wTime);
    }
}
void setStandardNetwork(){
    /*
    Specifies the network dimensions for the creatures; Change manually for whatever you want
    */
    standardNetwork.clear();
    stdNetDim.clear();
    stdNetDim.add(10);stdNetDim.add(8);stdNetDim.add(8);stdNetDim.add(6);stdNetDim.add(6);stdNetDim.add(4);
    for(int i=0; i<stdNetDim.size(); i++){
        standardNetwork.add( new ArrayList<node>() );
        for(int j=0; j<stdNetDim.get(i); j++){
            node newNode = new node();
            newNode.bias = 0.0;
            if(i != stdNetDim.size()-1){
                for(int z=0; z<stdNetDim.get(i+1); z++){
                    newNode.weights.add(0.0);
                }
            }
            standardNetwork.get(i).add(newNode);
        }
    }
}
void createNewBody(ArrayList<ArrayList<node>> baseNet, int n, float quality, boolean fresh){
    //Quality is based off score, and various how much randomness is introduced into offspring networks
    float r = 100.0;
    for(int i=0; i<n; i++){
        float dTheta = random(0,2.0*PI);
        body newBody        = new body(new PVector(width/2.0 + r*cos(dTheta),height/2.0 + r*sin(dTheta)), pow(10,3), 60.0, 6);
        network newNetwork  = new network(baseNet, quality, fresh);
        newBody.cNetwork    = newNetwork;
        bodies.add(newBody);
    }
}
ArrayList<ArrayList<node>> mergeNetworks(ArrayList<network> mergers){
    /*
    Takes a set of networks and averages their values (weights and biases)
    */
    ArrayList<ArrayList<node>> newNetwork = new ArrayList<ArrayList<node>>();
    for(int i=0; i<stdNetDim.size(); i++){
        newNetwork.add( new ArrayList<node>() );
        for(int j=0; j<stdNetDim.get(i); j++){
            node newNode = new node();
            float avgBias = 0;
            for(int p=0; p<mergers.size(); p++){
                avgBias += mergers.get(p).layers.get(i).get(j).bias;
            }
            avgBias /= mergers.size();
            newNode.bias = avgBias;
            if(i != stdNetDim.size()-1){
                for(int z=0; z<stdNetDim.get(i+1); z++){
                    float avgWeight = 0;
                    for(int p=0; p<mergers.size(); p++){
                        avgWeight += mergers.get(p).layers.get(i).get(j).weights.get(z);
                    }
                    avgWeight /= mergers.size();
                    newNode.weights.add(avgWeight);
                }
            }
            newNetwork.get(i).add(newNode);
        }
    }
    return newNetwork;
}
void buildNextGeneration(int n, int m){
    /*
    Take the top n best performers, merge them in groups of m, and create k networks from each of
    these groups.
    You must make sure the groups create appropriate number of offspring

    EXAMPLE

    30 entities
    Take top 10 winners             (n)
    Pair in 5 groups of 2           (n/m and m)
    each group makes 6 offspring    (k)

    */

    ArrayList<body> winners = new ArrayList<body>();
    winners.clear();    //##Probably not needed just a precaution for loops
    int k = nEntity*m / n;
    //Calc scores
    calcScores();
    //Sort by scores
    for(int i=0; i<n; i++){
        int wInd = 0;
        for(int j=0; j<bodies.size(); j++){
            if(bodies.get(j).score > bodies.get(wInd).score){
                wInd = j;
            }
        }
        winners.add( bodies.get(wInd) );
        bodies.remove(wInd);
    }
    println("Top score; ", winners.get(0).score);
    //Remove old
    bodies.clear();
    //Create new ones
    for(int i=0; i<n/m; i++){
        ArrayList<network> mergeSet = new ArrayList<network>();
        mergeSet.add(winners.get(i).cNetwork);mergeSet.add(winners.get(i+1).cNetwork);mergeSet.add(winners.get(i+2).cNetwork);
        createNewBody(mergeNetworks(mergeSet), k, 0.2*(i+1), false);
        mergeSet.clear();
    }
}
void showNetworks(float sf){
    if(showNet){
        for(int i=0; i<bodies.size(); i++){
            float dOrig = sf*100.0;
            PVector orig = new PVector(10+((dOrig*i)%width), dOrig*ceil((dOrig*(i+1)) / width));
            bodies.get(i).cNetwork.display(orig, sf);
        }
    }
}
class network{
    ArrayList<ArrayList<node>> layers = new ArrayList<ArrayList<node>>();
    ArrayList<ArrayList<node>> bNetwork;

    float rFactor;  //Determines how extreme the random change to the weights is

    network(ArrayList<ArrayList<node>> basisNetwork, float randomFactor, boolean fresh){
        bNetwork = basisNetwork;
        rFactor  = randomFactor;
        if(fresh){
            createNetworkFresh();
        }
        else{
            createNetwork();
        }
    }

    void display(PVector origin, float sFac){
        /*
        .---.--.
        |   |  |
        #   |  |
        |   |  |
        .---.--.
        Starts origin at the middle on the left, and will display the network according to a rough size scale factor (sFac), such that relatively it looks
        good, but at a given size scale factor. Actual size depends on the network size.
        */
        int mWidth  = layers.size();
        int mHeight = layers.get(0).size();
        for(int i=1; i<mWidth; i++){
            if(layers.get(i).size() > mHeight){
                mHeight = layers.get(i).size();
            }
        }
        float sNode  = 10.0*sFac;
        float sLayer = 20.0*sFac;
        float wNode  = 4.0 *sFac;
        pushStyle();
        for(int i=0; i<layers.size(); i++){                                     //Layers
            for(int j=0; j<layers.get(i).size(); j++){                          //Nodes
                for(int z=0; z<layers.get(i).get(j).weights.size(); z++){       //Weights
                    layers.get(i).get(j).displayConnection( findNodePos(origin, i, j, sLayer, sNode), findNodePos(origin, i+1, z, sLayer, sNode), z );
                }
                layers.get(i).get(j).displayNode( findNodePos(origin, i, j, sLayer, sNode), wNode );
            }
        }
        popStyle();
    }
    void bugFixVals(){
        //Find avg weight
        float avgWeight = 0;
        float n = 0;
        for(int i=0; i<layers.size(); i++){
            for(int j=0; j<layers.get(i).size(); j++){
                for(int z=0; z<layers.get(i).get(j).weights.size(); z++){
                    avgWeight += layers.get(i).get(j).weights.get(z);
                    n++;
                }
            }
        }
    }
    PVector findNodePos(PVector origin, int nX, int nY, float sLayer, float sNode){
        //nX = layer it is in
        //nY = number in layer
        float n = layers.get(nX).size();  //Nodes in this layer
        float d = 0.5*(n-1) *sNode;
        return new PVector(origin.x +nX*sLayer, origin.y +(d - nY*sNode));
    }
    void createNetworkFresh(){
        layers.clear();
        for(int i=0; i<bNetwork.size(); i++){
            layers.add( new ArrayList<node>() );
            for(int j=0; j<bNetwork.get(i).size(); j++){
                node newNode = new node();
                newNode.bias = random(-5.0,5.0);
                for(int z=0; z<bNetwork.get(i).get(j).weights.size(); z++){
                    newNode.weights.add( random(-1.0,1.0) );
                }
                layers.get(i).add(newNode);
            }
        }
    }
    void createNetwork(){
        layers.clear();
        for(int i=0; i<bNetwork.size(); i++){
            layers.add( new ArrayList<node>() );
            for(int j=0; j<bNetwork.get(i).size(); j++){
                node newNode = new node();
                newNode.bias = (bNetwork.get(i).get(j).bias) + (random(-1.0*rFactor,1.0*rFactor));
                for(int z=0; z<bNetwork.get(i).get(j).weights.size(); z++){
                    newNode.weights.add( bNetwork.get(i).get(j).weights.get(z) + random(-1.0*rFactor,1.0*rFactor) );
                }
                layers.get(i).add(newNode);
            }
        }
    }
    //## Switch these parameters out for whatever the creature takes as inputs ##
    Integer runNetwork(ArrayList<Float> inputs){
        /*
        Runs one cycle of the network to find an output for this given situation.
        The network is as follows;

        EXAMPLE;

        Inputs      Working/Hidden  Output
        ------      --------------  ------
        flagX           ...         Turn Left      Probabilities -> Highest here taking the role as the action taken
        flagY           ...         Turn Right
        posX            ...         Throttle
        posY            ...         Brake
        velX            ...
        velY            ...
        forceX          ...
        forceY          ...
        wheelTheta      ...
        flagR           ...

        Returned integer indicates action to be take, e.g
        0 = Turn Left
        1 = Turn Right
        2 = Throttle
        3 = Brake
        */

        //Set intial weights based on system
        for(int i=0; i<layers.get(0).size(); i++){
            layers.get(0).get(i).runningVal = inputs.get(i);
        }
        /*
        //ACTION LIST METHOD
        //-------------------
        //Aims to make wanted actions positive and unwanted actions negative

        //Finds the weights of the final output nodes
        for(int i=1; i<layers.size(); i++){  //For each layer
            for(int j=0; j<layers.get(i).size(); j++){  //For each node in layer
                float cTotal = 0;
                for(int z=0; z<layers.get(i-1).size(); z++){  //Find its running value total
                    cTotal += (layers.get(i-1).get(z).runningVal) * (layers.get(i-1).get(z).weights.get(j));
                }
                layers.get(i).get(j).runningVal = cTotal;   //**Try to stop cTotal being passed by reference DOUBLE CHECK THIS**
            }
        }
        //Finds highest probability output node
        ArrayList<Integer> action = new ArrayList<Integer>(); //Assume 0 is correct initially
        float totalWeights = 0;
        for(int i=0; i<layers.get(layers.size()-1).size(); i++){
            totalWeights += layers.get(layers.size()-1).get(i).runningVal;
        }
        float threshold = 0.0;
        //println(totalWeights);
        for(int i=0; i<layers.get(layers.size()-1).size(); i++){
            //println("i -> ", layers.get(layers.size()-1).get(i).runningVal / totalWeights );
            if(layers.get(layers.size()-1).get(i).runningVal / totalWeights >= threshold){
                action.add(i);
            }
        }
        */
        //PROBABILITY METHOD
        //------------------
        //Aims to make output node value closer to 0 for less likely situations

        //Finds the weights of the final output nodes
        for(int i=1; i<layers.size(); i++){  //For each layer
            for(int j=0; j<layers.get(i).size(); j++){  //For each node in layer
                float cTotal = 0;
                for(int z=0; z<layers.get(i-1).size(); z++){  //Find its running value total
                    cTotal += (layers.get(i-1).get(z).runningVal) * (layers.get(i-1).get(z).weights.get(j));
                }
                layers.get(i).get(j).runningVal = cTotal;   //**Try to stop cTotal being passed by reference DOUBLE CHECK THIS**
            }
        }
        //Finds highest probability output node
        int action = 0;
        float totalWeights = 0;
        for(int i=0; i<layers.get(layers.size()-1).size(); i++){
            totalWeights += abs(layers.get(layers.size()-1).get(i).runningVal);
        }
        //println(totalWeights);
        float rNum = random(0.0,1.0);
        ArrayList<Float> rSeq = new ArrayList<Float>(); //Probability
        ArrayList<Integer> aSeq = new ArrayList<Integer>(); //Associated action for probaility
        //## CAN SHRINK TO JUST ONE LIST BY HAVING IT STORE AND SORT INDICES ##
        //Put all probabilites here
        for(int i=0; i<layers.get(layers.size()-1).size(); i++){
            rSeq.add( abs(layers.get(layers.size()-1).get(i).runningVal) / totalWeights );
            aSeq.add(i);
        }
        //Bubblesort
        for(int i=0; i<rSeq.size(); i++){
            boolean sorted = true;
            for(int j=0; j<rSeq.size()-1; j++){
                if(rSeq.get(j) < rSeq.get(j+1)){
                    sorted = false;
                    float rVal = rSeq.get(j+1);rSeq.remove(j+1);
                    rSeq.add(j, rVal);
                    int aVal = aSeq.get(j+1);aSeq.remove(j+1);
                    aSeq.add(j, aVal);
                }
            }
            if(sorted){
                break;
            }
        }
        //Determine outcome
        for(int i=0; i<rSeq.size(); i++){
            rNum -= rSeq.get(i);
            if(rNum <= 0){
                action = aSeq.get(i);
                break;
            }
        }

        return action;
    }
}
class node{
    ArrayList<Float> weights = new ArrayList<Float>();
    
    float bias       = 0;
    float runningVal = 0;

    node(){
        //Weights randomised during creation by the network
    }

    void displayNode(PVector pos, float r){
        pushStyle();
        fill(255*( abs(bias/2.0) +0.3));
        ellipse(pos.x, pos.y, r, r);
        popStyle();
    }
    void displayConnection(PVector pos1, PVector pos2, int weightNum){
        pushStyle();
        float m = abs(weights.get(weightNum) / 2.0) + 0.2;
        if(weights.get(weightNum) < 0){
            stroke(255,0,0, 255*m);}
        else{
            stroke(0,255,0, 255*m);}
        //stroke(255*cos(2.0*PI*m),255*sin(2.0*PI*m),0);
        strokeWeight(1);
        line(pos1.x, pos1.y, pos2.x, pos2.y);
        popStyle();
    }
}
