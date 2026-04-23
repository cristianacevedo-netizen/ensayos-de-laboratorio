clc; clear; close all;

%% ========================================================
%  PARAMETROS GEOMETRICOS
%  CM nivel 1 (m)
CM1x = -1690/1000;
CM1y = 0;

%  CM nivel 2 (m)
CM2x = -1320/1000;
CM2y = 0;

%  Coordenadas LVDT nivel 1 respecto a CM1 (para desplazamientos)
uy12 =  1484/1000 - CM1y;   ux12 =  40/1000 - CM1x;
uy22 = -1484/1000 - CM1y;   ux22 =  40/1000 - CM1x;
uy42 =   550/1000 - CM1y;   ux42 = -2400/1000 - CM1x;

%  Coordenadas globales puntos de sensores nivel 2
uy5g2 =  1400/1000;   ux5g2 = -250/1000;
uy6g2 = -1400/1000;   ux6g2 = -250/1000;
uy8g2 =     0/1000;   ux8g2 = -2070/1000;

%  Coordenadas LVDT nivel 2 respecto a CM2
uy52 = uy5g2 - CM2y;   ux52 = ux5g2 - CM2x;
uy62 = uy6g2 - CM2y;   ux62 = ux6g2 - CM2x;
uy82 = uy8g2 - CM2y;   ux82 = ux8g2 - CM2x;

%  Coordenadas Piezos nivel 1 respecto a CM1 (Tabla 2.1, mm->m)
%  Piez1: X=80mm, Y=+1190mm  mide X
%  Piez2: X=80mm, Y=-1190mm  mide X
%  Piez4: X=-3470mm, Y=-1508mm  mide Y
yP1_1 =  1190/1000 - CM1y;   xP1_1 =    80/1000 - CM1x;
yP2_1 = -1190/1000 - CM1y;   xP2_1 =    80/1000 - CM1x;
yP4_1 = -1508/1000 - CM1y;   xP4_1 = -3470/1000 - CM1x;

%  Coordenadas Piezos nivel 2 respecto a CM2 (Tabla 2.1, mm->m)
%  Piez5: X=300mm, Y=+1200mm  mide X
%  Piez6: X=300mm, Y=-1200mm  mide X
%  Piez8: X=-2400mm, Y=-1500mm  mide Y
yP5_2 =  1200/1000 - CM2y;   xP5_2 =   300/1000 - CM2x;
yP6_2 = -1200/1000 - CM2y;   xP6_2 =   300/1000 - CM2x;
yP8_2 = -1500/1000 - CM2y;   xP8_2 = -2400/1000 - CM2x;

%  Masas
m1 = 5.784;   % kN*s^2/m
m2 = 6.446;

%% ========================================================
%  ARCHIVOS (orden calitri35 -> calitri300)
archivos = {
    'Test-BS1Calitri35XY_sin_galgas.dat',
    'Test-BS1Calitri50XY_sin_galgas.dat',
    'Test-BS1Calitri100XY_sin_galgas.dat',
    'Test-BS1Calitri200XY_sin_galgas.dat',
    'Test-BS1Calitri200bisXY_sin_galgas.dat',
    'Test-BS1Calitri300XY_sin_galgas.dat'
};
etiquetas = {'Calitri35','Calitri50','Calitri100','Calitri200','Calitri200bis','Calitri300'};
colores   = lines(numel(archivos));
nSim      = numel(archivos);

%% ========================================================
%  VECTORES ACUMULADORES
t_seq     = [];
uCM2x_seq = [];   uCM2y_seq = [];
aCM1x_seq = [];   aCM1y_seq = [];
aCM2x_seq = [];   aCM2y_seq = [];
Fbx_seq   = [];   Fby_seq   = [];
limites   = [];

t_offset  = 0;

%  Maximos historicos
maxPos_x = 0;   maxNeg_x = 0;
maxPos_y = 0;   maxNeg_y = 0;

%  Vectores de puntos maximos [t, u(mm), a(m/s^2), F_base(kN)]
pts_x_pos = [];   pts_x_neg = [];
pts_y_pos = [];   pts_y_neg = [];

