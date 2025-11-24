import { provideZoneChangeDetection } from '@angular/core';
import { bootstrapApplication } from '@angular/platform-browser';
import { provideAnimations } from '@angular/platform-browser/animations';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { AppComponent } from '@wordle-kata/shell';
import { LoggerService, LogLevel } from '@wordle-kata/util-logging';

// Initialize logger for bootstrap errors
const logger = new LoggerService();
logger.setLogLevel(LogLevel.Error);

bootstrapApplication(AppComponent, {
  providers: [provideZoneChangeDetection(), provideAnimations(), provideHttpClient(withFetch())],
}).catch((err) => {
  logger.error('Application bootstrap failed:', err);
  // Display user-friendly error message
  document.body.innerHTML = `
    <div style="display: flex; align-items: center; justify-content: center; height: 100vh; font-family: Arial, sans-serif;">
      <div style="text-align: center; padding: 2rem;">
        <h1 style="color: #d32f2f;">Application Failed to Start</h1>
        <p style="color: #666;">We're sorry, but the application encountered an error during startup.</p>
        <p style="color: #666;">Please refresh the page or contact support if the problem persists.</p>
      </div>
    </div>
  `;
});
