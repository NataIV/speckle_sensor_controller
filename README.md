# Componentes

Componentes a usar a modo de "Bibliotecas".

# Testbench

Testbench que simula un proceso completo de ESCANEO -> PROCESAMIENTO -> CONFIGURACION. Se debe adjuntar el archivo "init.mem" para inicializar la memoria.

# Configurar el proyecto de vivado

Para configurar el proyecto se debe adjuntar el archivo "top.v", el cual debería importar directamente los archivos correspondientes de la carpeta "componentes". Además se deben adjuntar los archivos de la carpetas de testbench para simular y la carpeta constrains para la sintesis.
