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
];
