# Programa para mostrar varias formas de leer y
# escribir datos en un archivo de texto.

mem = ""


for i in range(0, 24):
    for j in range(0, 24):
        mem += f"{((2-(i%2))+(j%2)):02X}\n"

with open("init.mem","w") as f:
    f.write(mem)