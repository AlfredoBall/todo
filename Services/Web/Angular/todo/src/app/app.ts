import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router, NavigationEnd } from '@angular/router';
import { Navbar } from './components/navbar/navbar';
import { MsalService, MsalBroadcastService, MsalInterceptor, MsalInterceptorConfiguration } from '@azure/msal-angular';
import { InteractionStatus, EventMessage, EventType, AuthenticationResult, InteractionType } from '@azure/msal-browser';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { AUTH_CONFIG } from './auth-config';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, Navbar],
  templateUrl: './app.html',
  styleUrl: './app.css',
  providers: [
    {
      provide: HTTP_INTERCEPTORS,
      useClass: MsalInterceptor,
      multi: true
    }
  ]
})
export class App implements OnInit, OnDestroy {
  private msalService = inject(MsalService);
  private msalBroadcastService = inject(MsalBroadcastService);
  private router = inject(Router);
  private readonly destroy$ = new Subject<void>();

  ngOnInit(): void {
    // Handle redirect after login
    this.msalService.handleRedirectObservable().subscribe();

    // Scroll to top on route change
    this.router.events
      .pipe(
        filter(event => event instanceof NavigationEnd),
        takeUntil(this.destroy$)
      )
      .subscribe(() => {
        window.scrollTo(0, 0);
      });

    // Set active account when interaction is complete
    this.msalBroadcastService.inProgress$
      .pipe(
        filter((status: InteractionStatus) => status === InteractionStatus.None),
        takeUntil(this.destroy$)
      )
      .subscribe(() => {
        this.setActiveAccount();
      });

    // Handle login success
    this.msalBroadcastService.msalSubject$
      .pipe(
        filter((msg: EventMessage) => msg.eventType === EventType.LOGIN_SUCCESS),
        takeUntil(this.destroy$)
      )
      .subscribe((result: EventMessage) => {
        const payload = result.payload as AuthenticationResult;
        this.msalService.instance.setActiveAccount(payload.account);
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private setActiveAccount(): void {
    const accounts = this.msalService.instance.getAllAccounts();
    if (accounts.length > 0 && !this.msalService.instance.getActiveAccount()) {
      this.msalService.instance.setActiveAccount(accounts[0]);
    }
  }
}