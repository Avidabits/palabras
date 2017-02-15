/* 
  El instante hablado,  
  scketch processing pensado para visualizar datos de reconocimiento de voz
  procedentes de un script en html que sa la speech recognition api de google
*/  

// clase y variable de configuracion
class Configura{
  Boolean letra_menguante=true; //poner a false si va demasiado lento.
  int retardo=50;
  color color_fondo=0; //negro
  color color_letra=color(255, 255, 255);// muy claro
  int num_textos_minimo=5;
  float factor_anchura=1.0; // vamos a hacer que la amchura de la pantalla pueda ser distinta para que 
  // los textos puedan ponerse en una franja vertical y ocupar menos espacio de galeria.
  // cuando calculemos el warping del texto o el ancho de los objetos a pintar, multiplicaremos with por el factor de anchira
  //int width() {return (int)(factor_anchura*(float)width); }
  int width() {return width;}// PENDIENTE RECUPERAR METODO ANTERIOR
} 

Configura configuracion=new Configura();


// Variables globales que actualizaré desde el script html
// con ellas y con la funcion copia_variables_script hare que puedan funcionar 
// este pde de forma independiente.
String texto_final = "¿que si quieres hablar conmigo?"; 
String texto_intermedio ="¿quieres hablar conmigo? ¿ehRR?"; 
Boolean nuevo_final=false; // para saber cuando hay un reconocimiento final nuevo
// una poesia secreta 
ArrayList<String> poesia;

// Global variables
int X, Y; //posicion circulo
float size_letra=32;


class trackTexto {
  String texto;
  int x_inicial;
  int y_inicial;
  int x;
  int y;
  int x_final;
  int y_final;
  int retardo_caida;
  float m_size_letra;
  float m_size_letra_inicial;
  PFont m_fuente;
  trackTexto(String nuevo_texto, int XInicial, int YInicial, int XFinal, int YFinal, int retardo, PFont p_fuente, float p_size_letra)
  {  
    
    x=x_inicial=XInicial; y=y_inicial=YInicial; x_final=XFinal; y_final=YFinal; retardo_caida=retardo;
    texto=nuevo_texto;
    m_fuente=p_fuente;
    m_size_letra=m_size_letra_inicial=p_size_letra;
    
  };
  
  void reinicia(int XInicial, int YInicial, int XFinal, int YFinal, int retardo, PFont p_fuente, float p_size_letra)
  {
    x=x_inicial=XInicial; y=y_inicial=YInicial; x_final=XFinal; y_final=YFinal; retardo_caida=retardo;
    m_fuente=p_fuente;
    m_size_letra=m_size_letra_inicial=p_size_letra;    
  };
  
  void avanza()
  {
       
    x+=(x_final-x)/retardo_caida;
    y+=(y_final-y)/retardo_caida+1;
    
     if (configuracion.letra_menguante) m_size_letra=map(y, y_inicial, y_final, m_size_letra_inicial, m_size_letra_inicial/2);
    // para sistemas operativos lento no cambio el tamaño de la letra

  }; 
  
  
  void pintate()
  {

 
    if (configuracion.letra_menguante) textFont(m_fuente, m_size_letra);
    int distanciaBorde=x;
    if (x>configuracion.width()/2) distanciaBorde=configuracion.width()-x;
    text(texto,x-distanciaBorde,y-m_size_letra, distanciaBorde*2, m_size_letra*4); //escibir el texto en pantalla    
    noFill();
    rect(x-distanciaBorde,y-m_size_letra, distanciaBorde*2, m_size_letra*4);
  };
  
  Boolean ha_llegado() {
     if ((x >= x_final) && (y >= y_final+m_size_letra)) return true; // asume que seguimos trayectoria hacia abajo de caida
    
     return false;

}; 
  
}; //class tractTexto

ArrayList<trackTexto> textos_finales;

PFont fuente;


// Setup the Processing Canvas
void setup(){
  

  textos_finales = new ArrayList<trackTexto>();  // Create an empty ArrayList
  on_nueva_size(1280, 720);
  
  fill(configuracion.color_letra);     // relleno dibujo blanco, letra
  stroke(configuracion.color_letra);
  frameRate( 16 ); // numero de veces que llamamos a draw por segundo. 
  X = configuracion.width()/2; //empieza en el centro. 
  Y = height/2;//empieza en el centro
  
  
  // printArray(PFont.list());// mirando esas fuentes
  fuente= createFont("Verdana", size_letra);
  textFont(fuente);  
  textAlign(CENTER);//importante para escribir textos en modo (x,y, ancho, alto);
  textMode(SCREEN);
 
  creaPoesia();
}


