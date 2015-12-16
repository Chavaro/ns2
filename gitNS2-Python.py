#!/usr/bin/python

import os
os.system("clear");
print("=== gitNS2-Python ===");	#Modo de impresion 1

print "\n=== Ejecutando archivo NS ===";
os.system("ns gitNS2.tcl");
print " ";

#print("\n\tPress ENTER to continue...");
#raw_input();

print "=== Ejecutando script ===";
# Abrir archivo .tr
archivo = open("gitNS2.tr", "r");
print "Nombre del archivo: \t", archivo.name;	#Modo de impresion 2
print "Modo de apertura: \t", archivo.mode;		#read mode

# Conteo de trazas/eventos
enunciados = archivo.readlines();
print("Trazas totales: \t%s" %(len(enunciados)));	#Modo de impresion 3
#print "Trazas totales: ", len(enunciados);	#Modo de impresion 4

# Definiciones para el filtrado
sinkNode = '_10_';
mobileNode = '_9_';
findLayer = 'MAC';
findTraffic = 'cbr';
splitText = ' ';
removeText = '\n';

traza = [];
for linea in enunciados :
	campo = linea.split(splitText);
	#Leemos solo eventos 'received', 'sent' y 'dropped'
	if campo[0] not in ['r','s','D']:
		continue
	#Leemos solo capa 'MAC'
	if not (campo[3] == findLayer):
		continue
	#Leemos solo trafico tipo 'cbr'
	if not (campo[7] == findTraffic):
		continue
	#Armamos el array o nuevo conjunto de trazas
	traza.append({'evento': campo[0], 'time': campo[1], 'nodeID': campo[2], 'pakUID': int(campo[6]), 'pakSize': campo[8]})

print("Trazas filtradas: \t%s" % (len(traza)));

print "\n=== Trace Analysis ===";
# Encuentra cantidad de nodos en trazas filtradas
nodes = set(t['nodeID'] for t in traza);
print "Nodos: \t\t%s" % (len(nodes));

# Encuentra cantidad de eventos s (no Sink)
sent = set(t['time'] for t in traza if t['nodeID'] != sinkNode and t['evento'] == 's'); #Guarda los tiempos de cada evento

# Encuentra cantidad de eventos r en Sink
recv = set(t['time'] for t in traza if t['nodeID'] == sinkNode and t['evento'] == 'r');

# Encuentra cantidad de eventos D en Sink
dropped = set(t['time'] for t in traza if t['nodeID'] == mobileNode and t['evento'] == 'D');

#Calculo e impresion de Probabilidad de Entrega
print("Env al Sink: \t%d \nRec en Sink: \t%d" % (len(sent), len(recv)));
print("DropPaq n10: \t%d" % (len(dropped)));


print "\n=== Measurements of Network === ";
#Probabilidad de Entrega
print("Delivery P.: \t%.2f %%" % (float(len(recv))/len(sent)*100));
#Paq. Recibidos por Seg = recv/100 secs ***CBR starts @ 20s. Each CBR package = 80B = 640b
print("Throughput: \t%.2f bps" % (float(len(recv)*80*8/100)));
#End-to-End = Paq. Enviados del Nodo10 y Recibidos por el Sink
print("End-2-End: \t%.2f ms" % (float(len(recv)/100)));


os.system("echo | awk -f traceAnalysis.awk gitNS2.tr");


# Cerrar archivo
archivo.close();
print "\nArchivo cerrado?: ", archivo.closed;
