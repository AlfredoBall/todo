import { HttpClient } from '@angular/common/http';
import { Component, OnInit, input } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  selector: 'app-dynamic-html-loader',
  template: `<div [innerHTML]="htmlContent | async"></div>`,
  standalone: true,
})
export class DynamicHtmlLoaderComponent implements OnInit {
  filePath = input.required<string>();
  htmlContent: Promise<SafeHtml> | undefined;

  constructor(private http: HttpClient, private sanitizer: DomSanitizer) {}

  ngOnInit() {
    this.htmlContent = this.loadHtmlContent(this.filePath());
  }

  private async loadHtmlContent(url: string): Promise<SafeHtml> {
    const htmlString = await this.http.get(url, { responseType: 'text' }).toPromise();
    // Sanitize the HTML to prevent XSS attacks
    return this.sanitizer.bypassSecurityTrustHtml(htmlString || '');
  }
}