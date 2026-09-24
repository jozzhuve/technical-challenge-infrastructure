import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'category',
      label: 'Visión',
      collapsed: false,
      items: ['intro', 'contexto-y-alcance'],
    },
    {
      type: 'category',
      label: 'Arquitectura',
      collapsed: false,
      items: ['architecture', 'repositorios'],
    },
    {
      type: 'category',
      label: 'Ejercicios',
      collapsed: false,
      items: ['ejercicio-1-endosos', 'ejercicio-2-rutas', 'loan-to-be'],
    },
    {
      type: 'category',
      label: 'Plataforma',
      collapsed: false,
      items: ['gcp-target', 'seguridad-resiliencia', 'costos-operacion'],
    },
    {
      type: 'category',
      label: 'Entrega y operación',
      collapsed: false,
      items: ['pruebas-evidencias', 'ejecucion-local', 'decisiones', 'riesgos-evolucion'],
    },
  ],
};

export default sidebars;
