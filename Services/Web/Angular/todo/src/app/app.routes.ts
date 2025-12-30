import { Routes } from '@angular/router';
import { Home } from './pages/home/home';
import { About } from './pages/about/about';
import { DynamicHtmlLoaderComponent } from './components/dynamic-html-loader/dynamic-html-loader';

export const routes: Routes = [
    {
        path: 'clipboard/:clipboardId',
        component: Home,
    },
    {
        path: 'about',
        component: About
    },
    {
        path: '',
        component: Home,
    }
    ,
    {
        path: 'privacy-policy',
        component: DynamicHtmlLoaderComponent,
        data: { filePath: './policies/privacy-policy.html' }
    },
    {
        path: 'terms-of-use',
        component: DynamicHtmlLoaderComponent,
        data: { filePath: './policies/terms-of-use.html' }
    },
    {
        path: 'delete-data',
        component: DynamicHtmlLoaderComponent,
        data: { filePath: './policies/delete-data.html' }
    }
];
