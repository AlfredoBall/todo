import { HttpClient } from '@angular/common/http';
import { Component, OnInit, input } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { AsyncPipe } from '@angular/common';
import { ActivatedRoute } from '@angular/router';

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
    const htmlString = await this.http.get(url, { responseType: 'text' }).toPromise();
    // Sanitize the HTML to prevent XSS attacks
    return this.sanitizer.bypassSecurityTrustHtml(htmlString || '');
  }
}