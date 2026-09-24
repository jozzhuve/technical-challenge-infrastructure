import type { Config } from '@docusaurus/types';

const config: Config = {
  title: 'Reto Técnico - Arquitectura de Solución',
  tagline: 'Diseño, decisiones técnicas y evidencia de ejecución',
  url: 'https://example.com',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'Arquitectura de Solución',
      items: [{ to: '/', label: 'Documentación', position: 'left' }],
    },
    footer: {
      style: 'dark',
      copyright: `Reto técnico - ${new Date().getFullYear()}`,
    },
  },
};

export default config;
