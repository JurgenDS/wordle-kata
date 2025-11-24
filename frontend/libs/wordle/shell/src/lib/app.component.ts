import { Component, ChangeDetectionStrategy } from '@angular/core';
import { HelloComponent } from '@wordle-kata/feature-hello';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [HelloComponent],
  template: '<app-hello></app-hello>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {}