// Main draw loop
void draw()
{

  background( configuracion.color_fondo );
  fill(configuracion.color_letra);

  size_letra=size_letra+sin(frameCount/6);
  textFont(fuente, size_letra);
  
  // pintamos el texto en modo corner, ancho alto. 
  int distanciaBorde=X;
  if (X>configuracion.width()/2) distanciaBorde=configuracion.width()-X;
  text(texto_intermedio,X-distanciaBorde,Y-size_letra, distanciaBorde*2, size_letra*4); //escibir el texto en pantalla
  noFill();
  rect(X-distanciaBorde,Y-size_letra, distanciaBorde*2, size_letra*4);

  //text(texto_intermedio,X,Y+size_letra/2); //PENDIENTE, QUITAR el texto en pantalla
  textFont(fuente); //restaura el tamaño de letra original
  
  if (nuevo_final) 
  {
    // meter el texto final en la lista de textos finales
    textos_finales.add(new trackTexto(texto_final, X, Y, X, height, configuracion.retardo, fuente, size_letra));  // añade el nuevo texto
    // hacer que todos los textos avancen

    //nueva posicion para los nuevos textos intermedios que lleguen
    X=(int)random(size_letra*5, configuracion.width()-size_letra*5);
    Y=(int)random(size_letra*2, height/2); //para que por lo menos tengan que caer durante la mitad de la pantalla
    nuevo_final=false;  
  }
  
  // en cualquier caso hay que hacer que los textos finales anteriores avances
  for (int i = textos_finales.size()-1; i >= 0; i--) {
       trackTexto txt=textos_finales.get(i);
       txt.avanza();
       txt.pintate();
       if (txt.ha_llegado()&&textos_finales.size()>configuracion.num_textos_minimo) {
          // Items can be deleted with remove().
          textos_finales.remove(i);
          txt=null; // para asegurar el uso de garbage collector 
       }
       else if (txt.ha_llegado()&&textos_finales.size()<=configuracion.num_textos_minimo) {
          X=(int)random(size_letra*5, configuracion.width()-size_letra*5);
          Y=(int)random(size_letra*2, height/2); //para que por lo menos tengan que caer durante la mitad de la pantalla
         txt.reinicia(X, Y, X, height, configuracion.retardo, fuente, size_letra); 
         // no lo borramos, lo metemos al principio
       } 
    }
 // drawAxis();
}

// nuevas funciones 
void copia_variables_script(String texto_reconocido, Boolean is_final)
{
        nuevo_final=is_final;
        if (nuevo_final) {
          texto_final=texto_reconocido;
          texto_intermedio="";
        }
        else texto_intermedio=texto_reconocido;
}

// se usa para inicializar el tamaño y tambien es llamada desde el htlml cuando cambia el tamaño 
// de la venta
void on_nueva_size(int p_ancho, int p_alto)
{
  size( p_ancho, p_alto ); //tamaño del canvas
  size_letra=p_ancho/40;
   
}

// para depurar y simular un nuevo texto final usaré el keyPressed y la hora corriente
// hace la funcion de copia_variables_script cuando estamos fuera del entorno web
int gIndex=0;

void keyPressed()
//void mouseClicked() 
{
  nuevo_final=true;
 
  if (gIndex >=poesia.size()) gIndex=0;
  texto_final=texto_intermedio;
  texto_intermedio=poesia.get(gIndex);
  gIndex++;
    
}

/**
 This is a little helper function that draws an XY coordinate axis .
  
 If you want to see where the coordinate axis is and which way it is facing,
 put drawAxis() in the code above.
 **/
void drawAxis() {
  stroke(255, 0, 0);
  line(0, 0, 20, 0); //eje x rojo
  stroke(0, 255, 0); // eje y verde
  line(0, 0, 0, 20);
}

void creaPoesia()
{
  poesia = new ArrayList<String>();

  poesia.add("¿qué significa? LARGO LARGO LARGO LARGISIMO"); //pendiente , quitar texto testing
  poesia.add("cómo?");
  poesia.add("qué bonito");
  poesia.add("no entiendo nada");
  poesia.add("pues a mi no me gusta");
  poesia.add("esta noche no he podido dormir");
  poesia.add("te espero en casa");
  poesia.add("¿cuanto cuesta?");
  poesia.add("por qué");
  poesia.add("siempre te quedas ahí pasada");
  poesia.add("pues sigo sin entender nada");
  poesia.add("cuanto más los miro");
  poesia.add("mirar allí");
  poesia.add("no la encuentro");
  poesia.add("dónde está la tuyo");
  poesia.add("siempre pienso en eso");
  poesia.add("a mi no me mires");
  poesia.add("ya entiendo lo que quiere decir");
  poesia.add("pues a mi plin");
  
}

void pintaFluorescente(int altura)
{
   // pintar luces vibrantes y algo pulsantes en la parte baja del viewport
   float r=red(configuracion.color_letra);
   float g=green(configuracion.color_letra);
   float b=blue(configuracion.color_letra);
    
   for (int i=0; i<altura; i++)  
   {
     float decremento=sin(2*PI*i/(4*altura));
     stroke(color(r-r*decremento, g-g*decremento, b-b*decremento));
     line(0, height-i, configuracion.width(), height-i);
   }
}

