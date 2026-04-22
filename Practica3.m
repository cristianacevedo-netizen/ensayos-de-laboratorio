<existing file content>...%% ========================================================
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
    aCM2x_k = aCM2x_seq(idx_k);
    aCM2y_k = aCM2y_seq(idx_k);

    [pks, locs] = findpeaks(uCM2x_k);
    for i = 1:numel(locs)
        if pks(i) > maxPos_x2
            maxPos_x2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_x_pos2 = [pts_x_pos2; t_seq(gi), uCM2x_seq(gi)*1000, aCM2x_seq(gi)];
        end
    end
    [pks, locs] = findpeaks(-uCM2x_k);
    for i = 1:numel(locs)
        if pks(i) > maxNeg_x2
            maxNeg_x2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_x_neg2 = [pts_x_neg2; t_seq(gi), uCM2x_seq(gi)*1000, aCM2x_seq(gi)];
        end
    end
    [pks, locs] = findpeaks(uCM2y_k);
    for i = 1:numel(locs)
        if pks(i) > maxPos_y2
            maxPos_y2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_y_pos2 = [pts_y_pos2; t_seq(gi), uCM2y_seq(gi)*1000, aCM2y_seq(gi)];
        end
    end
    [pks, locs] = findpeaks(-uCM2y_k);
    for i = 1:numel(locs)
        if pks(i) > maxNeg_y2
            maxNeg_y2 = pks(i);
            gi = ini_k - 1 + locs(i);
            pts_y_neg2 = [pts_y_neg2; t_seq(gi), uCM2y_seq(gi)*1000, aCM2y_seq(gi)];
        end
    end
end

%% GRAFICO 6 — Desplazamiento X CM2 (sin Calitri200 ni Calitri300)
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

%% GRAFICO 7 — Desplazamiento Y CM2 (sin Calitri200 ni Calitri300)
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

%% GRAFICO 8 — Aceleracion absoluta X (sin Calitri200 ni Calitri300)
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

%% GRAFICO 9 — Aceleracion absoluta Y (sin Calitri200 ni Calitri300)
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

%% GRAFICO 10 — Resultante fuerzas de inercia en base (sin Calitri200 ni Calitri300)
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