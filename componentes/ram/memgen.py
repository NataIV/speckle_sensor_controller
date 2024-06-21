# Programa para mostrar varias formas de leer y
# escribir datos en un archivo de texto.

with open("init.mem","w") as f:
    f.write("".join(f"{i:02X}\n" for i in range(0, 576)))