%% ========================================================
%  BUCLE PRINCIPAL
for k = 1:nSim

    DATA = readmatrix(archivos{k});

    % Col 1:  tiempo (s)
    % Col 2:  axMTS [g]   Col 3: ayMTS [g]
    % Col 8:  LVDT1 [mm]  Col 9:  LVDT2 [mm]  Col 11: LVDT4 [mm]
    % Col 12: LVDT5 [mm]  Col 13: LVDT6 [mm]  Col 15: LVDT8 [mm]
    % Piezos [g]: Piez1=col22, Piez2=col23, Piez4=col25
    %             Piez5=col26, Piez6=col27, Piez8=col29

    t         = DATA(:,1);
    acc_mesa  = DATA(:,2) * 9.81;
    acc_mesay = DATA(:,3) * 9.81;

    % LVDT nivel 1
    lvdt1 = DATA(:,8)  / 1000;
    lvdt2 = DATA(:,9)  / 1000;
    lvdt4 = DATA(:,11) / 1000;

    % LVDT nivel 2
    lvdt5 = DATA(:,12) / 1000;
    lvdt6 = DATA(:,13) / 1000;
    lvdt8 = DATA(:,15) / 1000;

    % Piezos nivel 1 [g -> m/s^2]
    piez1 = DATA(:,22) * 9.81;   % mide X
    piez2 = DATA(:,23) * 9.81;   % mide X
    piez4 = DATA(:,25) * 9.81;   % mide Y

    % Piezos nivel 2 [g -> m/s^2]
    piez5 = DATA(:,26) * 9.81;   % mide X
    piez6 = DATA(:,27) * 9.81;   % mide X
    piez8 = DATA(:,29) * 9.81;   % mide Y

    %% --- FILTRO: eliminar puntos > 5g mediante interpolacion lineal ---
    umbral = 5 * 9.81;  % m/s^2
    piezos_raw = {piez1, piez2, piez4, piez5, piez6, piez8};
    for j = 1:numel(piezos_raw)
        p = piezos_raw{j};
        mask = abs(p) > umbral;
        if any(mask) && any(~mask)
            p(mask) = interp1(find(~mask), p(~mask), find(mask), 'linear', 'extrap');
        end
        piezos_raw{j} = p;
    end
    [piez1, piez2, piez4, piez5, piez6, piez8] = deal(piezos_raw{:});

    %% --- DESPLAZAMIENTOS CM NIVEL 1 (respecto a base) ---
    theta1 = (lvdt2 - lvdt1) ./ (uy12 - uy22);
    uCM1x  = lvdt1 + theta1 .* uy12;
    uCM1y  = lvdt4 - theta1 .* ux42;

    %% --- DESPLAZAMIENTOS CM NIVEL 2 (respecto al suelo) ---
    u1_5 = uCM1x - theta1 .* (uy5g2 - CM1y);
    u1_6 = uCM1x - theta1 .* (uy6g2 - CM1y);
    v1_8 = uCM1y + theta1 .* (ux8g2 - CM1x);

    u5 = u1_5 + lvdt5;
    u6 = u1_6 + lvdt6;
    v8 = v1_8 + lvdt8;

    theta2 = (u6 - u5) ./ (uy52 - uy62);
    uCM2x  = u5 + theta2 .* uy52;
    uCM2y  = v8 - theta2 .* ux82;

    %% --- ACELERACIONES CM NIVEL 1 (solido rigido con 3 piezos) ---
    % theta_acc1: rotacion del nivel 1, determinada con Piez1 y Piez2 (miden X)
    theta_acc1 = (piez2 - piez1) ./ (yP1_1 - yP2_1);
    % Traslacion CM en X
    aCM1x = piez1 + theta_acc1 .* yP1_1;
    % Traslacion CM en Y: Piez4 mide Y, mismo theta_acc1
    aCM1y = piez4 - theta_acc1 .* xP4_1;

    %% --- ACELERACIONES CM NIVEL 2 (solido rigido con 3 piezos) ---
    % theta_acc2: rotacion del nivel 2, determinada con Piez5 y Piez6 (miden X)
    theta_acc2 = (piez6 - piez5) ./ (yP5_2 - yP6_2);
    % Traslacion CM en X
    aCM2x = piez5 + theta_acc2 .* yP5_2;
    % Traslacion CM en Y: Piez8 mide Y, mismo theta_acc2
    aCM2y = piez8 - theta_acc2 .* xP8_2;

    %% --- FUERZAS DE INERCIA Y RESULTANTE EN BASE ---
    F1x = -m1 .* aCM1x;
    F1y = -m1 .* aCM1y;
    F2x = -m2 .* aCM2x;
    F2y = -m2 .* aCM2y;

    Fbx = F1x + F2x;
    Fby = F1y + F2y;

    %% --- TIEMPO SECUENCIAL ---
    dt_gap   = mean(diff(t));
    t_local  = t - t(1) + t_offset;
    t_offset = t_local(end) + dt_gap;

    n_prev = numel(t_seq);

    %% --- ACUMULAR ---
    t_seq     = [t_seq;     t_local];
