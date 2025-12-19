import type { IClipboardItem, ITodoItem } from "../types";
import type { IPublicClientApplication } from "@azure/msal-browser";
import { AUTH_CONFIG } from "../auth-config";

// Use '/api' for development (proxy), or VITE_API_BASE_URL for production
const API_BASE_URL = import.meta.env.MODE === 'production' 
  ? (import.meta.env.VITE_API_BASE_URL || '/api')
  : '/api';

export class ApiService {
  private msalInstance: IPublicClientApplication | null = null;

  public setMsalInstance(instance: IPublicClientApplication) {
    this.msalInstance = instance;
  }

  private async getAuthHeaders(): Promise<HeadersInit> {
    const headers: HeadersInit = {
      'Content-Type': 'application/json'
    };

    if (AUTH_CONFIG.BYPASS_AUTH_IN_DEV) {
      return headers;
    }

    if (!this.msalInstance) {
      return headers;
    }

    try {
      const accounts = this.msalInstance.getAllAccounts();
      if (accounts.length === 0) {
        return headers;
      }

      const request = {
        scopes: AUTH_CONFIG.API_SCOPES,
        account: accounts[0]
      };

      const response = await this.msalInstance.acquireTokenSilent(request);
      headers['Authorization'] = `Bearer ${response.accessToken}`;
    } catch (error) {
      console.error('Error acquiring token:', error);
    }

    return headers;
  }

  public async fetchClipboards() : Promise<IClipboardItem[]> {
    const headers = await this.getAuthHeaders();
    const response = await fetch(`${API_BASE_URL}/api/clipboards`, { headers });
    
    if (!response.ok) {
      if (response.status === 401) {
        // User not authenticated - return empty array
        return [];
      }
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  }

  public async fetchItems(clipboardId: number): Promise<ITodoItem[]> {
    const headers = await this.getAuthHeaders();
    const response = await fetch(`${API_BASE_URL}/api/items/${clipboardId}`, { headers });
    
    if (!response.ok) {
      if (response.status === 401) {
        // User not authenticated - return empty array
        return [];
      }
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  }

  public async completeItem(itemId: number): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/item/${itemId}/complete`, {
      method: 'POST',
      headers
    });
  }

  public async unfinishItem(itemId: number): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/item/${itemId}/unfinish`, {
      method: 'POST',
      headers
    });
  }

  public async deleteItem(itemId: number): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/item/${itemId}`, {
      method: 'DELETE',
      headers
    });
  }

  public async editItem(itemId: number, name: string): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/item/${itemId}?name=${encodeURIComponent(name)}`, {
      method: 'PATCH',
      headers
    });
  }

  public async addItem(clipboardId: number, name: string): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/item/?clipboardId=${clipboardId}&name=${encodeURIComponent(name)}`, {
      method: 'POST',
      headers
    });
  }
  public async editClipboard(id: number, name: string): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/clipboard/${id}?name=${encodeURIComponent(name)}`, {
      method: 'PATCH',
      headers
    });
  }

  public async deleteClipboard(id: number): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/clipboard/${id}`, {
      method: 'DELETE',
      headers
    });
  }

  public async addClipboard(name: string): Promise<Response> {
    const headers = await this.getAuthHeaders();
    return await fetch(`${API_BASE_URL}/api/clipboard?name=${encodeURIComponent(name)}`, {
      method: 'POST',
      headers
    });
  }
}

export default ApiService;