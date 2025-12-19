import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';

// @ts-ignore
const API_BASE_URL = import.meta.env.NG_APP_API_BASE_URL || '/api';

@Injectable({
  providedIn: 'root',
})
export class DataSource {
  private http = inject(HttpClient);

  fetchClipboards() {
    return this.http.get<any[]>(`${API_BASE_URL}/api/clipboards`);
  }

  addClipboard(name: string) {
    return this.http.post<any>(`${API_BASE_URL}/api/clipboard?name=${encodeURIComponent(name)}`, {});
  }

  editClipboard(id: number, name: string) {
    return this.http.patch<any>(`${API_BASE_URL}/api/clipboard/${id}?name=${encodeURIComponent(name)}`, {});
  }

  removeClipboard(id: number) {
    return this.http.delete<any>(`${API_BASE_URL}/api/clipboard/${id}`);
  }

  fetchItems(clipboardId: number) {
    return this.http.get<any[]>(`${API_BASE_URL}/api/items/${clipboardId}`);
  }

  addItem(clipboardId: number, name: string) {
    return this.http.post<any>(`${API_BASE_URL}/api/item?clipboardId=${clipboardId}&name=${encodeURIComponent(name)}`, {});
  }

  removeItem(id: number) {
    return this.http.delete<any>(`${API_BASE_URL}/api/item/${id}`);
  }

  completeItem(id: number) {
    return this.http.post<any>(`${API_BASE_URL}/api/item/${id}/complete`, {});
  }

  unfinishItem(id: number) {
    return this.http.post<any>(`${API_BASE_URL}/api/item/${id}/unfinish`, {});
  }

  editItem(id: number, name: string) {
    return this.http.patch<any>(`${API_BASE_URL}/api/item/${id}?name=${encodeURIComponent(name)}`, {});
  }
}
