/// <reference types="@ngx-env/builder" />

interface ImportMetaEnv {
  readonly NODE_ENV: 'development' | 'production';
  readonly NG_APP_apiBaseUrl: string;
  readonly NG_APP_AzureAd__ClientID: string;
  readonly NG_APP_AzureAd__TenantId: string;
  readonly NG_APP_RedirectUri: string;
  readonly NG_APP_PostLogoutRedirectUri: string;
  readonly NG_APP_apiScopes: string;
  readonly NG_APP_bypassAuthInDev: string;
  readonly NG_APP_AzureAd__Audience: string;
  readonly NG_APP_AzureAd__Instance: string;
  readonly NG_APP_API_BASE_URL: string;
  readonly NG_APP_AzureAd__Scopes: string;
  readonly NG_APP_production: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

// 2. Use _NGX_ENV_.YOUR_ENV_VAR in your code. (customizable)
// You can modify the name of the variable in angular.json.
// ngxEnv: {
//  define: '_NGX_ENV_',
// }
declare const _NGX_ENV_: Env;

// 3. Use process.env.YOUR_ENV_VAR in your code. (deprecated)
declare namespace NodeJS {
  export interface ProcessEnv extends Env {}
}