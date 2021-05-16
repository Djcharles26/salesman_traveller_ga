import "dart:math";
import "dart:core";
import 'dart:ui';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class Connection{
  City from, dest;
  int cost;

  Connection(City from,City dest,int cost) {
    this.from = from;
    this.dest = dest;
    this.cost = cost;
  }
}

class City{
  String name;
  Offset point;
  Color color;

  City(name){
    this.name = name;
    this.point = Offset(Random().nextInt(550) + 10.0, Random().nextInt(450) + 10.0);
    this.color = Color.fromRGBO(Random().nextInt(155) + 100, Random().nextInt(155) + 100, Random().nextInt(155) + 100, 1);
  }

  City.clone(City city) {
    this.name = city.name;
    this.point = city.point;
    this.color = city.color;
  }
}

class GNOME {
  List<City> cities;
  String gnomeName = "";
  int distance;
  double fitness;


  GNOME(List<City> cities){
    this.cities = cities;
    for(City city in this.cities) {
      this.gnomeName+= city.name[0];
    }
  }

  bool lessThan(GNOME gnome) {
    return this.distance < gnome.distance;
  }

  static int randNum(int start, int end) {
    int r = end - start;
    int rnum = start + Random().nextInt(r);
    return rnum;
  }

  GNOME mutatedGene(connections) {
    GNOME gnome;
    List<City> citiesTemp = List<City>.from(this.cities);
    while (true) {
      int r = GNOME.randNum(1, citiesTemp.length - 1);
      int r1 = GNOME.randNum(1, citiesTemp.length - 1);
      if (r1 != r) {
        City temp = City.clone(citiesTemp[r]);
        citiesTemp[r] = citiesTemp[r1];
        citiesTemp[r1] = temp;
        break;
      }
    }
    gnome = new GNOME(citiesTemp);
    gnome.calculateDistance(connections);
    return gnome;
  }

  void calculateDistance(List<Connection> connections) {
    int sum = 0;
    for (int i =0; i<cities.length - 1; i++) {
      var connection = connections.firstWhere((element) => 
        element.from.name == this.cities[i].name && element.dest.name == this.cities[i+1].name ||
        element.dest.name == this.cities[i].name && element.from.name == this.cities[i+1].name , orElse: () => null);
      if (connection != null) {
        sum += connection.cost;
      }
    }
    this.distance = sum;

    this.fitness = 1 / distance;
  }

  void normalizeFitness(double sum) {
    this.fitness = this.fitness / sum;
  }

}

class Generation {
  List<GNOME> gnomes;
  int bestDistance;
  GNOME best;
  int number;
  double average;

  Generation(this.number, this.gnomes, this.best, this.bestDistance);

  void calculateAverage() {
    average = 0.0;
    if(gnomes != null) {
      var sum = 0;
      for(var gnome in this.gnomes) {
        sum += gnome.distance;
      }

      average = sum / gnomes.length;
    }
  }
}

class _HomePageState extends State<HomePage> {

  int nCities = 1, popSize = 10, generations = 10;
  int currGen = 0;

  List<City> cities = [];
  List<Connection> connections = [];
  int bestGeneration;
  List<Generation> gens = [];
  GNOME best;
  int bestDistance = 10000000000000;
  ScrollController routeScroll, genScroll, mainScroll;

  @override
  void initState() { 
    super.initState();
    this.routeScroll = new ScrollController(initialScrollOffset:  0.0);
    this.mainScroll = new ScrollController(initialScrollOffset:  0.0);
    this.genScroll = new ScrollController(initialScrollOffset:  0.0);
  }