uCM2x_seq = [uCM2x_seq; uCM2x];
uCM2y_seq = [uCM2y_seq; uCM2y];
aCM1x_seq = [aCM1x_seq; aCM1x];
aCM1y_seq = [aCM1y_seq; aCM1y];
aCM2x_seq = [aCM2x_seq; aCM2x];
aCM2y_seq = [aCM2y_seq; aCM2y];
Fbx_seq   = [Fbx_seq;   Fbx];
Fby_seq   = [Fby_seq;   Fby];
limites   = [limites, numel(t_seq)];

    %% --- DETECCION DE MAXIMOS SECUENCIALES ---
    % Positivos X
    [pks, locs] = findpeaks(uCM2x);
    for i = 1:numel(locs)
        if pks(i) > maxPos_x
            maxPos_x = pks(i);
            gi = n_prev + locs(i);
            pts_x_pos = [pts_x_pos; t_seq(gi), uCM2x_seq(gi)*1000, aCM2x_seq(gi), Fbx_seq(gi)];
        end
    end

    % Negativos X
    [pks, locs] = findpeaks(-uCM2x);
    for i = 1:numel(locs)
        if pks(i) > maxNeg_x
            maxNeg_x = pks(i);
            gi = n_prev + locs(i);
            pts_x_neg = [pts_x_neg; t_seq(gi), uCM2x_seq(gi)*1000, aCM2x_seq(gi), Fbx_seq(gi)];
        end
    end

    % Positivos Y
    [pks, locs] = findpeaks(uCM2y);
    for i = 1:numel(locs)
        if pks(i) > maxPos_y
            maxPos_y = pks(i);
            gi = n_prev + locs(i);
            pts_y_pos = [pts_y_pos; t_seq(gi), uCM2y_seq(gi)*1000, aCM2y_seq(gi), Fby_seq(gi)];
        end
    end

    % Negativos Y
    [pks, locs] = findpeaks(-uCM2y);
    for i = 1:numel(locs)
        if pks(i) > maxNeg_y
            maxNeg_y = pks(i);
            gi = n_prev + locs(i);
            pts_y_neg = [pts_y_neg; t_seq(gi), uCM2y_seq(gi)*1000, aCM2y_seq(gi), Fby_seq(gi)];
        end
    end
end

