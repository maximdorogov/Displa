%Autor: Maxim Dorogov
%Este programa lee datos provenientes de un puerto serie y los imprime por
%pantalla.
 
close all;clc;clear all;

SERIAL_PORT = 'COM4';
BAUD_RATE = 38400;
DATA_BITS = 8; %bits a recibir
SMPLNG_TIME = 50e-3; %debe ser menor o igual que el periodo de las muestras
%de entrada
data_h = 0;
data_l = 0;
data_y = zeros(1000,1);
data_x = zeros(1000,1);
%creo el objeto "serie"
board = serial(SERIAL_PORT);
board.InputBufferSize = 1;
board.BaudRate = BAUD_RATE;
fopen(board); 
board.ReadAsyncMode = 'continuous';

div_x = 1;
div_y = 2;
%configuro la pantalla de impresion 

% figure
% hold on
% ylim([0 850]);
% xlim([1 1000]);

%leo los datos entrantes del puerto serie
%while i>0
readasync(board);
for i =1:3000   %comentar esta linea si uso el while
    
    %pause(1e-3)
    data_x(i) = fread(board);
     if (data_x(i)> 160)
         data_x(i) = 0;
         data_y(i) = 0;
         continue
     end
     data_y(i) = fread(board); 
     if (data_y(i)> 240)
         data_x(i) = 0;
         data_y(i) = 0;
     end
   
    %pause(5e-3)
    %if data(i) > 160
        %data(i) = 0;
    %end
    %stem(i,data,'*r')
    %pause(0.1e-3)
    
end
figure
hold on
ylim([1 120]);
xlim([1 160]);

plot(data_x,data_y,'.b')
 disp('Programa terminado');
 fclose(board);
 delete(board);
 clear board;
return
    data_h = bitshift(data_h, 8); %shifteo a la izquierda
    data = data_h + data_l;
    plot(i,data,'r')
    pause(1e-3)
    %i=i+1;  %descomentar esta linea si uso el while
%end   

    disp('Programa terminado');
    fclose(board);
    delete(board);
    clear board;

