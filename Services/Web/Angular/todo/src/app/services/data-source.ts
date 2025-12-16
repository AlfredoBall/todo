import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class DataSource {
  private http = inject(HttpClient);

  fetchClipboards() {
    return this.http.get<any[]>('api/clipboards');
  }

  addClipboard(name: string) {
    return this.http.post<any>(`api/clipboard?name=${encodeURIComponent(name)}`, {});
  }

  editClipboard(id: number, name: string) {
    return this.http.patch<any>(`api/clipboard/${id}?name=${encodeURIComponent(name)}`, {});
  }

  removeClipboard(id: number) {
    return this.http.delete<any>(`api/clipboard/${id}`);
  }

  fetchItems(clipboardId: number) {
    return this.http.get<any[]>(`api/items/${clipboardId}`);
  }

  addItem(clipboardId: number, name: string) {
    return this.http.post<any>(`api/item?clipboardId=${clipboardId}&name=${encodeURIComponent(name)}`, {});
  }

  removeItem(id: number) {
    return this.http.delete<any>(`api/item/${id}`);
  }

  completeItem(id: number) {
    return this.http.post<any>(`api/item/${id}/complete`, {});
  }

  unfinishItem(id: number) {
    return this.http.post<any>(`api/item/${id}/unfinish`, {});
  }

  editItem(id: number, name: string) {
    return this.http.patch<any>(`api/item/${id}?name=${encodeURIComponent(name)}`, {});
  }
}
