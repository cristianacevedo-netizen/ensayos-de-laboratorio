    % Filtro: eliminar puntos > 5g mediante interpolacion lineal
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
