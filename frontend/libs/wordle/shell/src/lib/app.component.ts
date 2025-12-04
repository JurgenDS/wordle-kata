import { Component, ChangeDetectionStrategy } from '@angular/core';
import { HelloComponent } from '@wordle-kata/feature-hello';

@Component({
  selector: 'app-root',
  imports: [HelloComponent],
  // Using templateUrl instead of inline template for better ESLint performance
  // Inline templates require Angular template compilation which is slow (30-60s)
  templateUrl: './app.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {}
