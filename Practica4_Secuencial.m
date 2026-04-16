clc; clear; close all;

%% ========================================================
%  PARÁMETROS GEOMÉTRICOS (igual que Práctica 1)
%  CM nivel 1 (m)
CM1x = -1690/1000;
CM1y = 0;

%  CM nivel 2 (m)
CM2x = -1320/1000;
CM2y = 0;

%  Coordenadas sensores LVDT nivel 1 respecto a CM1
ux12 =  40/1000  - CM1x;   uy12 =  1484/1000 - CM1y;
ux22 =  40/1000  - CM1x;   uy22 = -1484/1000 - CM1y;
ux42 = -2400/1000- CM1x;   uy42 =   550/1000 - CM1y;

%  Coordenadas globales puntos de sensores nivel 2
uy5g2 =  1200/1000;   ux5g2 = -250/1000;
uy6g2 = -1400/1000;   ux6g2 = -250/1000;
ux8g2 = -2400/1000;   uy8g2 =  160/1000;

%  Coordenadas sensores nivel 2 respecto a CM2
uy52 = uy5g2 - CM2y;   ux52 = ux5g2 - CM2x;
uy62 = uy6g2 - CM2y;   ux62 = ux6g2 - CM2x;
uy82 = uy8g2 - CM2y;   ux82 = ux8g2 - CM2x;

%  Masas
m1 = 5.784;   % kN·s²/m
m2 = 6.446;

%% ========================================================
%  ARCHIVOS (orden de intensidad creciente)
archivos = {
    'Test-BS1Calitri35XY_sin_galgas.dat',
    'Test-BS1Calitri50XY_sin_galgas.dat',
    'Test-BS1Calitri100XY_sin_galgas.dat',
    'Test-BS1Calitri200bisXY_sin_galgas.dat',
    'Test-BS1Calitri200XY_sin_galgas.dat',
    'Test-BS1Calitri300XY_sin_galgas.dat'
};
etiquetas = {'Calitri35','Calitri50','Calitri100','Calitri200bis','Calitri200','Calitri300'};
colores   = lines(numel(archivos));

%% ========================================================
%  ACUMULADORES para gráficos secuenciales
t_seq      = [];
uCM1x_seq  = [];   uCM1y_seq  = [];
uCM2x_seq  = [];   uCM2y_seq  = [];
aCM1x_seq  = [];   aCM1y_seq  = [];
aCM2x_seq  = [];   aCM2y_seq  = [];
limites    = [];   % índice final de cada ensayo en el vector acumulado

t_offset = 0;   % desplazamiento temporal acumulado

%% ========================================================
%  BUCLE
for k = 1:numel(archivos)

    DATA = readmatrix(archivos{k});

    %  Columnas según estructura real de los archivos:
    %  1:t  2:axMTS[g]  3:ayMTS[g]  4:dxMTS[mm]  5:dyMTS[mm]
    %  8:LVDT1  9:LVDT2  11:LVDT4
    %  12:LVDT5  13:LVDT6  15:LVDT8
    t         = DATA(:,1);
    acc_mesa  = DATA(:,2) * 9.81;      % X base  [m/s²]
    acc_mesay = DATA(:,3) * 9.81;      % Y base  [m/s²]

    lvdt1 = DATA(:,8)  / 1000;   % LVDT1 nivel 1  [m]
    lvdt2 = DATA(:,9)  / 1000;   % LVDT2 nivel 1  [m]
    lvdt4 = DATA(:,11) / 1000;   % LVDT4 nivel 1  [m]
    lvdt5 = DATA(:,12) / 1000;   % LVDT5 nivel 2  [m]
    lvdt6 = DATA(:,13) / 1000;   % LVDT6 nivel 2  [m]
    lvdt8 = DATA(:,15) / 1000;   % LVDT8 nivel 2  [m]

    %% --- NIVEL 1: desplazamiento CM respecto a base ---
    theta1  = (lvdt2 - lvdt1) ./ (uy12 - uy22);
    uCM1x   = lvdt1 + theta1 .* uy12;
    uCM1y   = lvdt4 - theta1 .* ux42;

    %% --- NIVEL 2: desplazamiento CM respecto a base ---
    %  Posición del nivel 1 en los puntos de los sensores del nivel 2
    u1_5 = uCM1x - theta1 .* (uy5g2 - CM1y);
    u1_6 = uCM1x - theta1 .* (uy6g2 - CM1y);
    v1_8 = uCM1y + theta1 .* (ux8g2 - CM1x);

    %  Desplazamiento global nivel 2
    u5 = u1_5 + lvdt5;
    u6 = u1_6 + lvdt6;
    v8 = v1_8 + lvdt8;

    %  Rotación y CM nivel 2
    theta2 = (u6 - u5) ./ (uy52 - uy62);
    uCM2x  = u5 + theta2 .* uy52;
    uCM2y  = v8 - theta2 .* ux82;

    %% --- ACELERACIONES ABSOLUTAS EN CM ---
    %  Aceleración relativa = d²(desp_relativo)/dt²
    aCM1x_rel = gradient(gradient(uCM1x, t), t);
    aCM1y_rel = gradient(gradient(uCM1y, t), t);
    aCM2x_rel = gradient(gradient(uCM2x, t), t);
    aCM2y_rel = gradient(gradient(uCM2y, t), t);

    %  Absoluta = relativa + base
    aCM1x = aCM1x_rel + acc_mesa;
    aCM1y = aCM1y_rel + acc_mesay;
    aCM2x = aCM2x_rel + acc_mesa;
    aCM2y = aCM2y_rel + acc_mesay;

    %% --- TIEMPO SECUENCIAL ---
    dt_gap   = mean(diff(t));          % paso de tiempo del ensayo
    t_local  = t - t(1) + t_offset;   % tiempo desplazado
    t_offset = t_local(end) + dt_gap; % próximo ensayo arranca justo después

    %% --- ACUMULAR ---
    t_seq     = [t_seq;     t_local];
    uCM1x_seq = [uCM1x_seq; uCM1x];   uCM1y_seq = [uCM1y_seq; uCM1y];
    uCM2x_seq = [uCM2x_seq; uCM2x];   uCM2y_seq = [uCM2y_seq; uCM2y];
    aCM1x_seq = [aCM1x_seq; aCM1x];   aCM1y_seq = [aCM1y_seq; aCM1y];
    aCM2x_seq = [aCM2x_seq; aCM2x];   aCM2y_seq = [aCM2y_seq; aCM2y];
    limites   = [limites, numel(t_seq)];