  List<DropdownMenuItem> getOptions(int max){
    List<DropdownMenuItem> items = [];
    for (int i =1; i<max + 1; i++) {
      items.add(DropdownMenuItem(child: Center(child: Text("$i", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), value: i));
    }
    return items;
  }

  bool repeat(List<City> cities, City city) {
    return cities.firstWhere((element) => element.name == city.name, orElse: ()=> null) != null;
  }

  GNOME generateGnome(City initial) {
    List<City> citiesTemp = [initial];
    while(true) {
      if (citiesTemp.length == nCities) {
        citiesTemp.add(initial);
        break;
      }

      int temp = GNOME.randNum(1, nCities);
      if (!repeat(citiesTemp, this.cities[temp])) {
        citiesTemp.add(this.cities[temp]);
      }
    }
    
    GNOME gnome = GNOME(citiesTemp);
    gnome.calculateDistance(connections);
    return gnome;
  }

  void getBetterGNOME(List<GNOME> population) {
    int best = 100000000;
    GNOME aux;
    for(GNOME p in population) {
      if(p.distance < best) {
        best = p.distance;
        aux = p;
      }
    }
    this.setState(() {
      this.bestDistance = best;
      this.best = aux;
    });
  }

  List<GNOME> generateInitialPopulaton() {
    List<GNOME> population = [];
    GNOME temp;

    double sum = 0;
    for (int i =0; i< popSize; i++) {
      temp = generateGnome(this.cities[0]);
      population.add(temp);
      sum += temp.fitness;
    }

    for (int i=0; i<popSize; i++)  population[i].normalizeFitness(sum);
    
    return population;
  }

  GNOME pickOne(List<GNOME> populations) {
    var index = 0;
    var r = Random().nextDouble();
    while(r > 0) {
      r = r - populations[index].fitness;
      index ++;
    }
    index--;
    return populations[index];
  }

  Future<void> genAlg() async {
    this.setState(() {
      this.best = null;
      this.bestDistance= -1;
      this.gens = [];
      this.currGen = 0;
      this.bestGeneration = 0;
    });

    int gen = 1;
    
    List<GNOME> population = generateInitialPopulaton();
    getBetterGNOME(population);
    Generation newGen = Generation(0, List.from(population), this.best, this.bestDistance);
    newGen.calculateAverage();

    this.setState(() {
      this.gens.add(newGen);
      this.bestGeneration = 0;
    });
    
    await Future.delayed(Duration(seconds: 1), () => {});

    while(gen <= generations) {
      this.setState(() {
        this.currGen = gen;    
      });
     
      List<GNOME> newPopulation = [];
      double sum = 0;
      for (int i=0; i<popSize; i++) {
        GNOME newGen = pickOne(population).mutatedGene(connections);
        newGen.calculateDistance(connections);
        sum += newGen.fitness;
        newPopulation.add(newGen);
      }
      //In this current generation which is better?
      population = newPopulation;

      for (int i=0; i<population.length; i++)  population[i].normalizeFitness(sum);
    
      getBetterGNOME(population);

      Generation newGen = Generation(gen, List.from(population), this.best, this.bestDistance);
      newGen.calculateAverage();

      this.genScroll.jumpTo(this.genScroll.position.maxScrollExtent);

      this.setState(() {
        if (newGen.average <= this.gens[this.bestGeneration].average && newGen.bestDistance <= this.gens[this.bestGeneration].bestDistance) 
          this.bestGeneration = this.gens.length;
        
        this.gens.add(newGen);
      });
      
      gen ++;
      await Future.delayed(Duration(seconds: 1), () => {});
    }
  }  

  void generateCities(){
    this.setState(() {
      this.cities = [];
      this.connections = [];     
    });
    for(int i=0; i<nCities; i++) {
      City city = new City("$i");
      this.setState((){
        cities.add(city);
      });
    }

    for (int i=0; i<nCities - 1; i++) {
      for (int j=i; j < nCities - 1; j++) {
        int random = Random().nextInt(25);
        Connection conn = new Connection(cities[i], cities[j + 1], random);
        this.setState(() {
          connections.add(conn);
        });
      }
    }
  }

  Widget generationDisplay(Generation generation) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Text("Generation ${generation.number}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Best GNOME: ${generation.best.gnomeName}. Cost: ${generation.bestDistance}",  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
          ListTile(
            title: Text("GNOME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            trailing: Text("Distance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: generation.gnomes.length,
              itemBuilder: (ctx,i) {
                Color color = generation.gnomes[i].gnomeName == generation.best.gnomeName ? Colors.red: Colors.black;
                return ListTile(
                  title: Text(generation.gnomes[i].gnomeName, style: TextStyle(fontSize: 16, color: color)),
                  trailing: Text("${generation.gnomes[i].distance}", style: TextStyle(fontSize: 18, color: color)),
                );
              }
            ),
          )
        ],
      ),
    );
  }

  Widget _canvasInfo() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      children: [
        Column(
          children: [
             this.best != null
              ? Text("Best Generation ${this.bestGeneration}. Cost ${this.gens[this.bestGeneration].bestDistance}," +
                "Best Path: ${this.gens[this.bestGeneration].best.gnomeName}, Gen Average: ${this.gens[this.bestGeneration].average}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)
                )
              : SizedBox(width: 0),
            this.best != null 
              ? Text("Current Generation ${this.currGen}. Cost ${this.bestDistance}, Best Path: ${this.best.gnomeName}, Gen Average: ${this.gens[this.currGen].average}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue))
              : SizedBox(width: 0),
            Container(
              color: Colors.black,
              width: 600,
              height: 500,
              child: CustomPaint(
                painter: Drawer(cities, connections, this.best, this.gens.isEmpty ? null :  this.gens[this.bestGeneration].best)
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text("Costs by route:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 14,),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(blurRadius: 6, color: Colors.grey[100], offset: Offset(0.3, 0.3))
                ]
              ),
              height: MediaQuery.of(context).size.height * 0.46,
              width: MediaQuery.of(context).size.width * 0.3,
              child: Scrollbar(
                controller: this.routeScroll,
                isAlwaysShown: true,
                child: ListView.separated(
                  controller: this.routeScroll,
                  itemCount: this.connections.length,
                  itemBuilder: (ctx,i) => Text("From: ${this.connections[i].from.name} To: ${this.connections[i].dest.name} = ${this.connections[i].cost}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  separatorBuilder: (ctx,i) => SizedBox(height: 16,),
                ),
              ),
            ),
            
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text("Generations:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 14,),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(blurRadius: 6, color: Colors.grey[100], offset: Offset(0.3, 0.3))
                ]
              ),
              height: MediaQuery.of(context).size.height * 0.46,
              width: MediaQuery.of(context).size.width * 0.3,
              child: Scrollbar(
                controller: this.genScroll,
                child: ListView.separated(
                  controller: this.genScroll,
                  itemCount: this.gens.length,
                  itemBuilder: (ctx,i) => generationDisplay(gens[i]),
                  separatorBuilder: (ctx,i) => Divider(height: 16,)
                ),
              ),
            ),
            
          ],
        )
      ],
    );
  }

  Widget _buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: (){
            if(this.nCities > 0) {
              this.generateCities();
            }else{
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text("Alert!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  content: Text("Cities cannot be zero!", style: TextStyle(fontSize: 22)),
                  actions: [
                    TextButton(
                      child: Text("Okay", style: TextStyle(fontSize: 18 ,fontWeight: FontWeight.bold, color: Colors.blue)),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                )
              );
            }
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blue[900]),
            overlayColor: MaterialStateProperty.all(Colors.transparent)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Generate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        SizedBox(width: 16,),
        ElevatedButton(
          onPressed: () async {
            if(this.nCities > 0) {
              this.genAlg();
              // this.generateCities();
            }
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red[500]),
            overlayColor: MaterialStateProperty.all(Colors.transparent)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Calculate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text('Salesperson Traveller problem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          isAlwaysShown: true,
          controller: this.mainScroll,
          child: SingleChildScrollView(
            controller: this.mainScroll,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Center(child: Text("Solving Salesperson Traveller problem with genetic algorithms", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
                    SizedBox(height: 16,),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: ListTile(
                        leading: Text("Number of cities:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        title: Container(
                          child: DropdownButton(
                            value: nCities,
                            items: getOptions(20),
                            onChanged: (val){
                              this.setState(() {
                                this.nCities = val;                            
                              });
                            },
                          )
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: ListTile(
                            leading: Text("Max of generations:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            title: Container(
                              child: DropdownButton(
                                value: generations,
                                items: getOptions(100),
                                onChanged: (val){
                                  this.setState(() {
                                    this.generations = val;                            
                                  });
                                },
                              )
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: ListTile(
                            leading: Text("Population Size:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            title: Container(
                              child: DropdownButton(
                                value: popSize,
                                items: getOptions(100),
                                onChanged: (val){
                                  this.setState(() {
                                    this.popSize = val;                            
                                  });
                                },
                              )
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    this._buttonRow()
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                this._canvasInfo()
              ],
            ),
          ),
        ),
      )
    );
  }
}

class Drawer extends CustomPainter {
  List<City> cities = [];
  List<Connection> connections = [];
  GNOME best;
  GNOME currBest;

  Drawer(List cities, List connections, GNOME currBest, GNOME best) {
    this.cities = cities;
    this.connections = connections;
    this.currBest = currBest;
    this.best = best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint1 = Paint();
    paint1.strokeCap = StrokeCap.round;
    paint1.color = Colors.white;
    paint1.strokeWidth = 2;

    for(Connection connection in this.connections){
      canvas.drawPoints(PointMode.lines, [connection.from.point, connection.dest.point], paint1);
    }


    if(this.best != null) {
      paint1.strokeWidth = 10;
      paint1.color = Colors.red;
      for (int i=0; i<this.best.cities.length - 1; i++) {
        canvas.drawPoints(PointMode.lines, [this.best.cities[i].point, this.best.cities[i+1].point], paint1);
      }
    }



    if(this.currBest != null) {
      paint1.strokeWidth = 4;
      paint1.color = Colors.blue;
      for (int i=0; i<this.currBest.cities.length - 1; i++) {
        canvas.drawPoints(PointMode.lines, [this.currBest.cities[i].point, this.currBest.cities[i+1].point], paint1);
      }
    }

    paint1.strokeWidth = 30;

    final textStyle = TextStyle(
      fontSize: 24, 
      fontWeight: FontWeight.bold,

      color: Colors.red[300]
    );
    var textPainter = TextPainter();
    List<Offset> offsets = [];
    for(City city in this.cities) {
      offsets.add(city.point);
      textPainter = TextPainter(
        text: TextSpan(text: "${city.name}", style: textStyle),
        textDirection: TextDirection.ltr
      );

      textPainter.layout(minWidth: 0, maxWidth: size.width);

      paint1.color = city.color;
      canvas.drawPoints(PointMode.points, [city.point], paint1);


      var textOffset = Offset(city.point.dx + 3.0, city.point.dy + 3.0);
      textPainter.paint(canvas, textOffset);
    }



  }

  @override
  bool shouldRepaint(covariant Drawer oldDelegate) {
    return oldDelegate.cities != this.cities && oldDelegate.connections != this.connections && oldDelegate.best != this.best && this.currBest != oldDelegate.currBest;
  }

}