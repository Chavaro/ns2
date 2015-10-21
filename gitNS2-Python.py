#!/usr/bin/python

import os
os.system("clear");
print("=== srWPAN-Python ===");	#Modo de impresion 1

print "\n=== Ejecutando archivo NS ===";
os.system("ns srWPAN.tcl");
print " ";

#print("\n\tPress ENTER to continue...");
#raw_input();

print "=== Ejecutando script ===";
# Abrir archivo
archivo = open("srWPAN.tr", "r");
print "Nombre del archivo: \t", archivo.name;	#Modo de impresion 2
print "Modo de apertura: \t", archivo.mode;

# Conteo de trazas
enunciados = archivo.readlines();
print("Trazas encontradas: \t%s" %(len(enunciados)));	#Modo de impresion 3
#print "Trazas encontradas: ", len(enunciados);	#Modo de impresion 4

# Definiciones
sinkNode = '_0_';
mobileNode = '_10_';
findLayer = 'MAC';
findTraffic = 'cbr';
splitText = ' ';
removeText = '\n';

traza = [];
for linea in enunciados :
	campo = linea.split(splitText);
	#Excluimos eventos ajenos a 'received', 'sent' y 'dropped'
	if campo[0] not in ['r','s','D']:
		continue
	#Excluimos capas ajenas a 'MAC'
	if not (campo[3] == 'MAC'):
		continue
	#Excluimos trafico ajeno al tipo 'cbr'
	if not (campo[7] == 'cbr'):
		continue
	#Armamos el array
	traza.append({'evento': campo[0], 'time': campo[1], 'nodeID': campo[2], 'pakUID': int(campo[6]), 'pakSize': campo[8]})

print("Trazas filtradas: \t%s" % (len(traza)));

print "\n=== Trace Analysis ===";
# Encuentra cantidad de nodos en trazas filtradas
nodes = set(t['nodeID'] for t in traza);
print "Nodos: \t\t%s" % (len(nodes));

# Encuentra cantidad de eventos s (no Sink)
#sent = len(set(t['pid'] for t in traza if t['nodeID'] != sinkNode and t['evento'] == 's'));
#sent = set(t['time'] for t in traza if t['nodeID'] == mobileNode and t['evento'] == 's');
sent = set(t['time'] for t in traza if t['nodeID'] != sinkNode and t['evento'] == 's'); #Guarda los tiempos de cada evento

# Encuentra cantidad de eventos r en Sink
recv = set(t['time'] for t in traza if t['nodeID'] == sinkNode and t['evento'] == 'r');

# Encuentra cantidad de eventos D en Sink
dropped = set(t['time'] for t in traza if t['nodeID'] == mobileNode and t['evento'] == 'D');

#Calculo e impresion de Probabilidad de Entrega
print("Env al Sink: \t%d \nRec en Sink: \t%d" % (len(sent), len(recv)));
print("DropPaq n10: \t%d" % (len(dropped)));


print("\n=== Grep ===");
os.system("grep -E -w -i '^r|^s|^d' srWPAN.tr | grep -E -w -i 'MAC' | grep -E -w -i 'cbr' > filteredTraces.txt");
print("Trazas filtradas guardadas en filteredTraces.txt:");
os.system("grep -E -w -i '^r|^s|^d' srWPAN.tr | grep -E -w -i 'MAC' | grep -E -w -i -c 'cbr'");

print("Enviados: ");
os.system("grep -E -w -i '^s' filteredTraces.txt | grep -E -w -i -v '_0_' | grep -E -w -i 'MAC' | grep -E -w -i -c 'cbr'")

print("Recibidos: ");
os.system("grep -E -w -i '^r' filteredTraces.txt | grep -E -w -i '_0_' | grep -E -w -i 'MAC' | grep -E -w -i -c 'cbr'")


print "\n=== Measurements of Network === ";
#Probabilidad de Entrega
print("Delivery P.: \t%.2f %%" % (float(len(recv))/len(sent)*100));
#Paq. Recibidos por Seg = recv/100 secs ***CBR starts @ 20s. Each CBR package = 80B = 640b
print("Throughput: \t%.2f bps" % (float(len(recv)*80*8/100)));
#End-to-End = Paq. Enviados del Nodo10 y Recibidos por el Sink
print("End-2-End: \t%.2f ms" % (float(len(recv)/100)));

#os.system("echo | awk -f hello.awk");
os.system("echo | awk -f fil2.awk srWPAN.tr > out2.xgr");
os.system("echo | awk -f Throughput.awk srWPAN.tr");
os.system("echo | awk -f pdr.awk srWPAN.tr");

print ("\n=== fil2.awk ===");
print ("out2.xgr file created.");
print ("\tPlotting: out2.xgr");
os.system("echo | awk -f traceAnalysis.awk srWPAN.tr");

# === GNUPLOT.PY ===
import numpy as np
import Gnuplot

#Instantiate Gnuplot object
g = Gnuplot.Gnuplot(persist=1)
#Formatting options
g('set grid')

g('set xlabel "secs"')
g('set xr [0.0:121.0]')
g('set style line 2')

g('set ylabel "kb"')
g('set ytics 200')
g('set yr [0.0:1550.0]')

g('set key left ')
#Plot data
g('plot "out2.xgr" using 1:2 title "Throughput/s" with impulses lt rgb "blue"')
#lines, points, linespoints, impulses, dots, steps, fsteps, histeps, errorbars, xerrorbars, yerrorbars, xyerrorbars, boxes, boxerrorbars, boxxyerrorbars, financebars, candlesticks or vector

# Cerrar archivo
archivo.close();
print "\nArchivo cerrado?: ", archivo.closed;