end

%% ========================================================
%  GRÁFICOS SECUENCIALES
ini = 1;

% ---- Desplazamiento X (CM1 y CM2) ----
figure('Name','Desplazamiento X en CM - Secuencial','NumberTitle','off');
ax1 = subplot(2,1,1); hold on; grid on;
ax2 = subplot(2,1,2); hold on; grid on;

for k = 1:numel(archivos)
    idx = ini:limites(k);
    subplot(ax1); plot(t_seq(idx), uCM2x_seq(idx)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    subplot(ax2); plot(t_seq(idx), uCM1x_seq(idx)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
subplot(ax1); ylabel('u_{CM2,x} (mm)'); title('Desplazamiento X — Nivel 2 (CM)'); legend('Location','best');
subplot(ax2); ylabel('u_{CM1,x} (mm)'); title('Desplazamiento X — Nivel 1 (CM)'); legend('Location','best');
xlabel(ax2,'Tiempo secuencial (s)');

% ---- Desplazamiento Y (CM1 y CM2) ----
ini = 1;
figure('Name','Desplazamiento Y en CM - Secuencial','NumberTitle','off');
ax3 = subplot(2,1,1); hold on; grid on;
ax4 = subplot(2,1,2); hold on; grid on;

for k = 1:numel(archivos)
    idx = ini:limites(k);
    subplot(ax3); plot(t_seq(idx), uCM2y_seq(idx)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    subplot(ax4); plot(t_seq(idx), uCM1y_seq(idx)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
subplot(ax3); ylabel('u_{CM2,y} (mm)'); title('Desplazamiento Y — Nivel 2 (CM)'); legend('Location','best');
subplot(ax4); ylabel('u_{CM1,y} (mm)'); title('Desplazamiento Y — Nivel 1 (CM)'); legend('Location','best');
xlabel(ax4,'Tiempo secuencial (s)');

% ---- Aceleración X (CM1 y CM2) ----
ini = 1;
figure('Name','Aceleración X en CM - Secuencial','NumberTitle','off');
ax5 = subplot(2,1,1); hold on; grid on;
ax6 = subplot(2,1,2); hold on; grid on;

for k = 1:numel(archivos)
    idx = ini:limites(k);
    subplot(ax5); plot(t_seq(idx), aCM2x_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    subplot(ax6); plot(t_seq(idx), aCM1x_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
subplot(ax5); ylabel('a_{CM2,x} (m/s²)'); title('Aceleración absoluta X — Nivel 2 (CM)'); legend('Location','best');
subplot(ax6); ylabel('a_{CM1,x} (m/s²)'); title('Aceleración absoluta X — Nivel 1 (CM)'); legend('Location','best');
xlabel(ax6,'Tiempo secuencial (s)');

% ---- Aceleración Y (CM1 y CM2) ----
ini = 1;
figure('Name','Aceleración Y en CM - Secuencial','NumberTitle','off');
ax7 = subplot(2,1,1); hold on; grid on;
ax8 = subplot(2,1,2); hold on; grid on;

for k = 1:numel(archivos)
    idx = ini:limites(k);
    subplot(ax7); plot(t_seq(idx), aCM2y_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    subplot(ax8); plot(t_seq(idx), aCM1y_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
subplot(ax7); ylabel('a_{CM2,y} (m/s²)'); title('Aceleración absoluta Y — Nivel 2 (CM)'); legend('Location','best');
subplot(ax8); ylabel('a_{CM1,y} (m/s²)'); title('Aceleración absoluta Y — Nivel 1 (CM)'); legend('Location','best');
xlabel(ax8,'Tiempo secuencial (s)');

fprintf('Gráficos generados correctamente.\n');
