/*
To adapt to an entity, lots of mentions of "networks" should be replaced with "bodies.cNetwork" if bodies stores
the list of entities and cNetwork is that entity's network. Also, when "networks.get(...)" are removed, a body
should be removed instead, and equally when a network is created, a body should be create and assigned that network
instead.

####
NEEDS TO BE UPDATED WITH NEW CHANGES TO PROBABILITY OF ACTION
####
*/

ArrayList<network> networks = new ArrayList<network>(); //## In practice, all of these will be inside an entity
ArrayList<Float> scores     = new ArrayList<Float>();   //##
ArrayList<Float> inputs     = new ArrayList<Float>();   //## This will be manually assigned to each entity when made

ArrayList<ArrayList<node>> standardNetwork = new ArrayList<ArrayList<node>>();
ArrayList<Integer> stdNetDim = new ArrayList<Integer>();

int nEntity = 30;

void setup(){
    size(800,800);
    setStandardNetwork();
    setInputs();

    createNewNetworks(standardNetwork, nEntity);
    randomiseScores();
}
void draw(){
    background(60,60,60);
    showNetworks(1.0);
    overlay();
}
void keyPressed(){
    if(key == '1'){
        buildNextGeneration(15,3);
    }
    if(key == '2'){
        //pass
    }
}

void overlay(){
    pushStyle();
    fill(255);
    text(frameRate, 30,30);
    popStyle();
}
void randomiseScores(){
    //## PURELY FOR TESTING PURPOSES
    for(int i=0; i<nEntity; i++){
        scores.add(random(-10.0,10.0));
    }
}
void setStandardNetwork(){
    /*
    Specifies the network dimensions for the creatures; Change manually for whatever you want
    */
    standardNetwork.clear();
    stdNetDim.clear();
    stdNetDim.add(10);stdNetDim.add(8);stdNetDim.add(8);stdNetDim.add(4);
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
void setInputs(){
    /*
    Input values for the network.
    If parsed by reference, then will only need to set this once for each creature
    */
    /*
    EXAMPLE

    inputs.add( maps.get(cMap).flags.get(maps.get(cMap).cFlag).pos.x ); //FlagPos
    inputs.add( maps.get(cMap).flags.get(maps.get(cMap).cFlag).pos.y );
    inputs.add( pos.x );                                                //Pos
    inputs.add( pos.y );
    inputs.add( vel.x );                                                //Vel
    inputs.add( vel.y );
    inputs.add( force.x );                                              //Force
    inputs.add( force.y );
    inputs.add( wTheta );                                               //wTheta
    inputs.add( maps.get(cMap).flags.get(maps.get(cMap).cFlag).r );     //FlagR
    */
    inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);inputs.add(0.0);

}
void createNewNetworks(ArrayList<ArrayList<node>> baseNet, int n){
    for(int i=0; i<n; i++){
        network newNetwork = new network(baseNet, 10.0);
        networks.add(newNetwork);
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
    Take top 15 winners             (n)
    Pair in 5 groups of 3           (n/m and m)
    each group makes 6 offspring    (k)

    */

    ArrayList<network> winners = new ArrayList<network>();
    winners.clear();    //##Probably not needed just a precaution for loops
    int k = (nEntity * m) / n;
    //Calc scores
    //pass #### NEEDS DOING WHEN COMBINED -> SPECIFIC TO EACH CASE ####
    //Sort by scores
    for(int i=0; i<n; i++){
        int wInd = 0;
        for(int j=0; j<networks.size(); j++){
            if(scores.get(j) > scores.get(wInd)){
                wInd = j;
            }
        }
        winners.add( networks.get(wInd) );
        networks.remove(wInd);
        scores.remove(wInd);
    }
    //Remove old
    networks.clear();
    scores.clear();
    //Create new ones
    for(int i=0; i<n/m; i++){
        ArrayList<network> mergeSet = new ArrayList<network>();
        mergeSet.add(winners.get(i));mergeSet.add(winners.get(i+1));mergeSet.add(winners.get(i+2));
        createNewNetworks(mergeNetworks(mergeSet), k);
        mergeSet.clear();
    }
}
void showNetworks(float sf){
    for(int i=0; i<networks.size(); i++){
        float dOrig = sf*100.0;
        PVector orig = new PVector(10+((dOrig*i)%width), dOrig*ceil((dOrig*(i+1)) / width));
        networks.get(i).display(orig, sf);
    }
}
class network{
    ArrayList<ArrayList<node>> layers = new ArrayList<ArrayList<node>>();
    ArrayList<ArrayList<node>> bNetwork;

    float rFactor;  //Determines how extreme the random change to the weights is

    network(ArrayList<ArrayList<node>> basisNetwork, float randomFactor){
        bNetwork = basisNetwork;
        rFactor  = randomFactor;
        createNetwork();
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
    PVector findNodePos(PVector origin, int nX, int nY, float sLayer, float sNode){
        //nX = layer it is in
        //nY = number in layer
        float n = layers.get(nX).size();  //Nodes in this layer
        float d = 0.5*(n-1) *sNode;
        return new PVector(origin.x +nX*sLayer, origin.y +(d - nY*sNode));
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
        int action = 0; //Assume 0 is correct initially
        for(int i=1; i<layers.get(layers.size()-1).size(); i++){
            boolean cond1 = layers.get(layers.size()-1).get(i).runningVal > layers.get(layers.size()-1).get(action).runningVal;
            if(cond1){
                action = i;
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
        line(pos1.x, pos1.y, pos2.x, pos2.y);
        popStyle();
    }
}
