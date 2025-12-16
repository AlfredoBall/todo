import { Component, OnInit, OnDestroy, inject, signal } from '@angular/core';
import { MsalService, MsalBroadcastService } from '@azure/msal-angular';
import { EventMessage, EventType, InteractionStatus, AuthenticationResult } from '@azure/msal-browser';
import { filter, takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';
import { AUTH_CONFIG } from '../../auth-config';

@Component({
  selector: 'app-login',
  standalone: true,
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login implements OnInit, OnDestroy {
  private msalService = inject(MsalService);
  private msalBroadcastService = inject(MsalBroadcastService);
  private readonly destroy$ = new Subject<void>();

  isAuthenticated = signal<boolean>(false);
  userDisplayName = signal<string>('');

  ngOnInit(): void {
    // Listen for authentication status changes
    this.msalBroadcastService.inProgress$
      .pipe(
        filter((status: InteractionStatus) => status === InteractionStatus.None),
        takeUntil(this.destroy$)
      )
      .subscribe(() => {
        this.checkAuthenticationStatus();
      });

    // Listen for login success events
    this.msalBroadcastService.msalSubject$
      .pipe(
        filter((msg: EventMessage) => msg.eventType === EventType.LOGIN_SUCCESS),
        takeUntil(this.destroy$)
      )
      .subscribe((result: EventMessage) => {
        const payload = result.payload as AuthenticationResult;
        this.msalService.instance.setActiveAccount(payload.account);
        this.checkAuthenticationStatus();
      });

    // Initial authentication check
    this.checkAuthenticationStatus();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private checkAuthenticationStatus(): void {
    const accounts = this.msalService.instance.getAllAccounts();
    this.isAuthenticated.set(accounts.length > 0);

    if (accounts.length > 0) {
      const activeAccount = this.msalService.instance.getActiveAccount() || accounts[0];
      if (!this.msalService.instance.getActiveAccount()) {
        this.msalService.instance.setActiveAccount(activeAccount);
      }
      this.userDisplayName.set(activeAccount?.name || activeAccount?.username || 'User');
    }
  }

  login(): void {
    this.msalService.loginRedirect({
      scopes: AUTH_CONFIG.API_SCOPES
    });
  }

  logout(): void {
    this.msalService.logoutRedirect({
      postLogoutRedirectUri: AUTH_CONFIG.POST_LOGOUT_REDIRECT_URI
    });
  }
}
