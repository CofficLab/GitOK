export interface PluginPackage {
  name: string;
  version: string;
  main: string;
  description: string;
  author: string;
  license: string;
  dependencies: Record<string, string>;
  devDependencies: Record<string, string>;
  scripts: Record<string, string>;
  keywords: string[];
  repository: string;
  page?: string;
}
