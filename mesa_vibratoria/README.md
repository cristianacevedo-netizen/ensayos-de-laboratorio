# Análisis de Mesa Vibratoria

## Descripción

Este directorio contiene el análisis dinámico completo de un ensayo de mesa vibratoria (*shaking table*), desarrollado como parte del curso de **Ensayos Dinámicos**.

Una mesa vibratoria es un dispositivo de laboratorio que permite simular movimientos sísmicos y estudiar el comportamiento dinámico de estructuras a escala, siendo fundamental para la validación de modelos analíticos y el estudio de fenómenos como resonancia y amortiguamiento.

## Contenido

| Archivo | Descripción |
|---------|-------------|
| `analisis_mesa_vibratoria.ipynb` | Notebook principal con el análisis completo |
| `datos/` | Directorio donde se guardan las figuras generadas |

## Temas cubiertos en el notebook

1. **Marco Teórico** — Sistema de 1 GDL, ecuación de movimiento, parámetros dinámicos
2. **Modelo Matemático** — Definición de masa, rigidez, amortiguamiento y propiedades derivadas (ωₙ, fₙ, Tₙ)
3. **Configuración del ensayo** — Generación del acelerograma sintético de entrada
4. **Método de Newmark** — Integración numérica paso a paso (β = 0.25, γ = 0.5)
5. **Estimación del amortiguamiento**
   - Decremento logarítmico (vibración libre)
   - Semiancho de banda (Half-Power Bandwidth, -3 dB)
6. **Análisis en frecuencia** — FFT de la excitación y la respuesta
7. **Función de Respuesta en Frecuencia (FRF)** — Transmisibilidad analítica y comparación numérica
8. **Espectros de respuesta sísmica** — Sₐ, Sᵥ, Sᵈ para distintos niveles de amortiguamiento
9. **Resultados y discusión** — Tabla resumen y comparación teórica-experimental
10. **Conclusiones** — Interpretación de los resultados obtenidos

## Requisitos

```
numpy
matplotlib
scipy
jupyter
```

Instalación:

```bash
pip install numpy matplotlib scipy jupyter
```

## Ejecución

```bash
cd mesa_vibratoria
jupyter notebook analisis_mesa_vibratoria.ipynb
```

## Figuras generadas

Al ejecutar el notebook se generarán automáticamente en la carpeta `datos/`:

- `acelerograma_entrada.png` — Señal de aceleración de la mesa
- `respuesta_tiempo.png` — Desplazamiento, velocidad y aceleración de la estructura
- `vibracion_libre.png` — Decremento logarítmico en vibración libre
- `espectros_FFT.png` — Espectros de amplitud (FFT)
- `FRF_transmisibilidad.png` — Función de Respuesta en Frecuencia
- `espectros_respuesta.png` — Espectros de respuesta sísmica (Sₐ, Sᵥ, Sᵈ)
- `comparacion_resultados.png` — FRF numérica vs. analítica

## Fundamento teórico

La ecuación de movimiento del sistema de 1 GDL ante excitación de base es:

$$m\ddot{u}(t) + c\dot{u}(t) + ku(t) = -m\ddot{u}_g(t)$$

cuya solución en función de los parámetros naturales del sistema es:

$$\ddot{u}(t) + 2\zeta\omega_n\dot{u}(t) + \omega_n^2 u(t) = -\ddot{u}_g(t)$$

donde:
- `ωₙ = √(k/m)` — frecuencia natural circular [rad/s]
- `ζ = c / (2mωₙ)` — razón de amortiguamiento crítico [-]
- `Tₙ = 2π/ωₙ` — período natural [s]

## Referencias

- Chopra, A. K. (2017). *Dynamics of Structures* (5ª ed.). Pearson.
- Clough, R. W. & Penzien, J. (2003). *Dynamics of Structures* (3ª ed.). CSI.
- Newmark, N. M. (1959). A method of computation for structural dynamics. *ASCE*.