%% ========================================================
%  ANALISIS 1 — GRAFICOS COMPLETOS (todos los ensayos)
%% GRAFICO 1 - Desplazamiento X CM2 secuencial
figure('Name','Desplazamiento X - CM Nivel 2','NumberTitle','off');
hold on; grid on;
ini = 1;
for k = 1:nSim
    idx = ini:limites(k);
    plot(t_seq(idx), uCM2x_seq(idx)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
if ~isempty(pts_x_pos)
    plot(pts_x_pos(:,1), pts_x_pos(:,2), 'ro', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (+)');
end
if ~isempty(pts_x_neg)
    plot(pts_x_neg(:,1), pts_x_neg(:,2), 'rs', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (-)');
end
xlabel('Tiempo secuencial (s)');
ylabel('u_{CM2,x} (mm)');
title('Desplazamiento X en CM Nivel 2');
legend('Location','best');

%% GRAFICO 2 - Desplazamiento Y CM2 secuencial
figure('Name','Desplazamiento Y - CM Nivel 2','NumberTitle','off');
hold on; grid on;
ini = 1;
for k = 1:nSim
    idx = ini:limites(k);
    plot(t_seq(idx), uCM2y_seq(idx)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
if ~isempty(pts_y_pos)
    plot(pts_y_pos(:,1), pts_y_pos(:,2), 'ro', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (+)');
end
if ~isempty(pts_y_neg)
    plot(pts_y_neg(:,1), pts_y_neg(:,2), 'rs', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (-)');
end
xlabel('Tiempo secuencial (s)');
ylabel('u_{CM2,y} (mm)');
title('Desplazamiento Y en CM Nivel 2');
legend('Location','best');

%% GRAFICO 3 - Aceleracion absoluta X (Nivel 1 y 2)
figure('Name','Aceleracion X - CM Nivel 1 y 2','NumberTitle','off');
ax1 = subplot(2,1,1); hold on; grid on;
ax2 = subplot(2,1,2); hold on; grid on;
ini = 1;
for k = 1:nSim
    idx = ini:limites(k);
    plot(ax1, t_seq(idx), aCM2x_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax2, t_seq(idx), aCM1x_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
ylabel(ax1,'a_{CM2,x} (m/s^2)'); title(ax1,'Aceleracion absoluta X - Nivel 2 (CM)'); legend(ax1,'Location','best');
ylabel(ax2,'a_{CM1,x} (m/s^2)'); title(ax2,'Aceleracion absoluta X - Nivel 1 (CM)'); legend(ax2,'Location','best');
xlabel(ax2,'Tiempo secuencial (s)');

%% GRAFICO 4 - Aceleracion absoluta Y (Nivel 1 y 2)
figure('Name','Aceleracion Y - CM Nivel 1 y 2','NumberTitle','off');
ax3 = subplot(2,1,1); hold on; grid on;
ax4 = subplot(2,1,2); hold on; grid on;
ini = 1;
for k = 1:nSim
    idx = ini:limites(k);
    plot(ax3, t_seq(idx), aCM2y_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax4, t_seq(idx), aCM1y_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
ylabel(ax3,'a_{CM2,y} (m/s^2)'); title(ax3,'Aceleracion absoluta Y - Nivel 2 (CM)'); legend(ax3,'Location','best');
ylabel(ax4,'a_{CM1,y} (m/s^2)'); title(ax4,'Aceleracion absoluta Y - Nivel 1 (CM)'); legend(ax4,'Location','best');
xlabel(ax4,'Tiempo secuencial (s)');

%% GRAFICO 5 - Resultante fuerzas de inercia en la base
figure('Name','Resultante Fuerzas de Inercia en Base','NumberTitle','off');
ax5 = subplot(2,1,1); hold on; grid on;
ax6 = subplot(2,1,2); hold on; grid on;
ini = 1;
for k = 1:nSim
    idx = ini:limites(k);
    plot(ax5, t_seq(idx), Fbx_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax6, t_seq(idx), Fby_seq(idx), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    ini = limites(k)+1;
end
ylabel(ax5,'F_{base,x} (kN)'); title(ax5,'Resultante fuerzas de inercia en base - X'); legend(ax5,'Location','best');
ylabel(ax6,'F_{base,y} (kN)'); title(ax6,'Resultante fuerzas de inercia en base - Y'); legend(ax6,'Location','best');
xlabel(ax6,'Tiempo secuencial (s)');

%% ========================================================
%  IMPRESION DE PUNTOS DE MAXIMO DESPLAZAMIENTO
fprintf('\n--- Puntos de maximo desplazamiento X (positivos) ---\n');
fprintf('  t(s)       u_CM2x(mm)   a_CM2x(m/s2)   F_base(kN)\n');
for i = 1:size(pts_x_pos,1)
    fprintf('  %8.3f   %10.3f   %12.4f   %10.4f\n', pts_x_pos(i,1), pts_x_pos(i,2), pts_x_pos(i,3), pts_x_pos(i,4));
end

fprintf('\n--- Puntos de maximo desplazamiento X (negativos) ---\n');
fprintf('  t(s)       u_CM2x(mm)   a_CM2x(m/s2)   F_base(kN)\n');
for i = 1:size(pts_x_neg,1)
    fprintf('  %8.3f   %10.3f   %12.4f   %10.4f\n', pts_x_neg(i,1), pts_x_neg(i,2), pts_x_neg(i,3), pts_x_neg(i,4));
end

fprintf('\n--- Puntos de maximo desplazamiento Y (positivos) ---\n');
fprintf('  t(s)       u_CM2y(mm)   a_CM2y(m/s2)   F_base(kN)\n');
for i = 1:size(pts_y_pos,1)
    fprintf('  %8.3f   %10.3f   %12.4f   %10.4f\n', pts_y_pos(i,1), pts_y_pos(i,2), pts_y_pos(i,3), pts_y_pos(i,4));
end

fprintf('\n--- Puntos de maximo desplazamiento Y (negativos) ---\n');
fprintf('  t(s)       u_CM2y(mm)   a_CM2y(m/s2)   F_base(kN)\n');
for i = 1:size(pts_y_neg,1)
    fprintf('  %8.3f   %10.3f   %12.4f   %10.4f\n', pts_y_neg(i,1), pts_y_neg(i,2), pts_y_neg(i,3), pts_y_neg(i,4));
end

%% ========================================================
%  ANALISIS 2 — Mismos graficos sin Calitri200 ni Calitri300
%  (ensayos k = 1,2,3,5 : Calitri35, Calitri50, Calitri100, Calitri200bis)
idx_A2 = [1, 2, 3, 5];   % indices de ensayos a incluir

%  Reconstruir maximos solo con los ensayos seleccionados
maxPos_x2 = 0;   maxNeg_x2 = 0;
maxPos_y2 = 0;   maxNeg_y2 = 0;
pts_x_pos2 = [];   pts_x_neg2 = [];
pts_y_pos2 = [];   pts_y_neg2 = [];

for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);

    uCM2x_k = uCM2x_seq(idx_k);
    uCM2y_k = uCM2y_seq(idx_k);

    [pks, locs] = findpeaks(uCM2x_k);
    for i = 1:numel(locs)
        if pks(i) > maxPos_x2
            maxPos_x2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_x_pos2 = [pts_x_pos2; t_seq(gi), uCM2x_seq(gi)*1000, aCM2x_seq(gi), Fbx_seq(gi)];
        end
    end
    [pks, locs] = findpeaks(-uCM2x_k);
    for i = 1:numel(locs)
        if pks(i) > maxNeg_x2
            maxNeg_x2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_x_neg2 = [pts_x_neg2; t_seq(gi), uCM2x_seq(gi)*1000, aCM2x_seq(gi), Fbx_seq(gi)];
        end
    end
    [pks, locs] = findpeaks(uCM2y_k);
    for i = 1:numel(locs)
        if pks(i) > maxPos_y2
            maxPos_y2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_y_pos2 = [pts_y_pos2; t_seq(gi), uCM2y_seq(gi)*1000, aCM2y_seq(gi), Fby_seq(gi)];
        end
    end
    [pks, locs] = findpeaks(-uCM2y_k);
    for i = 1:numel(locs)
        if pks(i) > maxNeg_y2
            maxNeg_y2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_y_neg2 = [pts_y_neg2; t_seq(gi), uCM2y_seq(gi)*1000, aCM2y_seq(gi), Fby_seq(gi)];
        end
    end
end

%% GRAFICO 6 - [A2] Desplazamiento X CM2 (sin Calitri200 ni Calitri300)
figure('Name','[A2] Desplazamiento X - CM Nivel 2','NumberTitle','off');
hold on; grid on;
for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(t_seq(idx_k), uCM2x_seq(idx_k)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
if ~isempty(pts_x_pos2)
    plot(pts_x_pos2(:,1), pts_x_pos2(:,2), 'ro', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (+)');
end
if ~isempty(pts_x_neg2)
    plot(pts_x_neg2(:,1), pts_x_neg2(:,2), 'rs', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (-)');
end
xlabel('Tiempo secuencial (s)'); ylabel('u_{CM2,x} (mm)');
title('[A2] Desplazamiento X en CM Nivel 2'); legend('Location','best');

%% GRAFICO 7 - [A2] Desplazamiento Y CM2 (sin Calitri200 ni Calitri300)
figure('Name','[A2] Desplazamiento Y - CM Nivel 2','NumberTitle','off');
hold on; grid on;
for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(t_seq(idx_k), uCM2y_seq(idx_k)*1000, 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
if ~isempty(pts_y_pos2)
    plot(pts_y_pos2(:,1), pts_y_pos2(:,2), 'ro', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (+)');
end
if ~isempty(pts_y_neg2)
    plot(pts_y_neg2(:,1), pts_y_neg2(:,2), 'rs', 'MarkerFaceColor','r', 'MarkerSize',7, 'DisplayName','Nuevo max (-)');
end
xlabel('Tiempo secuencial (s)'); ylabel('u_{CM2,y} (mm)');
title('[A2] Desplazamiento Y en CM Nivel 2'); legend('Location','best');

%% GRAFICO 8 - [A2] Aceleracion absoluta X (sin Calitri200 ni Calitri300)
figure('Name','[A2] Aceleracion X - CM Nivel 1 y 2','NumberTitle','off');
ax1b = subplot(2,1,1); hold on; grid on;
ax2b = subplot(2,1,2); hold on; grid on;
for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(ax1b, t_seq(idx_k), aCM2x_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax2b, t_seq(idx_k), aCM1x_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
ylabel(ax1b,'a_{CM2,x} (m/s^2)'); title(ax1b,'[A2] Aceleracion absoluta X - Nivel 2 (CM)'); legend(ax1b,'Location','best');
ylabel(ax2b,'a_{CM1,x} (m/s^2)'); title(ax2b,'[A2] Aceleracion absoluta X - Nivel 1 (CM)'); legend(ax2b,'Location','best');
xlabel(ax2b,'Tiempo secuencial (s)');

%% GRAFICO 9 - [A2] Aceleracion absoluta Y (sin Calitri200 ni Calitri300)
figure('Name','[A2] Aceleracion Y - CM Nivel 1 y 2','NumberTitle','off');
ax3b = subplot(2,1,1); hold on; grid on;
ax4b = subplot(2,1,2); hold on; grid on;
for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(ax3b, t_seq(idx_k), aCM2y_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax4b, t_seq(idx_k), aCM1y_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
ylabel(ax3b,'a_{CM2,y} (m/s^2)'); title(ax3b,'[A2] Aceleracion absoluta Y - Nivel 2 (CM)'); legend(ax3b,'Location','best');
ylabel(ax4b,'a_{CM1,y} (m/s^2)'); title(ax4b,'[A2] Aceleracion absoluta Y - Nivel 1 (CM)'); legend(ax4b,'Location','best');
xlabel(ax4b,'Tiempo secuencial (s)');

%% GRAFICO 10 - [A2] Resultante fuerzas de inercia en base (sin Calitri200 ni Calitri300)
figure('Name','[A2] Resultante Fuerzas de Inercia en Base','NumberTitle','off');
ax5b = subplot(2,1,1); hold on; grid on;
ax6b = subplot(2,1,2); hold on; grid on;
for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(ax5b, t_seq(idx_k), Fbx_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax6b, t_seq(idx_k), Fby_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
ylabel(ax5b,'F_{base,x} (kN)'); title(ax5b,'[A2] Resultante fuerzas de inercia en base - X'); legend(ax5b,'Location','best');
ylabel(ax6b,'F_{base,y} (kN)'); title(ax6b,'[A2] Resultante fuerzas de inercia en base - Y'); legend(ax6b,'Location','best');
xlabel(ax6b,'Tiempo secuencial (s)');

%% GRAFICO 11 - Fuerza vs Desplazamiento Nivel 2 (todos los ensayos)
figure('Name','Fuerza vs Desplazamiento - Nivel 2','NumberTitle','off');
ax7 = subplot(2,1,1); hold on; grid on;
ax8 = subplot(2,1,2); hold on; grid on;
for k = 1:nSim
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(ax7, uCM2x_seq(idx_k)*1000, Fbx_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax8, uCM2y_seq(idx_k)*1000, Fby_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
cap_x = [];
if ~isempty(pts_x_pos), cap_x = [cap_x; pts_x_pos(:,[2,4])]; end
if ~isempty(pts_x_neg), cap_x = [cap_x; pts_x_neg(:,[2,4])]; end
if ~isempty(cap_x)
    cap_x = sortrows(cap_x, 1);
    plot(ax7, cap_x(:,1), cap_x(:,2), 'k-o', 'LineWidth', 2, 'MarkerSize', 6, ...
         'MarkerFaceColor','k', 'DisplayName','Curva capacidad');
end
cap_y = [];
if ~isempty(pts_y_pos), cap_y = [cap_y; pts_y_pos(:,[2,4])]; end
if ~isempty(pts_y_neg), cap_y = [cap_y; pts_y_neg(:,[2,4])]; end
if ~isempty(cap_y)
    cap_y = sortrows(cap_y, 1);
    plot(ax8, cap_y(:,1), cap_y(:,2), 'k-o', 'LineWidth', 2, 'MarkerSize', 6, ...
         'MarkerFaceColor','k', 'DisplayName','Curva capacidad');
end
xlabel(ax7,'u_{CM2,x} (mm)'); ylabel(ax7,'F_{base,x} (kN)');
title(ax7,'Fuerza vs Desplazamiento Nivel 2 - X'); legend(ax7,'Location','best');
xlabel(ax8,'u_{CM2,y} (mm)'); ylabel(ax8,'F_{base,y} (kN)');
title(ax8,'Fuerza vs Desplazamiento Nivel 2 - Y'); legend(ax8,'Location','best');

%% GRAFICO 12 - [A2] Fuerza vs Desplazamiento Nivel 2 (sin Calitri200 ni Calitri300)
figure('Name','[A2] Fuerza vs Desplazamiento - Nivel 2','NumberTitle','off');
ax9 = subplot(2,1,1); hold on; grid on;
ax10 = subplot(2,1,2); hold on; grid on;
for k = idx_A2
    ini_k = 1; if k > 1, ini_k = limites(k-1)+1; end
    idx_k = ini_k:limites(k);
    plot(ax9, uCM2x_seq(idx_k)*1000, Fbx_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
    plot(ax10, uCM2y_seq(idx_k)*1000, Fby_seq(idx_k), 'Color', colores(k,:), 'DisplayName', etiquetas{k});
end
cap_x2 = [];
if ~isempty(pts_x_pos2), cap_x2 = [cap_x2; pts_x_pos2(:,[2,4])]; end
if ~isempty(pts_x_neg2), cap_x2 = [cap_x2; pts_x_neg2(:,[2,4])]; end
if ~isempty(cap_x2)
    cap_x2 = sortrows(cap_x2, 1);
    plot(ax9, cap_x2(:,1), cap_x2(:,2), 'k-o', 'LineWidth', 2, 'MarkerSize', 6, ...
         'MarkerFaceColor','k', 'DisplayName','Curva capacidad');
end
cap_y2 = [];
if ~isempty(pts_y_pos2), cap_y2 = [cap_y2; pts_y_pos2(:,[2,4])]; end
if ~isempty(pts_y_neg2), cap_y2 = [cap_y2; pts_y_neg2(:,[2,4])]; end
if ~isempty(cap_y2)
    cap_y2 = sortrows(cap_y2, 1);
    plot(ax10, cap_y2(:,1), cap_y2(:,2), 'k-o', 'LineWidth', 2, 'MarkerSize', 6, ...
         'MarkerFaceColor','k', 'DisplayName','Curva capacidad');
end
xlabel(ax9,'u_{CM2,x} (mm)'); ylabel(ax9,'F_{base,x} (kN)');
title(ax9,'[A2] Fuerza vs Desplazamiento Nivel 2 - X'); legend(ax9,'Location','best');
xlabel(ax10,'u_{CM2,y} (mm)'); ylabel(ax10,'F_{base,y} (kN)');
title(ax10,'[A2] Fuerza vs Desplazamiento Nivel 2 - Y'); legend(ax10,'Location','best');
