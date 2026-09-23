import type { Config } from '@docusaurus/types';

const config: Config = {
  title: 'Technical Challenge',
  tagline: 'Decisiones de arquitectura, ejecución y calidad',
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
      title: 'Technical Challenge',
      items: [{ to: '/', label: 'Documentación', position: 'left' }],
    },
  },
};

export default config;
