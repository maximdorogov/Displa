%Autor: Maxim Dorogov
%Este programa lee datos provenientes de un puerto serie y los imprime por
%pantalla.
 
close all;clc;

SERIAL_PORT = 'COM6';
BAUD_RATE = 38400;
DATA_BITS = 8; %bits a recibir
SMPLNG_TIME = 50e-3; %debe ser menor o igual que el periodo de las muestras
%de entrada
data = 0;
%creo el objeto "serie"
board = serial(SERIAL_PORT);
board.InputBufferSize = 1;
board.BaudRate = BAUD_RATE;
fopen(board); 
board.ReadAsyncMode = 'manual';
%configuro la pantalla de impresion 

figure
hold on
ylim([0 250]);
xlim([0 1000]);
grid minor

%leo los datos entrantes del puerto serie

for i =0:50    
    readasync(board,1);
    data = fread(board);
    plot(i,data,'.r')
    pause(5e-3)
end   


    disp('Programa terminado');
    fclose(board);
    delete(board);
    clear board;
return
