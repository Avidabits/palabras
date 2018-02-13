/* 
  El instante hablado,  
  scketch processing pensado para visualizar datos de reconocimiento de voz
  procedentes de un script en html que sa la speech recognition api de google
*/ 


// clase y variable de configuracion
class Configura{
  Boolean depuracion=false;
  Boolean letra_menguante=true; //poner a false si va demasiado lento.
  Boolean flourescente=true;
  Boolean subiendo=false; // las letras pueden subir o bajar
  color color_fondo=0; //negro
  color color_letra=color(255, 234, 255);
  int num_textos_minimo=20;
  float factor_anchura=1.0; // vamos a hacer que la amchura de la pantalla pueda ser distinta para que 
  // los textos puedan ponerse en una franja vertical y ocupar menos espacio de galeria.
  // cuando calculemos el warping del texto o el ancho de los objetos a pintar, multiplicaremos with por el factor de anchira
  float anchura() {return (float)width*factor_anchura;}
} 

Configura configuracion=new Configura();


// Variables globales que actualizaré desde el script html
// con ellas y con la funcion copia_variables_script hare que puedan funcionar 
// este pde de forma independiente.
String texto_final = "¿que si quieres hablar conmigo?"; 
String texto_intermedio ="¿quieres hablar conmigo?"; 
Boolean nuevo_final=false; // para saber cuando hay un reconocimiento final nuevo
// una poesia secreta 
ArrayList<String> poesia;

// Global variables
int X=100; 
int Y=360; //posicion circulo
float size_letra=20;


class trackTexto {
  String texto;
  int x_inicial;
  int y_inicial;
  int x;
  int y;
  int x_final;
  int y_final;
  float m_size_letra;
  float m_size_letra_inicial;
  PFont m_fuente;
  trackTexto(String nuevo_texto, int XInicial, int YInicial, int XFinal, int YFinal, PFont p_fuente, float p_size_letra)
  {  
    
    x=x_inicial=XInicial; y=y_inicial=YInicial; x_final=XFinal; y_final=YFinal; 
    texto=nuevo_texto;
    m_fuente=p_fuente;
    m_size_letra=m_size_letra_inicial=p_size_letra;
    
  };
  
  void reinicia(int XInicial, int YInicial, int XFinal, int YFinal, PFont p_fuente, float p_size_letra)
  {
    x=x_inicial=XInicial; y=y_inicial=YInicial; x_final=XFinal; y_final=YFinal; 
    m_fuente=p_fuente;
    m_size_letra=m_size_letra_inicial=p_size_letra;   
   texto_debug("reiniciando..."); 
  };
  
  void avanza()
  {
    int pasosX=(x_final-x_inicial)/100;
    int pasosY=(y_final-y_inicial)/100;   
    x+=pasosX;
    y+=pasosY;

    if (configuracion.letra_menguante) m_size_letra=map(y, y_inicial, y_final, m_size_letra_inicial, m_size_letra_inicial/3);
    // para sistemas operativos lento no cambio el tamaño de la letra

  }; 
  

  // seguimiento hasta aqui todo igual
  void pintate()
  {
 
    if (configuracion.letra_menguante) textFont(m_fuente, m_size_letra);
    pinta_texto(texto, x, y, m_size_letra);

  };
  
  Boolean ha_llegado() 
  {
    
    if (configuracion.subiendo) {
       if (y <= (y_final)) 
       {
         return true; // trayectoria hacia arriba         
       }
     }
     else {
       if (y >= (y_final)) {
        return true; // trayectoria hacia abajo de caida
       }
     }
     
     return false;
  }; 
  
}; //class tracktTexto

ArrayList<trackTexto> textos_finales;

PFont fuente;


// Setup the Processing Canvas
void setup(){
  
  textos_finales = new ArrayList<trackTexto>();  // Create an empty ArrayList
  
  size(1280, 720);
  //frame.setResizable(true);// rmbr 31.12.2017 elimino esto porque no es reconocido en processingJS
  on_nueva_size(1280, 720);
 
  
  fill(configuracion.color_letra);     // relleno dibujo blanco, letra
  stroke(configuracion.color_letra);
  frameRate( 16 ); // numero de veces que llamamos a draw por segundo.
  texto_debug("FRAMERATE: 16");

  
  
  // printArray(PFont.list());// mirando esas fuentes
  fuente= createFont("Verdana", size_letra);
  texto_debug("size_letra: "+size_letra);
  textFont(fuente);  
  textAlign(CENTER);//importante para escribir textos en modo (x,y, ancho, alto);
 
  creaPoesia();
}




