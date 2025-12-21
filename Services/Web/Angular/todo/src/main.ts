import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

console.log('ENV TEST:', import.meta.env);

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
