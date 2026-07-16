import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Gera uma build autocontida (.next/standalone) para uma imagem Docker enxuta.
  output: "standalone",
};

export default nextConfig;