// Main draw loop
void draw()
{
  background( configuracion.color_fondo );
  
  
  if (configuracion.flourescente)pintaFluorescente(height/10);
  
  fill(configuracion.color_letra);
  stroke(configuracion.color_letra);
  
  
   // este seno se usa para la letra pulsante del texto intermedio
  size_letra=size_letra+0.5*sin(frameCount/6);
  textFont(fuente, size_letra);
  // pintamos el texto en modo corner, ancho alto. 
  pinta_texto(texto_intermedio, X, Y, size_letra);
  textFont(fuente); //restaura el tamaño de letra original
  
  
  if (nuevo_final) 
  {
    // meter el texto final en la lista de textos finales (x inicial, x final, x fina, y final)
    if (configuracion.subiendo) textos_finales.add(new trackTexto(texto_final, X, Y, X, 0, fuente, size_letra));  // añade el nuevo texto subiendo
    else textos_finales.add(new trackTexto(texto_final, X, Y, X, height, fuente, size_letra));  // añade el nuevo texto bajando
    
    // hacer que todos los textos avancen

    //nueva posicion para los nuevos textos intermedios que lleguen
    X=(int)random(size_letra*5, (float)configuracion.anchura()-size_letra*5.0);
    if (configuracion.subiendo) Y=(int)random(height-size_letra, height/2); // que suba desde abajo 
    else Y=(int)random(size_letra*2, height/2.0); //para que por lo menos tengan que caer durante la mitad de la pantalla
   
    nuevo_final=false;  
  }
  
  // en cualquier caso hay que hacer que los textos finales anteriores avances
  for (int i = textos_finales.size()-1; i >= 0; i--) {
       trackTexto txt=textos_finales.get(i);
       txt.avanza();
       txt.pintate();
       if (txt.ha_llegado()&&(textos_finales.size()>configuracion.num_textos_minimo)) {
          // Items can be deleted with remove().
          texto_debug("borrando");
          textos_finales.remove(i);
          txt=null; // para asegurar el uso de garbage collector 
       }
       else if (txt.ha_llegado()&&(textos_finales.size()<=configuracion.num_textos_minimo)) {
          X=(int)random(size_letra*5, configuracion.anchura()-size_letra*5);
          if (configuracion.subiendo){
            Y=(int)random(height, height/2); // que suba desde abajo
            txt.reinicia(X, Y, X, 0, fuente, size_letra); //subiendo
          }
          else {          
            Y=(int)random(size_letra*2, height/2); //para que por lo menos tengan que caer durante la mitad de la pantalla
            txt.reinicia(X, Y, X, height, fuente, size_letra); //bajando
          }
                
         // no lo borramos, lo metemos al principio
       } 
    }
  if (configuracion.depuracion) drawAxis();
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
  // rmbr 30.12.2017
  // size( p_ancho, p_alto ); //// rmbr 30.12.2017 no se puede usar excepto como primera línes
  // setSize(p_ancho, p_alto );// rmbr 31.12.2017 No soportado en processing JS
  // para solventar esto, una vez puesta la aplicacion en ventana completa habrá que recargar la página con ctrl + F5
  
  size_letra=configuracion.anchura()/40;
  texto_debug("on_nueva_size: p_ancho="+p_ancho);
  texto_debug("on_nueva_size: sizeletra=p_ancho/40="+size_letra);
  
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
  line(0, 0, 32, 0); //eje x rojo
  stroke(0, 255, 0); // eje y verde
  line(0, 0, 0, 32);
}

void creaPoesia()
{
  //creaPoesiaLuciernagas();
  creaPoesiaQuevedo();
}

void creaPoesiaQuevedo()
{
  poesia = new ArrayList<String>();
  poesia.add("Cerrar podrá mis ojos la postrera"); 
  poesia.add("Sombra que me llevare el blanco día,"); 
  poesia.add("Y podrá desatar esta alma mía ");
  poesia.add("Hora, a su afán ansioso lisonjera;"); 

  poesia.add("Mas no de esotra parte en la ribera");
  poesia.add("Dejará la memoria, en donde ardía:");
  poesia.add("Nadar sabe mi llama el agua fría,");
  poesia.add("Y perder el respeto a ley severa.");

  poesia.add("Alma, a quien todo un Dios prisión ha sido,"); 
  poesia.add("Venas, que humor a tanto fuego han dado,");
  poesia.add("Médulas, que han gloriosamente ardido,");

  poesia.add("Su cuerpo dejará, no su cuidado;");
  poesia.add("Serán ceniza, mas tendrá sentido;");
  poesia.add("Polvo serán, mas polvo enamorado");
  
}

void creaPoesiaLuciernagas()
{
  poesia = new ArrayList<String>();

  poesia.add("luciérnagas"); //pendiente , quitar texto testing
  poesia.add("iluminan la noche");
  poesia.add("energía interior");
  poesia.add("mentes creativas");
  poesia.add("apoyo y conexión");
  poesia.add("estamos deseando conocerte");
  poesia.add("¿eres una luciérnaga?");
  poesia.add("¿porqué?");
  poesia.add("luciérnaga");
  poesia.add("conexiones");
  
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
     line(0, height-i, configuracion.anchura(), height-i);
   }

}

void pinta_texto(String texto, int centroX, int centroY, float sizeLetra)
{
   // helper para homogeneizar el modo de pintar texto porque processinfg JS no acepta determimados modos de rectangulo
  int distanciaBorde=centroX;
  if (centroX>configuracion.anchura()/2) distanciaBorde=(int)configuracion.anchura()-centroX;
  text(texto,centroX-distanciaBorde,centroY-sizeLetra, distanciaBorde*2, sizeLetra*5); //escibir el texto en pantalla    
  if (configuracion.depuracion) {
    noFill();
    rect(centroX-distanciaBorde,centroY-sizeLetra, distanciaBorde*2, sizeLetra*5);
  }
  
};

void texto_debug(String debug)
{
  if (configuracion.depuracion) println(debug);
};




