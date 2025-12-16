import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button'; // For navigation buttons
import { RouterModule, Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { Subscription } from 'rxjs';
import { Login } from '../login/login';

@Component({
  selector: 'app-navbar',
  imports: [MatToolbarModule, MatButtonModule, RouterModule, Login],
  templateUrl: './navbar.html',
  styleUrl: './navbar.css',
})
export class Navbar implements OnInit, OnDestroy {
  private router = inject(Router);
  currentClipboardId = signal<number | null>(null);
  currentFilter = signal<string | null>(null);
  currentPage = signal<number | null>(null);
  private routerSubscription?: Subscription;

  ngOnInit() {
    this.updateRouteInfo(this.router.url);
    
    this.routerSubscription = this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: NavigationEnd) => {
        this.updateRouteInfo(event.url);
      });
  }

  ngOnDestroy() {
    this.routerSubscription?.unsubscribe();
  }

  private updateRouteInfo(url: string) {
    const match = url.match(/\/clipboard\/(\d+)/);
    if (match) {
      this.currentClipboardId.set(Number(match[1]));
      
      const filterMatch = url.match(/[?&]filter=([^&]+)/);
      if (filterMatch) {
        this.currentFilter.set(filterMatch[1]);
      } else {
        this.currentFilter.set(null);
      }

      const pageMatch = url.match(/[?&]page=(\d+)/);
      if (pageMatch) {
        this.currentPage.set(Number(pageMatch[1]));
      } else {
        this.currentPage.set(null);
      }
    }
  }

  getHomeLink(): string {
    const clipboardId = this.currentClipboardId();
    const filter = this.currentFilter();
    
    if (!clipboardId) return '/';
    
    if (filter) {
      return `/clipboard/${clipboardId}?filter=${filter}`;
    }
    return `/clipboard/${clipboardId}`;
  }

  navigateHome(event: Event) {
    event.preventDefault();
    const clipboardId = this.currentClipboardId();
    const filter = this.currentFilter();
    const page = this.currentPage();
    
    if (!clipboardId) {
      this.router.navigate(['/']);
    } else {
      const queryParams: any = {};
      if (filter) queryParams.filter = filter;
      if (page && page > 1) queryParams.page = page;
      this.router.navigate(['/clipboard', clipboardId], { queryParams });
    }
  }
}

