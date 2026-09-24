---
title: Ejercicio 1 - Traductor de endosos
---

# Ejercicio 1 - Traductor de endosos

## Problema que identifiqué

La dificultad del ejercicio no está en transformar un objeto plano en un JSON anidado. El punto importante es que la estructura depende del producto y del tipo de endoso, y además cambia el orden, las etiquetas, los defaults y los eventos aplicados.

Si esas reglas se implementan directamente en código, el servicio termina creciendo con condicionales por producto y cada nueva variante obliga a desplegar una nueva versión aunque el cambio sea solamente de configuración.

Por eso traté la plantilla como dato.

## Diseño

La clave funcional de una plantilla es:

```text
producto + tipoEndoso + versión
```

Solo una versión puede estar activa para una misma combinación de producto y tipo de endoso.

El modelo se divide en tres tablas:

### `endorsement_templates`

Representa la cabecera de la plantilla. Mantiene producto, tipo de endoso, versión, estado activo y valores generales utilizados para construir la salida.

### `endorsement_template_fields`

Define cada campo dinámico:

```text
label
source_field
default_value
required
field_order
```

La resolución sigue esta lógica:

```text
valor recibido
    |
    | existe
    +-------> usar valor recibido
    |
    | no existe
    v
valor por defecto
    |
    | existe
    +-------> usar default
    |
    | no existe y es obligatorio
    v
error de validación
```

### `endorsement_template_events`

Define los eventos y el orden en el que deben aparecer en `eventAppliedEntities`.

## Flujo

```text
POST /api/v1/endorsements/translate
              |
              v
      Validación del payload
              |
              v
  Buscar plantilla activa por
   producto + tipoEndoso
              |
              v
       Ordenar los campos
              |
              v
 Resolver valor / default / requerido
              |
              v
       Ordenar eventos
              |
              v
      Construir respuesta
```

También se mantiene `POST /endorse/translate` para respetar la ruta solicitada originalmente en el reto, mientras que `/api/v1/endorsements/translate` deja explícito el versionado del contrato.

## Separación de responsabilidades

La estructura interna queda de esta manera:

```text
Route
  |
Controller
  |
EndorsementTranslatorService
  |
EndorsementTemplateRepository (port)
  |
TypeOrmEndorsementTemplateRepository
  |
PostgreSQL
```

El caso de uso no depende de Hapi ni de TypeORM.

## Manejo de errores

No devuelvo `500` para escenarios que el servicio puede reconocer.

Ejemplos:

- payload inválido: error de validación;
- plantilla no configurada: `404`;
- campo obligatorio sin valor ni default: error funcional;
- error no esperado: error técnico con `traceId`.

## Extensibilidad

La prueba más importante de este diseño no es el ejemplo `Rumbo / CambioFrecuencia`, sino la capacidad de incorporar otra combinación agregando una plantilla y sus campos en base de datos sin modificar el traductor.

En un escenario productivo, la administración de estas plantillas podría exponerse mediante un backoffice controlado, con versionado, auditoría y flujo de publicación. Para el alcance del reto mantuve esa configuración en scripts SQL porque es suficiente para demostrar el diseño.

## Decisiones que no tomé

No utilicé un motor de reglas porque el problema actual no requiere esa complejidad. La variabilidad se resuelve con metadatos ordenados y valores por defecto; introducir un rule engine en este punto agregaría operación y mantenimiento sin una necesidad demostrada.