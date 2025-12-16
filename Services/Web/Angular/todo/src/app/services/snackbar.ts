import { Injectable, inject } from '@angular/core';
import {MatSnackBar} from '@angular/material/snack-bar';

@Injectable({
  providedIn: 'root',
})
export class Snackbar {
  private _snackBar = inject(MatSnackBar);

  openSnackBar(message: string, action: string, isError: boolean = false) {
    this._snackBar.open(message, action, {
      duration: 3000, // This should be configurable as an app setting
      panelClass: isError ? ['snackbar-error'] : ['snackbar-success'],
      verticalPosition: 'bottom',
      horizontalPosition: 'right',
    });
  }
}
