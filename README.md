# Componentes

Directorio con todos los componentes a usar a modo de "Bibliotecas". Contiene los siguientes componentes:

## Chip driver

Se encarga de generar las señales de clock y dato para ambos registros de desplazamiento y del pulso de escritura de llaves. Permite configurar mediante dos divisores de frecuencia, la frecuencia a la que escribe los registros de desplazamientos y la frecuencia a la que escribe las llaves.

## Counter offset

Contador al que se le puede aplicar un "offset" a la salida sin necesidad de incrementar el registro interno, permitiendo obtener el valor actual del contador, o su valor incrementado en 1, 2 o disminuido en 1.

Se utilizan dos instancias de este contador para generar el direccionamiento de la RAM, mediante la siguiente operacion:
					ram_address = contador_columnas * 24 + contador_filas

El offset de cada contador se utiliza para realizar la comparacion del pixel apuntado por el valor actual y el pixel que estaria conectado por las diferentes llaves (sin incrementar el valor interno del contador):

- *NE* : se incrementa el contador de filas.
- *SE* : se decrementan ambos contadores.
- *WW* : se incrementa el contador de columnas.

## Ram

Ram de un puerto provista entre los ejemplos de vivado.

## Scan Module

Modulo para realizar el escaneo de la matriz de pixeles

## Process Fsm

Fsm para desacumular valores en la memoria RAM. Por como estan conectados los pixeles, solo los que estan conectados a las lineas ARL tienen el valor real de cada pixel, en cambio los demas tienen sumados el valor de otro pixel/es que sean necesarios para acceder a ese valor.

## Config fsm

Maquina de estados que realiza la configuracion del chip.
Se escribe un 1 en el registro de desplazamiento y se desplaza este 1 para realizar la escritura de cada columna.

Contiene otra maquina de estados que a su vez itera entre cada pixel, si este tiene un valor mayor al umbral, se compara el pixel conectado con la llave correspondiente y se escribe un 1 o 0 en el registro de filas del chip si se debe realizar esa conexion.

## top_level_fsm

Maquina de estados que se encarga de realizar el conexionado de recursos compartidos (RAM, escritura del chip, contadores).
