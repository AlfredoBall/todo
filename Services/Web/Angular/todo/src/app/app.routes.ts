import { Routes } from '@angular/router';
import { Home } from './pages/home/home';
import { About } from './pages/about/about';

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
        loadComponent: () => import('./pages/privacy-policy/privacy-policy').then(m => m.PrivacyPolicyComponent)
    },
    {
        path: 'terms-of-use',
        loadComponent: () => import('./pages/terms-of-use/terms-of-use').then(m => m.TermsOfUseComponent)
    },
    {
        path: 'delete-data',
        loadComponent: () => import('./pages/delete-data/delete-data').then(m => m.DeleteDataComponent)
    }
];
