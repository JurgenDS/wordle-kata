import { provideZoneChangeDetection } from '@angular/core';
import { bootstrapApplication } from '@angular/platform-browser';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { AppComponent } from '@wordle-kata/shell';

bootstrapApplication(AppComponent, {
  providers: [provideZoneChangeDetection(), provideHttpClient(withFetch())],
}).catch((err) => console.error(err));
