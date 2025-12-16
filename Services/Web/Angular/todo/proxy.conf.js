const target = process.env.services__API__HTTPS__0 || process.env['NG_APP_API_URL']

const PROXY_CONFIG = [
  {
    context: [
      "/api"
    ],
    target: target,
    secure: false, // Set to true if your backend uses a valid SSL certificate
    changeOrigin: true,
    logLevel: "debug"
  }
];

module.exports = PROXY_CONFIG;