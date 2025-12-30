import { HttpClient } from '@angular/common/http';
import { Component, OnInit, input } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { AsyncPipe } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-dynamic-html-loader',
  template: `<div [innerHTML]="htmlContent | async"></div>`,
  standalone: true,
  imports: [AsyncPipe]
})
export class DynamicHtmlLoaderComponent implements OnInit {
  filePath!: string;
  htmlContent: Promise<SafeHtml> | undefined;

  constructor(private http: HttpClient, private sanitizer: DomSanitizer, private route: ActivatedRoute) {}

  ngOnInit() {
    this.filePath = this.route.snapshot.data['filePath'];
    this.htmlContent = this.loadHtmlContent(this.filePath);
  }

  private async loadHtmlContent(url: string): Promise<SafeHtml> {
    try {
      // 2. Replace .toPromise() with firstValueFrom()
      const htmlString = await firstValueFrom(this.http.get(url, { responseType: 'text' }));
      return this.sanitizer.bypassSecurityTrustHtml(htmlString || '');
    } catch (error) {
      console.error('Failed to load policy HTML:', error);
      return this.sanitizer.bypassSecurityTrustHtml('<p>Error loading document.</p>');
    }
  }
}