# Sources

Códigos fuente del proyecto.

# Testbench

Testbench que simula un proceso completo de ESCANEO -> PROCESAMIENTO -> CONFIGURACION. Se debe adjuntar el archivo "init.mem" para inicializar la memoria.

# Configurar el proyecto de vivado

Para configurar el proyecto y solo simular se debe incluir el archivo "speckle_sensor_controller.v", el cual debería importar directamente el resto de archivos. Además se deben adjuntar los archivos de la carpetas de testbench para simular.

Para grabar en la FPGA, se deberá incluir el archivo "top.v", se deberán crear los block designs necesarios (xadc, vio e ila) e incluir el archivo de constrains al proyecto.
