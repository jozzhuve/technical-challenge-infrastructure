---
title: Ejercicio 2 - Rutas óptimas
---

# Ejercicio 2 - Rutas óptimas

## Problema que resolví

El servicio recibe tres elementos: la ubicación del accidente, una lista de depósitos disponibles y un grafo ponderado. A partir de eso debe identificar qué depósito puede llegar al destino con la menor distancia y devolver el camino encontrado.

No asumí un depósito fijo ni un grafo cerrado. El grafo forma parte del request para mantener el caso flexible.

## Diseño

Separé el problema en tres piezas:

```text
HTTP Handler
    |
CalculateOptimalRouteService
    |
Dijkstra
    |
Graph
```

El handler se limita a recibir y devolver HTTP. El caso de uso decide qué depósito es el más conveniente. Dijkstra conoce únicamente nodos, vecinos y pesos.

## Dijkstra

La implementación utiliza una cola de prioridad y mantiene la distancia mínima conocida para cada nodo.

El flujo es:

```text
origen
  |
  v
cola de prioridad
  |
  v
extraer menor distancia
  |
  +--> evaluar vecinos
  |       |
  |       +--> mejorar distancia si corresponde
  |
  v
destino alcanzado
  |
  v
reconstruir camino
```

Los pesos negativos se rechazan porque Dijkstra no es válido para ese escenario.

## Múltiples depósitos

Para cada depósito se calcula la mejor ruta hacia el accidente. Si un depósito no puede alcanzar el destino, no invalida automáticamente toda la operación; se siguen evaluando las demás alternativas.

Al final se selecciona la menor distancia válida.

```text
Depósito A ---- 12 km ----\
Depósito B ----- 7 km -----+--> menor = B
Depósito C --- no route ---/
```

Si ningún depósito puede llegar al destino, el servicio devuelve un error controlado `422`.

## Contrato HTTP

Endpoint principal:

```text
POST /api/v1/routes/optimal
```

También existe:

```text
POST /routes/optimal
```

como alias simple para pruebas.

La respuesta incluye el depósito seleccionado, la distancia total y el camino calculado.

## Por qué separé el algoritmo

Quería evitar una implementación donde Dijkstra terminara dentro del handler y solo pudiera probarse realizando requests HTTP.

Al mantenerlo independiente:

- puedo probar el algoritmo de forma aislada;
- puedo cambiar el transporte sin modificarlo;
- puedo reemplazar el origen del grafo;
- el caso de uso mantiene la regla de selección de depósitos fuera del algoritmo.

## Evolución posible

Para un escenario real, el grafo probablemente no viajaría completo en cada solicitud. Podría venir de una fuente geoespacial, un servicio de mapas o una representación persistida de la red vial.

En ese momento también revisaría si Dijkstra sigue siendo suficiente o si conviene usar A*, dependiendo de la cantidad de nodos, disponibilidad de coordenadas y características del problema.

Para el alcance actual mantuve Dijkstra porque es el algoritmo solicitado y permite demostrar correctamente el caso sin agregar dependencias externas.